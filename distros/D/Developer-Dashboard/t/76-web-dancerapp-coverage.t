#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use HTTP::Request::Common qw(GET);

use lib 'lib';
use lib 't/lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Web::DancerApp;
use Local::PSGITest;

# ---------------------------------------------------------------------------
# Hermetic runtime: the Dancer2 route layer and Config discovery both resolve
# from the process HOME and the deepest .developer-dashboard layer under the
# current working directory, so anchor both inside throwaway temp dirs.
# ---------------------------------------------------------------------------
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";
my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
isa_ok( $paths, 'Developer::Dashboard::PathRegistry', 'path registry anchors the hermetic layer stack' );

# ---------------------------------------------------------------------------
# Test-only doubles.
# ---------------------------------------------------------------------------
{
    # A request double that lets us drive request-normalization branches with
    # exact header/env/body state instead of relying on a live PSGI request.
    package Local::CovRequest;
    sub new {
        my ( $class, %args ) = @_;
        return bless {
            headers => $args{headers} || {},
            env     => $args{env}     || {},
            body    => $args{body},
        }, $class;
    }
    sub header { return $_[0]->{headers}{ $_[1] }; }
    sub env    { return $_[0]->{env}; }
    sub body   { return $_[0]->{body}; }
}

{
    # A PSGI streaming writer double that records chunks and can be steered to
    # fail with a disconnect-style error or an unrelated fatal error.
    package Local::CovWriter;
    sub new { return bless { chunks => [] }, $_[0]; }
    sub write {
        my ( $self, $chunk ) = @_;
        push @{ $self->{chunks} }, $chunk;
        die "Broken pipe\n"        if defined $chunk && $chunk eq 'disc';
        die "kaboom explosion\n"   if defined $chunk && $chunk eq 'fatal';
        return 1;
    }
    sub close  { return 1; }
    sub chunks { return $_[0]->{chunks}; }
}

{
    # An exception object whose boolean overload is false, used to drive the
    # "raised error is boolean-false" fallback in the streaming failure path.
    package Local::FalseError;
    use overload
      'bool' => sub { 0 },
      '""'   => sub { 'false-bool-error' },
      fallback => 1;
    sub new { return bless {}, $_[0]; }
}

{ package Local::CovBackend; sub new { return bless {}, $_[0]; } }

{
    # Backend that implements login_response (but not logout_response) plus a
    # handle() fallback, to drive both sides of the _run_backend can() branch.
    package Local::LoginBackend;
    sub new  { return bless {}, $_[0]; }
    sub login_response { return [ 200, 'text/plain; charset=utf-8', 'login-ok', { 'X-Login' => '1' } ]; }
    sub handle {
        my ( $self, %args ) = @_;
        return [ 201, 'text/plain; charset=utf-8', 'handled-' . $args{path}, {} ];
    }
}

{
    # authorize_request permits (returns a false value), so the guarded method runs.
    package Local::AuthAllowBackend;
    sub new  { return bless {}, $_[0]; }
    sub authorize_request { return undef; }
    sub root_response     { return [ 200, 'text/plain; charset=utf-8', 'root-allowed', {} ]; }
}

{
    # authorize_request denies (returns a truthy response), short-circuiting the method.
    package Local::AuthDenyBackend;
    sub new  { return bless {}, $_[0]; }
    sub authorize_request { return [ 401, 'text/plain; charset=utf-8', 'denied', {} ]; }
    sub root_response     { return [ 200, 'text/plain; charset=utf-8', 'should-not-run', {} ]; }
}

{
    # No authorize_request at all: the ternary guard skips authorization entirely.
    package Local::NoAuthBackend;
    sub new  { return bless {}, $_[0]; }
    sub root_response { return [ 200, 'text/plain; charset=utf-8', 'root-noauth', {} ]; }
}

# ---------------------------------------------------------------------------
# build_psgi_app / _current_backend defensive die paths.
# ---------------------------------------------------------------------------
{
    my $error = eval { Developer::Dashboard::Web::DancerApp->build_psgi_app(); 1 } ? '' : $@;
    like( $error, qr/Missing backend web app/, 'build_psgi_app dies when no backend app is supplied' );
}

{
    local $Developer::Dashboard::Web::DancerApp::BACKEND_APP = undef;
    my $error = eval { Developer::Dashboard::Web::DancerApp::_current_backend(); 1 } ? '' : $@;
    like( $error, qr/Missing backend web app/, '_current_backend dies when no backend has been configured' );
}

# ---------------------------------------------------------------------------
# Request normalization: drive every host/remote-address/env branch through a
# request double so each // default and && guard is exercised deterministically.
# ---------------------------------------------------------------------------
sub request_args_with {
    my (%spec) = @_;
    no warnings 'redefine';
    my $fake = Local::CovRequest->new(
        headers => $spec{headers},
        env     => $spec{env},
        body    => $spec{body},
    );
    local *Developer::Dashboard::Web::DancerApp::request = sub { $fake };
    return Developer::Dashboard::Web::DancerApp::_request_args();
}

# Call A: Host present, every env value and the body defined.
{
    my $args = request_args_with(
        headers => {
            Host              => 'example.com',
            Cookie            => 'a=1',
            'X-DD-API-Key'    => 'k',
            'X-DD-API-Secret' => 's',
        },
        env => {
            SERVER_NAME    => 'srv',
            SERVER_PORT    => '8080',
            REMOTE_ADDR    => '10.0.0.1',
            SERVER_ADDR    => '10.0.0.9',
            PATH_INFO      => '/p',
            QUERY_STRING   => 'q=1',
            REQUEST_METHOD => 'POST',
        },
        body => 'payload',
    );
    is( $args->{path},                 '/p',          'request args keep a present PATH_INFO' );
    is( $args->{query},                'q=1',         'request args keep a present QUERY_STRING' );
    is( $args->{method},               'POST',        'request args keep a present REQUEST_METHOD' );
    is( $args->{body},                 'payload',     'request args keep a present body' );
    is( $args->{remote_addr},          '10.0.0.1',    'request args prefer a present REMOTE_ADDR' );
    is( $args->{headers}{host},        'example.com', 'request args keep a present Host header' );
    is( $args->{headers}{cookie},      'a=1',         'request args keep a present Cookie header' );
    is( $args->{headers}{'x-dd-api-key'},    'k',     'request args keep a present api key header' );
    is( $args->{headers}{'x-dd-api-secret'}, 's',     'request args keep a present api secret header' );
}

# Call B: Host empty, SERVER_NAME and SERVER_PORT both present -> host:port.
{
    my $args = request_args_with(
        headers => { Host => '' },
        env     => { SERVER_NAME => 'namehost', SERVER_PORT => '9090', REMOTE_ADDR => '1.1.1.1' },
    );
    is( $args->{headers}{host}, 'namehost:9090', 'empty Host rebuilds host from server name and port' );
    is( $args->{remote_addr},   '1.1.1.1',       'remote address stays the present REMOTE_ADDR' );
}

# Call C: Host absent, SERVER_NAME present, SERVER_PORT absent -> no port suffix.
{
    my $args = request_args_with(
        headers => {},
        env     => { SERVER_NAME => 'namehost2', REMOTE_ADDR => '2.2.2.2' },
    );
    is( $args->{headers}{host}, 'namehost2', 'missing server port leaves the rebuilt host bare' );
    is( $args->{remote_addr},   '2.2.2.2',   'remote address is still the present REMOTE_ADDR' );
}

# Call D: Host absent, SERVER_NAME absent -> empty rebuilt host, short-circuit.
{
    my $args = request_args_with(
        headers => {},
        env     => { REMOTE_ADDR => '3.3.3.3' },
    );
    is( $args->{headers}{host}, '', 'a missing server name yields an empty rebuilt host' );
    is( $args->{remote_addr},   '3.3.3.3', 'remote address is the present REMOTE_ADDR' );
}

# Call E: REMOTE_ADDR absent, SERVER_ADDR present -> falls back to SERVER_ADDR.
{
    my $args = request_args_with(
        headers => { Host => 'h5' },
        env     => { SERVER_ADDR => '9.9.9.9' },
    );
    is( $args->{remote_addr}, '9.9.9.9', 'remote address falls back to SERVER_ADDR when REMOTE_ADDR is missing' );
}

# Call F: REMOTE_ADDR and SERVER_ADDR absent, SERVER_NAME present -> uses SERVER_NAME.
{
    my $args = request_args_with(
        headers => { Host => 'h6' },
        env     => { SERVER_NAME => 'namehost6' },
    );
    is( $args->{remote_addr}, 'namehost6', 'remote address falls back to SERVER_NAME when both addresses are missing' );
}

# Call G: nothing supplied -> every default is taken.
{
    my $args = request_args_with(
        headers => {},
        env     => {},
        body    => undef,
    );
    is( $args->{path},          '/',   'a missing PATH_INFO defaults to /' );
    is( $args->{query},         '',    'a missing QUERY_STRING defaults to empty' );
    is( $args->{method},        'GET', 'a missing REQUEST_METHOD defaults to GET' );
    is( $args->{body},          '',    'a missing body defaults to empty' );
    is( $args->{remote_addr},   '',    'a wholly missing remote address defaults to empty' );
    is( $args->{headers}{host}, '',    'a wholly missing host defaults to empty' );
}

# ---------------------------------------------------------------------------
# _capture: unwrap arrayref-style splat, plain lists, and empty captures.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    {
        local *Developer::Dashboard::Web::DancerApp::splat = sub { return ( [ 'a', 'b' ] ); };
        is( Developer::Dashboard::Web::DancerApp::_capture(1), 'b', '_capture unwraps an arrayref-wrapped splat payload' );
    }
    {
        local *Developer::Dashboard::Web::DancerApp::splat = sub { return ( 'x', 'y' ); };
        is( Developer::Dashboard::Web::DancerApp::_capture(0), 'x', '_capture reads a flat multi-value splat list' );
    }
    {
        local *Developer::Dashboard::Web::DancerApp::splat = sub { return ('single'); };
        is( Developer::Dashboard::Web::DancerApp::_capture(0), 'single', '_capture keeps a single non-arrayref splat value' );
    }
    {
        local *Developer::Dashboard::Web::DancerApp::splat = sub { return (); };
        is( Developer::Dashboard::Web::DancerApp::_capture(0), undef, '_capture returns undef when there are no captures' );
    }
}

# ---------------------------------------------------------------------------
# _looks_like_disconnect_error: undef, empty, matching and non-matching text.
# ---------------------------------------------------------------------------
is( Developer::Dashboard::Web::DancerApp::_looks_like_disconnect_error(undef),                0, 'disconnect check returns 0 for undef' );
is( Developer::Dashboard::Web::DancerApp::_looks_like_disconnect_error(''),                   0, 'disconnect check returns 0 for an empty string' );
is( Developer::Dashboard::Web::DancerApp::_looks_like_disconnect_error('client disconnected'), 1, 'disconnect check matches a known disconnect phrase' );
is( Developer::Dashboard::Web::DancerApp::_looks_like_disconnect_error('totally unrelated'),  0, 'disconnect check returns 0 for an unrelated error' );

# ---------------------------------------------------------------------------
# _response_from_result: a hash body without a code stream is not streamed.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::DancerApp::status           = sub { };
    local *Developer::Dashboard::Web::DancerApp::content_type     = sub { };
    local *Developer::Dashboard::Web::DancerApp::response_header   = sub { };
    local $Developer::Dashboard::Web::DancerApp::BACKEND_APP =
      { app => Local::CovBackend->new, default_headers => {} };
    my $body = Developer::Dashboard::Web::DancerApp::_response_from_result(
        [ 200, 'text/plain; charset=utf-8', { stream => 'not-a-coderef' }, { 'X-H' => 'v' } ]
    );
    is( ref($body), 'HASH', 'a hash body without a code stream is treated as a plain body' );
    is( $body->{stream}, 'not-a-coderef', 'the non-stream hash body is returned unchanged' );
}

# ---------------------------------------------------------------------------
# Streaming happy path plus disconnect and fatal write handling.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    my $writer_obj = Local::CovWriter->new;
    my @responder_arg;
    my @writer_returns;
    local *Developer::Dashboard::Web::DancerApp::delayed = sub (&) { return $_[0]->(); };
    local $Dancer2::Core::Route::RESPONDER = sub {
        my ($reply) = @_;
        @responder_arg = @{$reply};
        return $writer_obj;
    };
    local $Developer::Dashboard::Web::DancerApp::BACKEND_APP =
      { app => Local::CovBackend->new, default_headers => { 'X-Def' => 'd' } };

    Developer::Dashboard::Web::DancerApp::_response_from_result(
        [
            200,
            'text/plain; charset=utf-8',
            {
                stream => sub {
                    my ($w) = @_;
                    push @writer_returns, $w->('good chunk');
                    push @writer_returns, $w->('');
                    push @writer_returns, $w->(undef);
                    push @writer_returns, $w->('disc');
                    $w->('fatal');
                    push @writer_returns, 'unreached';
                },
            },
            { 'X-Stream' => 's' },
        ]
    );

    is( $responder_arg[0], 200, 'the streaming responder receives the original status code' );
    is_deeply(
        \@writer_returns,
        [ 1, 1, 1, 0 ],
        'stream writer succeeds, short-circuits empty/undef chunks, and reports a disconnect',
    );
    like(
        join( '', map { defined $_ ? $_ : '' } @{ $writer_obj->chunks } ),
        qr/kaboom explosion/,
        'a fatal non-disconnect stream error is caught and its text is written to the client',
    );
}

# Streaming when the backend carries no default headers at all.
{
    no warnings 'redefine';
    my $writer_obj = Local::CovWriter->new;
    local *Developer::Dashboard::Web::DancerApp::delayed = sub (&) { return $_[0]->(); };
    local $Dancer2::Core::Route::RESPONDER = sub { return $writer_obj; };
    local $Developer::Dashboard::Web::DancerApp::BACKEND_APP =
      { app => Local::CovBackend->new, default_headers => undef };
    Developer::Dashboard::Web::DancerApp::_response_from_result(
        [ 200, 'text/plain; charset=utf-8', { stream => sub { $_[0]->('hi') } }, { 'X-H' => 'v' } ]
    );
    is( $writer_obj->chunks->[0], 'hi', 'streaming still works when the backend has no default headers' );
}

# Streaming when the raised error stringifies but is boolean-false.
{
    no warnings 'redefine';
    my $writer_obj = Local::CovWriter->new;
    local *Developer::Dashboard::Web::DancerApp::delayed = sub (&) { return $_[0]->(); };
    local $Dancer2::Core::Route::RESPONDER = sub { return $writer_obj; };
    local $Developer::Dashboard::Web::DancerApp::BACKEND_APP =
      { app => Local::CovBackend->new, default_headers => {} };
    Developer::Dashboard::Web::DancerApp::_response_from_result(
        [ 200, 'text/plain; charset=utf-8', { stream => sub { die Local::FalseError->new } }, {} ]
    );
    like(
        join( '', map { defined $_ ? $_ : '' } @{ $writer_obj->chunks } ),
        qr/Streaming response failed/,
        'a boolean-false raised error falls back to the default streaming failure text',
    );
}

# Streaming when there is no PSGI responder available.
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::DancerApp::delayed = sub (&) { return $_[0]->(); };
    local $Dancer2::Core::Route::RESPONDER = undef;
    local $Developer::Dashboard::Web::DancerApp::BACKEND_APP =
      { app => Local::CovBackend->new, default_headers => {} };
    my $error = eval {
        Developer::Dashboard::Web::DancerApp::_response_from_result(
            [ 200, 'text/plain; charset=utf-8', { stream => sub { } }, {} ]
        );
        1;
    } ? '' : $@;
    like( $error, qr/Missing delayed response writer/, 'streaming dies when no PSGI responder is available' );
}

# ---------------------------------------------------------------------------
# _run_backend: call an implemented method, and fall back to handle().
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    my $fake = Local::CovRequest->new(
        headers => { Host => 'h' },
        env     => { PATH_INFO => '/login', QUERY_STRING => '', REQUEST_METHOD => 'POST', REMOTE_ADDR => '1.2.3.4' },
        body    => 'x',
    );
    local *Developer::Dashboard::Web::DancerApp::request         = sub { $fake };
    local *Developer::Dashboard::Web::DancerApp::status          = sub { };
    local *Developer::Dashboard::Web::DancerApp::content_type    = sub { };
    local *Developer::Dashboard::Web::DancerApp::response_header  = sub { };
    local $Developer::Dashboard::Web::DancerApp::BACKEND_APP =
      { app => Local::LoginBackend->new, default_headers => {} };

    is(
        Developer::Dashboard::Web::DancerApp::_run_backend('login_response'),
        'login-ok',
        '_run_backend calls the backend method when the backend implements it',
    );
    like(
        Developer::Dashboard::Web::DancerApp::_run_backend('logout_response'),
        qr/^handled-/,
        '_run_backend falls back to handle() when the requested method is absent',
    );
}

# ---------------------------------------------------------------------------
# _run_authorized: authorized method, denied by authorize_request, and no
# authorize_request implementation at all.
# ---------------------------------------------------------------------------
sub run_authorized_body {
    my ($backend) = @_;
    no warnings 'redefine';
    my $fake = Local::CovRequest->new(
        headers => { Host => 'h' },
        env     => { PATH_INFO => '/', QUERY_STRING => '', REQUEST_METHOD => 'GET', REMOTE_ADDR => '1.2.3.4' },
        body    => '',
    );
    local *Developer::Dashboard::Web::DancerApp::request         = sub { $fake };
    local *Developer::Dashboard::Web::DancerApp::status          = sub { };
    local *Developer::Dashboard::Web::DancerApp::content_type    = sub { };
    local *Developer::Dashboard::Web::DancerApp::response_header  = sub { };
    local $Developer::Dashboard::Web::DancerApp::BACKEND_APP =
      { app => $backend, default_headers => {} };
    return Developer::Dashboard::Web::DancerApp::_run_authorized('root_response');
}

is( run_authorized_body( Local::AuthAllowBackend->new ), 'root-allowed',
    '_run_authorized runs the method when authorize_request permits it' );
is( run_authorized_body( Local::AuthDenyBackend->new ), 'denied',
    '_run_authorized returns the auth response when authorize_request denies it' );
is( run_authorized_body( Local::NoAuthBackend->new ), 'root-noauth',
    '_run_authorized runs the method when the backend has no authorize_request' );

# ---------------------------------------------------------------------------
# One genuine PSGI round-trip through build_psgi_app to exercise the real
# Dancer request/response keywords (not the doubles above).
# ---------------------------------------------------------------------------
{
    my $backend = bless {}, 'Local::RealBackend';
    {
        no warnings 'once';
        *Local::RealBackend::handle = sub {
            my ( $self, %args ) = @_;
            return [ 200, 'text/plain; charset=utf-8', "real:$args{path}", { 'X-Real' => 'yes' } ];
        };
    }
    my $psgi_app = Developer::Dashboard::Web::DancerApp->build_psgi_app(
        app             => $backend,
        default_headers => { 'X-Default' => 'dv' },
    );
    my $res = Local::PSGITest::request( $psgi_app, GET 'http://127.0.0.1/system/status' );
    is( $res->code,               200,                  'a real PSGI route dispatches through the backend handle fallback' );
    is( $res->content,            'real:/system/status', 'a real PSGI route returns the backend body' );
    is( $res->header('X-Default'), 'dv',                'a real PSGI route merges backend default headers' );
    is( $res->header('X-Real'),    'yes',               'a real PSGI route merges per-response headers' );
}

done_testing;

__END__

=pod

=head1 NAME

t/76-web-dancerapp-coverage.t - branch and condition coverage for the Dancer2 route adapter

=head1 PURPOSE

This test drives the request-normalization, capture-unwrapping, streaming, and
backend-dispatch helpers in the dashboard's Dancer2 route adapter so that every
defensive branch and short-circuiting condition is exercised. It pins the exact
behavior of the host/remote-address defaults, the delayed streaming writer, the
disconnect detection, and the authorize-then-run dispatch guards.

=head1 WHY IT EXISTS

The route adapter is full of hard-to-reach edges: the die guards when no backend
is wired, the rebuild of an empty Host from the server name and port, the fall
back from REMOTE_ADDR to SERVER_ADDR to SERVER_NAME, the streaming writer that
must distinguish a client disconnect from a real failure, and the authorize
short-circuit. Live PSGI traffic almost always supplies a full environment, so
those edges never run under ordinary route tests. This file reaches them with
request and writer doubles plus overridden Dancer keywords, keeping the adapter
at full branch and condition coverage and preventing a silent regression in the
defensive paths.

=head1 WHEN TO USE

Use this file when changing how the route adapter normalizes requests, resolves
the remote address, builds delayed streaming responses, detects client
disconnects, or enforces per-route authorization before dispatch.

=head1 HOW TO USE

Run C<prove -lv t/76-web-dancerapp-coverage.t> while iterating on the route
adapter, and keep it green under C<prove -lr t> and the coverage gate before
release.

=head1 WHAT USES IT

Developers during TDD, the repository test suite, and the Devel::Cover gate use
this file to keep the Dancer2 route adapter at complete branch and condition
coverage.

=head1 EXAMPLES

Example 1:

  prove -lv t/76-web-dancerapp-coverage.t

Run the route-adapter branch and condition coverage checks by themselves.

Example 2:

  prove -lr t

Run it inside the full repository suite before release.

=cut
