#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use HTTP::Request::Common qw(GET);

use lib 'lib';
use lib 't/lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime ();
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
    sub method { return $_[0]->{env}{REQUEST_METHOD}; }
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
    # Backends used to prove explicit fallback and missing-method behavior.
    package Local::EmptyBackend;
    sub new { return bless {}, $_[0]; }

    package Local::HandleOnlyBackend;
    sub new { return bless {}, $_[0]; }
    sub handle { return [ 202, 'text/plain; charset=utf-8', 'handled-fallback', {} ]; }
}

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

{
    package Local::CovHeaders;
    sub new { return bless { values => $_[1] || {} }, $_[0]; }
    sub header { return $_[0]->{values}{ lc $_[1] }; }
}

{
    package Local::CovResponse;
    sub new { return bless { headers => $_[1] || Local::CovHeaders->new }, $_[0]; }
    sub headers { return $_[0]->{headers}; }
    sub status { $_[0]->{status} = $_[1] if @_ > 1; return $_[0]->{status}; }
    sub content_type { $_[0]->{content_type} = $_[1] if @_ > 1; return $_[0]->{content_type}; }
    sub content { $_[0]->{content} = $_[1] if @_ > 1; return $_[0]->{content}; }
    sub push_header { $_[0]->{headers}{values}{ lc $_[1] } = $_[2]; return 1; }
}

{
    # Fake Dancer route used to exercise startup route filtering without
    # registering additional routes in the process-global Dancer application.
    package Local::FakeDancerRoute;
    sub new { return bless { method => $_[1], matches => $_[2] }, $_[0]; }
    sub method { return $_[0]->{method}; }
    sub match { return $_[0]->{matches} ? 1 : 0; }
}

{
    # Fake Dancer app and runner provide stable route snapshots for loader tests.
    package Local::FakeDancerApp;
    our $CURRENT;
    sub new { return bless { routes => $_[1] || {}, hooks => [] }, $_[0]; }
    sub name { return $_[0]->{name} || 'DeveloperDashboard'; }
    sub routes { return $_[0]->{routes}; }
    sub add_hook { push @{ $_[0]->{hooks} }, $_[1]; return $_[1]; }

    package Local::FakeDancerRunner;
    sub new { return bless { apps => $_[1] || [] }, $_[0]; }
    sub apps { return $_[0]->{apps}; }
}

{
    # Minimal inputs for _load_skill_dashboard_modules and authorization tests.
    package Local::DashboardEntries;
    sub new { return bless { entries => $_[1] || [] }, $_[0]; }
    sub nested_skill_entries { return @{ $_[0]->{entries} }; }

    package Local::AuthorizationContext;
    sub new { return bless { request => $_[1], response => $_[2], halted => 0 }, $_[0]; }
    sub request { return $_[0]->{request}; }
    sub response { return $_[0]->{response}; }
    sub halt { $_[0]->{halted} = 1; return; }

    package Local::AuthorizationBackend;
    sub new { return bless { refusal => $_[1] }, $_[0]; }
    sub authorize_request { return $_[0]->{refusal}; }
}

package main;

# _dashboard_module_fixture($name, $source)
# Creates an isolated skill lib and writes the supplied Dashboard.pm source.
# Input: fixture name and Perl source text.
# Output: skill-entry hash with absolute directory and module paths.
sub _dashboard_module_fixture {
    my ( $name, $source ) = @_;
    my $dir = File::Spec->catdir( $home, 'fixture-skills', $name );
    my $lib = File::Spec->catdir( $dir, 'lib' );
    make_path($lib);
    my $module = File::Spec->catfile( $lib, 'Dashboard.pm' );
    open my $fh, '>', $module or die "Unable to write $module: $!";
    print {$fh} $source;
    close $fh or die "Unable to close $module: $!";
    return { dir => $dir, module => $module, lib => $lib };
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

{
    my $psgi_app = Developer::Dashboard::Web::DancerApp->build_psgi_app( app => bless( {}, 'Local::RealBackend' ) );
    ok( ref($psgi_app) eq 'CODE', 'build_psgi_app defaults missing response headers to an empty hash' );
}

# ---------------------------------------------------------------------------
# Skill Dashboard startup loader: invalid registries, missing routes/modules,
# containment failures, load failures, and route ordering.
# ---------------------------------------------------------------------------
{
    is_deeply( Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules(undef), [],
        'skill Dashboard loader skips an undefined path registry' );
    is_deeply( Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules( bless( {}, 'Local::CovBackend' ) ), [],
        'skill Dashboard loader skips a registry without nested_skill_entries' );

    my $entries = Local::DashboardEntries->new([]);
    {
        no warnings 'redefine';
        local *Dancer2::runner = sub { return Local::FakeDancerRunner->new([]); };
        my $error = eval { Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules($entries); 1 } ? '' : $@;
        like( $error, qr/Unable to find the DeveloperDashboard Dancer2 application/, 'loader reports a missing shared Dancer app' );
    }

    {
        no warnings 'redefine';
        my $wrong_app = Local::FakeDancerApp->new({});
        $wrong_app->{name} = 'DifferentApp';
        local *Dancer2::runner = sub { return Local::FakeDancerRunner->new( [$wrong_app] ); };
        my $error = eval { Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules($entries); 1 } ? '' : $@;
        like( $error, qr/Unable to find the DeveloperDashboard Dancer2 application/, 'loader ignores a Dancer app with a different name' );
    }

    my $original_get  = Local::FakeDancerRoute->new( 'get', 0 );
    my $original_post = Local::FakeDancerRoute->new( 'post', 0 );
    my $original_put  = Local::FakeDancerRoute->new( 'put', 0 );
    my $original_options = Local::FakeDancerRoute->new( 'options', 0 );
    my $fake_app = Local::FakeDancerApp->new(
        {
            get     => [$original_get],
            post    => [$original_post],
            put     => [$original_put],
            options => [$original_options],
            ghost   => undef,
        }
    );
    my $runner = Local::FakeDancerRunner->new( [$fake_app] );
    {
        no warnings 'redefine';
        local *Dancer2::runner = sub { return $runner; };
        my $loaded = Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules($entries);
        is_deeply( $loaded, [], 'loader returns an empty list when no skill entries exist' );
        is_deeply( $fake_app->{hooks}, [], 'loader installs no authorization hook when no skill route was added' );
    }

    my $missing_dir = File::Spec->catdir( $home, 'fixture-skills', 'module-absent' );
    make_path($missing_dir);
    my $route_fixture = _dashboard_module_fixture(
        'routes-added',
        q{
            package Test::Coverage::DashboardRoutes;
            push @{ $Local::FakeDancerApp::CURRENT->{routes}{get} }, Local::FakeDancerRoute->new('get', 1);
            push @{ $Local::FakeDancerApp::CURRENT->{routes}{post} }, Local::FakeDancerRoute->new('post', 1);
            push @{ $Local::FakeDancerApp::CURRENT->{routes}{put} }, Local::FakeDancerRoute->new('put', 1);
            push @{ $Local::FakeDancerApp::CURRENT->{routes}{delete} }, Local::FakeDancerRoute->new('delete', 1);
            1;
        },
    );
    my $route_entries = Local::DashboardEntries->new(
        [ undef, 'bad-entry', { dir => undef }, { dir => '' }, { dir => $missing_dir }, $route_fixture ]
    );
    $Local::FakeDancerApp::CURRENT = $fake_app;
    {
        no warnings 'redefine';
        local *Dancer2::runner = sub { return $runner; };
        my $loaded = Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules($route_entries);
        is_deeply( $loaded, [ $route_fixture->{module} ], 'loader reports the one valid skill module it loaded' );
    }
    is( scalar @{ $fake_app->{hooks} }, 1, 'loader installs one authorization hook for added routes' );
    is( $fake_app->{routes}{get}[-1], $original_get, 'new GET skill routes stay ahead of the built-in fallback route' );
    is( $fake_app->{routes}{get}[0]->method, 'get', 'new GET route is inserted before the fallback' );
    is( $fake_app->{routes}{put}[0], $original_put, 'non-GET/POST route order preserves the existing route first' );
    is( $fake_app->{routes}{put}[1]->method, 'put', 'new non-fallback route is appended after existing routes' );
    is( $fake_app->{routes}{post}[-1], $original_post, 'POST fallback stays last after a skill route is added' );
    is( $fake_app->{routes}{post}[0]->method, 'post', 'new POST route is inserted before its built-in fallback' );
    is( $fake_app->{routes}{delete}[0]->method, 'delete', 'new methods absent from the original route table are added safely' );

    my $undefined_routes_app = Local::FakeDancerApp->new( { get => undef, ghost => undef } );
    my $undefined_routes_runner = Local::FakeDancerRunner->new( [$undefined_routes_app] );
    my $undefined_routes_fixture = _dashboard_module_fixture(
        'undefined-routes',
        q{package Test::Coverage::UndefinedRoutes; push @{ $Local::FakeDancerApp::CURRENT->{routes}{get} }, Local::FakeDancerRoute->new('get', 1); 1;} . "\n",
    );
    {
        no warnings 'redefine';
        local $Local::FakeDancerApp::CURRENT = $undefined_routes_app;
        local *Dancer2::runner = sub { return $undefined_routes_runner; };
        my $loaded = Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules( Local::DashboardEntries->new([$undefined_routes_fixture]) );
        is( scalar @{$loaded}, 1, 'loader snapshots and updates a route method whose prior route list is undefined' );
    }

    my $resolve_fixture = _dashboard_module_fixture( 'resolve-failure', "package Test::Coverage::ResolveFailure; 1;\n" );
    {
        no warnings 'redefine';
        my @resolved = ( $resolve_fixture->{lib}, undef );
        local *Developer::Dashboard::Web::DancerApp::abs_path = sub { return shift @resolved; };
        local *Dancer2::runner = sub { return $runner; };
        my $error = eval { Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules( Local::DashboardEntries->new([$resolve_fixture]) ); 1 } ? '' : $@;
        like( $error, qr/Unable to resolve skill Dashboard module/, 'loader reports a module path that cannot be resolved' );
    }

    {
        no warnings 'redefine';
        my @resolved = ( undef, undef );
        local *Developer::Dashboard::Web::DancerApp::abs_path = sub { return shift @resolved; };
        local *Dancer2::runner = sub { return $runner; };
        my $error = eval { Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules( Local::DashboardEntries->new([$resolve_fixture]) ); 1 } ? '' : $@;
        like( $error, qr/Unable to resolve skill Dashboard module/, 'loader reports a lib directory that cannot be resolved' );
    }

    for my $relative ( '/outside/Dashboard.pm', '..', '../outside/Dashboard.pm' ) {
        my $safe_name = $relative;
        $safe_name =~ s/[^A-Za-z0-9]+/-/g;
        my $relative_fixture = _dashboard_module_fixture( "relative-$safe_name", "package Test::Coverage::Relative; 1;\n" );
        no warnings 'redefine';
        local *File::Spec::abs2rel = sub { return $relative; };
        local *Dancer2::runner = sub { return $runner; };
        my $error = eval { Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules( Local::DashboardEntries->new([$relative_fixture]) ); 1 } ? '' : $@;
        like( $error, qr/resolves outside its skill lib directory/, "loader rejects escaped relative path '$relative'" );
    }

    my $outside = File::Spec->catfile( $home, 'external-Dashboard.pm' );
    open my $outside_fh, '>', $outside or die "Unable to write $outside: $!";
    print {$outside_fh} "package Test::Coverage::ExternalDashboard; 1;\n";
    close $outside_fh or die "Unable to close $outside: $!";
    my $escape_fixture = _dashboard_module_fixture( 'escape-module', '' );
    unlink $escape_fixture->{module} or die "Unable to remove $escape_fixture->{module}: $!";
    symlink $outside, $escape_fixture->{module} or die "Unable to link $escape_fixture->{module}: $!";
    {
        no warnings 'redefine';
        local *Dancer2::runner = sub { return $runner; };
        my $error = eval { Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules( Local::DashboardEntries->new([$escape_fixture]) ); 1 } ? '' : $@;
        like( $error, qr/resolves outside its skill lib directory/, 'loader rejects Dashboard.pm symlinks escaping the skill lib' );
    }

    my $syntax_fixture = _dashboard_module_fixture( 'syntax-error', q{package Test::Coverage::SyntaxFailure; my $broken = ; 1;} . "\n" );
    {
        no warnings 'redefine';
        local *Dancer2::runner = sub { return $runner; };
        my $error = eval { Developer::Dashboard::Web::DancerApp::_load_skill_dashboard_modules( Local::DashboardEntries->new([$syntax_fixture]) ); 1 } ? '' : $@;
        like( $error, qr/Unable to load skill Dashboard module.*syntax error/s, 'loader preserves a Dashboard.pm compile failure' );
    }
}

# ---------------------------------------------------------------------------
# Skill-route authorization validates its inputs and handles each refusal form.
# ---------------------------------------------------------------------------
{
    my $bad_routes = eval { Developer::Dashboard::Web::DancerApp::_authorize_skill_dashboard_routes( {}, bless( {}, 'Local::AuthorizationContext' ) ); 1 } ? '' : $@;
    like( $bad_routes, qr/Missing skill route list/, 'authorization rejects a non-array route list' );
    my $bad_context = eval { Developer::Dashboard::Web::DancerApp::_authorize_skill_dashboard_routes( [], undef ); 1 } ? '' : $@;
    like( $bad_context, qr/Missing Dancer2 request context/, 'authorization rejects a missing Dancer context' );
    my $context_without_request = bless {}, 'Local::CovBackend';
    my $missing_request = eval { Developer::Dashboard::Web::DancerApp::_authorize_skill_dashboard_routes( [], $context_without_request ); 1 } ? '' : $@;
    like( $missing_request, qr/Missing Dancer2 request context/, 'authorization rejects a context without request()' );

    my $request = Local::CovRequest->new( env => { REQUEST_METHOD => undef } );
    my $context = Local::AuthorizationContext->new( $request, Local::CovResponse->new );
    my $nonmatching = Local::FakeDancerRoute->new( 'get', 0 );
    is( Developer::Dashboard::Web::DancerApp::_authorize_skill_dashboard_routes( [$nonmatching], $context ), undef,
        'authorization passes requests that do not match a skill route' );

    my $matching = Local::FakeDancerRoute->new( '', 1 );
    {
        local $Developer::Dashboard::Web::DancerApp::BACKEND_APP = { app => Local::CovBackend->new, default_headers => {} };
        my $error = eval { Developer::Dashboard::Web::DancerApp::_authorize_skill_dashboard_routes( [$matching], $context ); 1 } ? '' : $@;
        like( $error, qr/does not implement authorize_request/, 'authorization refuses skill routes when backend auth is absent' );
    }

    my $get_request = Local::CovRequest->new( env => { REQUEST_METHOD => 'GET' } );
    my $matched_context = Local::AuthorizationContext->new( $get_request, Local::CovResponse->new );
    my $get_route = Local::FakeDancerRoute->new( 'get', 1 );
    {
        local *Developer::Dashboard::Web::DancerApp::request = sub { return $get_request; };
        local $Developer::Dashboard::Web::DancerApp::BACKEND_APP = { app => Local::AuthorizationBackend->new(undef), default_headers => {} };
        is( Developer::Dashboard::Web::DancerApp::_authorize_skill_dashboard_routes( [$get_route], $matched_context ), undef,
            'authorization passes a matched skill request when the backend allows it' );
    }

    for my $case (
        { body => undef, headers => { 'X-Refused' => 'yes' }, expected_body => '', expected_header => 'yes' },
        { body => 'blocked', headers => [], expected_body => 'blocked', expected_header => undef },
    ) {
        my $response = Local::CovResponse->new;
        my $denied_context = Local::AuthorizationContext->new( $get_request, $response );
        local *Developer::Dashboard::Web::DancerApp::request = sub { return $get_request; };
        local $Developer::Dashboard::Web::DancerApp::BACKEND_APP = {
            app => Local::AuthorizationBackend->new( [ 403, 'text/plain', $case->{body}, $case->{headers} ] ),
            default_headers => {},
        };
        Developer::Dashboard::Web::DancerApp::_authorize_skill_dashboard_routes( [$get_route], $denied_context );
        is( $response->status, 403, 'denied skill route copies the refusal status' );
        is( $response->content_type, 'text/plain', 'denied skill route copies the refusal content type' );
        is( $response->content, $case->{expected_body}, 'denied skill route normalizes an undefined body' );
        is( $response->headers->header('X-Refused'), $case->{expected_header}, 'denied skill route copies only hash response headers' );
        ok( $denied_context->{halted}, 'denied skill route halts the Dancer request' );
    }
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

{
    my $args = request_args_with(
        headers => {
            Origin           => 'https://same.example',
            Referer          => 'https://same.example/page',
            'Sec-Fetch-Site' => 'same-origin',
        },
        env => { PATH_INFO => '/headers' },
    );
    is( $args->{headers}{origin}, 'https://same.example', 'request args retain Origin for CSRF checks' );
    is( $args->{headers}{referer}, 'https://same.example/page', 'request args retain Referer for CSRF checks' );
    is( $args->{headers}{'sec-fetch-site'}, 'same-origin', 'request args retain browser fetch metadata' );
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

{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::DancerApp::response = sub {
        return Local::CovResponse->new( Local::CovHeaders->new( { 'content-security-policy' => 'hook-policy' } ) );
    };
    is_deeply(
        Developer::Dashboard::Web::DancerApp::_response_header_overrides(
            { 'Content-Security-Policy' => 'default-policy', 'X-Frame-Options' => 'DENY' }
        ),
        { 'Content-Security-Policy' => 'hook-policy' },
        'response header overrides include only existing headers matching defaults',
    );
    is_deeply(
        Developer::Dashboard::Web::DancerApp::_response_header_overrides({}),
        {},
        'response header override lookup does not need a request when there are no defaults',
    );
    is_deeply(
        Developer::Dashboard::Web::DancerApp::_response_header_overrides([]),
        {},
        'response header override lookup rejects non-hash defaults',
    );
}

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

{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::DancerApp::status = sub { };
    local *Developer::Dashboard::Web::DancerApp::content_type = sub { };
    local *Developer::Dashboard::Web::DancerApp::response_header = sub { };
    local $Developer::Dashboard::Web::DancerApp::BACKEND_APP = { app => Local::CovBackend->new, default_headers => {} };
    is(
        Developer::Dashboard::Web::DancerApp::_response_from_result([ 200, 'text/plain', 'plain-body', undef ]),
        'plain-body',
        '_response_from_result treats an undefined backend header map as empty',
    );
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
    local *Developer::Dashboard::Web::DancerApp::response = sub { return Local::CovResponse->new; };
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

{
    no warnings 'redefine';
    my $fake = Local::CovRequest->new( headers => {}, env => { PATH_INFO => '/missing', REQUEST_METHOD => 'GET' } );
    local *Developer::Dashboard::Web::DancerApp::request = sub { return $fake; };
    local *Developer::Dashboard::Web::DancerApp::status = sub { };
    local *Developer::Dashboard::Web::DancerApp::content_type = sub { };
    local *Developer::Dashboard::Web::DancerApp::response_header = sub { };
    local $Developer::Dashboard::Web::DancerApp::BACKEND_APP = { app => Local::EmptyBackend->new, default_headers => {} };
    like(
        Developer::Dashboard::Web::DancerApp::_run_backend('not_implemented'),
        qr/Backend app does not implement not_implemented or handle/,
        '_run_backend converts a backend with neither method nor handle into a visible 500 body',
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

{
    no warnings 'redefine';
    my $fake = Local::CovRequest->new( headers => {}, env => { PATH_INFO => '/fallback', REQUEST_METHOD => 'GET' } );
    local *Developer::Dashboard::Web::DancerApp::request = sub { return $fake; };
    local *Developer::Dashboard::Web::DancerApp::status = sub { };
    local *Developer::Dashboard::Web::DancerApp::content_type = sub { };
    local *Developer::Dashboard::Web::DancerApp::response_header = sub { };
    local $Developer::Dashboard::Web::DancerApp::BACKEND_APP = { app => Local::HandleOnlyBackend->new, default_headers => {} };
    is( Developer::Dashboard::Web::DancerApp::_run_authorized('root_response'), 'handled-fallback',
        '_run_authorized falls back to handle() when the named method is absent' );
}

{
    no warnings 'redefine';
    my $fake = Local::CovRequest->new( headers => {}, env => { PATH_INFO => '/missing', REQUEST_METHOD => 'GET' } );
    local *Developer::Dashboard::Web::DancerApp::request = sub { return $fake; };
    local *Developer::Dashboard::Web::DancerApp::status = sub { };
    local *Developer::Dashboard::Web::DancerApp::content_type = sub { };
    local *Developer::Dashboard::Web::DancerApp::response_header = sub { };
    local $Developer::Dashboard::Web::DancerApp::BACKEND_APP = { app => Local::EmptyBackend->new, default_headers => {} };
    like(
        Developer::Dashboard::Web::DancerApp::_run_authorized('root_response'),
        qr/Backend app does not implement root_response or handle/,
        '_run_authorized makes a missing backend method visible as a 500 body',
    );
}

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
            if ( defined $self->{runtime_code} ) {
                my $page = Developer::Dashboard::PageDocument->new(
                    meta => { codes => [ { body => $self->{runtime_code} } ] },
                );
                my $result = Developer::Dashboard::PageRuntime->new( paths => $self->{paths} )
                  ->run_code_blocks( page => $page, source => 'skill' );
                my $body = join '', @{ $result->{outputs} || [] }, @{ $result->{errors} || [] };
                return [ 200, 'text/plain; charset=utf-8', $body, $self->{runtime_response_headers} || {} ];
            }
            return [ 200, 'text/plain; charset=utf-8', "real:$args{path}", { 'X-Real' => 'yes' } ];
        };
        *Local::RealBackend::authorize_request = sub {
            my ($self) = @_;
            return $self->{deny} ? [ 403, 'text/plain; charset=utf-8', 'skill-denied', {} ] : undef;
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

{
    my $skill_lib = File::Spec->catdir( $paths->skills_root, 'dashboard-route-skill', 'lib' );
    make_path($skill_lib);
    my $dashboard_module = File::Spec->catfile( $skill_lib, 'Dashboard.pm' );
    my $load_log = File::Spec->catfile( $home, 'skill-dashboard-load.log' );
    local $ENV{SKILL_DASHBOARD_LOAD_LOG} = $load_log;
    open my $module_fh, '>', $dashboard_module or die "Unable to write $dashboard_module: $!";
    print {$module_fh} <<'PERL';
package Local::DashboardRouteSkill;
use Dancer2 appname => 'DeveloperDashboard';
open my $load_log, '>>', $ENV{SKILL_DASHBOARD_LOAD_LOG} or die "cannot open skill load log: $!";
print {$load_log} "loaded\n";
close $load_log or die "cannot close skill load log: $!";
hook before => sub {
    var foo => 'bar';
    response_header 'Content-Security-Policy' => "script-src 'self' 'unsafe-inline' 'unsafe-eval'";
};
set skill_setting => 'loaded';
get '/skill-dashboard-hook' => sub { return 'skill-dashboard-loaded'; };
1;
PERL
    close $module_fh or die "Unable to close $dashboard_module: $!";

    my $second_skill_lib = File::Spec->catdir( $paths->skills_root, 'second-dashboard-route-skill', 'lib' );
    make_path($second_skill_lib);
    my $second_dashboard_module = File::Spec->catfile( $second_skill_lib, 'Dashboard.pm' );
    open my $second_module_fh, '>', $second_dashboard_module or die "Unable to write $second_dashboard_module: $!";
    print {$second_module_fh} <<'PERL';
package Local::SecondDashboardRouteSkill;
use Dancer2 appname => 'DeveloperDashboard';
get '/second-skill-dashboard-hook' => sub { return 'second-skill-dashboard-loaded'; };
1;
PERL
    close $second_module_fh or die "Unable to close $second_dashboard_module: $!";

    my $psgi_app = Developer::Dashboard::Web::DancerApp->build_psgi_app(
        app   => bless( { deny => 1 }, 'Local::RealBackend' ),
        paths => $paths,
    );
    ok( -f $load_log, 'skill Dashboard.pm top-level code runs while the PSGI app starts' );
    my $res = Local::PSGITest::request( $psgi_app, GET 'http://127.0.0.1/skill-dashboard-hook' );
    is( $res->code, 403, 'skill Dashboard.pm routes pass through the dashboard authorization gate' );
    $Developer::Dashboard::Web::DancerApp::BACKEND_APP->{app}{deny} = 0;
    $res = Local::PSGITest::request( $psgi_app, GET 'http://127.0.0.1/skill-dashboard-hook' );
    is( $res->code,    200,                       'Dancer2 loads each installed skill Dashboard.pm route at app startup' );
    is( $res->content, 'skill-dashboard-loaded', 'a skill Dashboard.pm route joins the dashboard Dancer2 app' );
    my $second_res = Local::PSGITest::request( $psgi_app, GET 'http://127.0.0.1/second-skill-dashboard-hook' );
    is( $second_res->content, 'second-skill-dashboard-loaded', 'Dancer2 loads Dashboard.pm from every installed skill' );
    my ($dancer_app) = grep { $_->name eq 'DeveloperDashboard' } @{ Dancer2->runner->apps };
    is( $dancer_app->config->{skill_setting}, 'loaded', 'a skill Dashboard.pm can modify the shared Dancer2 app settings' );

    $Developer::Dashboard::Web::DancerApp::BACKEND_APP->{default_headers}{'Content-Security-Policy'} =
      "script-src 'self' 'unsafe-inline'";
    $Developer::Dashboard::Web::DancerApp::BACKEND_APP->{app} = bless(
        {
            paths        => $paths,
            runtime_code => 'use Dancer2 appname => "DeveloperDashboard"; print var("foo");',
        },
        'Local::RealBackend'
    );
    for my $path ( '/app/dashboard-route-skill/test', '/ajax/dashboard-route-skill/test2' ) {
        my $runtime_res = Local::PSGITest::request( $psgi_app, GET "http://127.0.0.1$path" );
        is( $runtime_res->code, 200, "$path CODE request succeeds under the skill before hook" );
        is( $runtime_res->content, 'bar', "$path CODE reads the value set by Dancer2 var() in the skill before hook" );
        like( $runtime_res->header('Content-Security-Policy') || '', qr/unsafe-eval/, "$path response retains the skill before-hook CSP override" );
    }
    $Developer::Dashboard::Web::DancerApp::BACKEND_APP->{app}{runtime_response_headers} = {
        'Content-Security-Policy' => 'script-src backend-only',
    };
    my $explicit_header_res = Local::PSGITest::request(
        $psgi_app,
        GET 'http://127.0.0.1/app/dashboard-route-skill/explicit-header'
    );
    is(
        $explicit_header_res->header('Content-Security-Policy'),
        'script-src backend-only',
        'an explicit backend response header takes precedence over hook and default headers',
    );
    my $load_count = 0;
    if ( open my $loaded_fh, '<', $load_log ) {
        $load_count++ while <$loaded_fh>;
        close $loaded_fh or die "Unable to close $load_log: $!";
    }
    is( $load_count, 1, 'skill Dashboard.pm top-level code loads once across app and Ajax requests' );
}

like(
    Developer::Dashboard::PageRuntime->new( paths => $paths )->_code_header({}),
    qr/^use Developer::Dashboard::DataHelper qw\(j je\);$/m,
    'every page CODE sandpit imports DataHelper without requiring repeated user imports'
);
my $code_block = Developer::Dashboard::PageRuntime->new( paths => $paths )->_run_single_block(
    code => 'print j({ ready => 1 });',
);
like( $code_block->{stdout}, qr/"ready"\s*:\s*1/, 'a page CODE block can call j without adding a DataHelper import' );

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
The skill-extension fixture reproduces startup and request behavior in one
PSGI process: a load marker proves module initialization happens before the
first request and only once, while `/app/...` and `/ajax/...` requests prove a
Dancer2 before-hook variable reaches CODE and a hook-set CSP survives the
adapter's default-header pass.

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

  d2 docker compose --project-name problem19 -f .developer-dashboard/config/docker/d2/compose.yml -f .developer-dashboard/config/docker/d2/development.compose.yml exec dev prove -lv t/76-web-dancerapp-coverage.t

Run the skill-hook reproduction and route-adapter regression inside the
isolated Docker development container.

Example 3:

  prove -lr t

Run it inside the full repository suite before release.

=cut
