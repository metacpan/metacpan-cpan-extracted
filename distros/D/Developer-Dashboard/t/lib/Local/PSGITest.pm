package Local::PSGITest;

use strict;
use warnings;

use HTTP::Headers;
use HTTP::Response;
use IO::Handle;
use URI;

sub test_psgi {
    my ( $app, $callback ) = @_;
    die "Missing PSGI application" if ref($app) ne 'CODE';
    die "Missing PSGI callback"    if ref($callback) ne 'CODE';

    return $callback->(
        sub {
            my ($request) = @_;
            return request( $app, $request );
        }
    );
}

sub request {
    my ( $app, $request ) = @_;
    die "Missing PSGI application" if ref($app) ne 'CODE';
    die "Missing HTTP::Request object"
      if !defined $request || !$request->isa('HTTP::Request');

    my $env      = _env_from_request($request);
    my $response = $app->($env);
    my $resolved = _resolve_response($response);
    return _http_response_from_psgi( $resolved, $request );
}

sub _env_from_request {
    my ($request) = @_;
    my $uri = URI->new( $request->uri );
    my $headers = $request->headers;
    my $content = defined $request->content ? $request->content : q{};

    open my $input, '<', \$content or die "Unable to open PSGI input stream: $!";
    my $host = $uri->host;
    my $port = $uri->port;
    my $scheme = $uri->scheme || 'http';

    my %env = (
        REQUEST_METHOD  => $request->method,
        SCRIPT_NAME     => q{},
        PATH_INFO       => $uri->path || '/',
        QUERY_STRING    => defined $uri->query ? $uri->query : q{},
        SERVER_NAME     => defined $host ? $host : '127.0.0.1',
        SERVER_PORT     => defined $port ? $port : ( $scheme eq 'https' ? 443 : 80 ),
        SERVER_PROTOCOL => 'HTTP/1.1',
        REMOTE_ADDR     => defined $host ? $host : '127.0.0.1',
        'psgi.version'      => [ 1, 1 ],
        'psgi.url_scheme'   => $scheme,
        'psgi.input'        => $input,
        'psgi.errors'       => IO::Handle->new_from_fd( fileno(STDERR), 'w' ),
        'psgi.multithread'  => 0,
        'psgi.multiprocess' => 0,
        'psgi.run_once'     => 0,
        'psgi.streaming'    => 1,
        'psgi.nonblocking'  => 0,
    );

    my $content_type = $headers->header('Content-Type');
    my $content_length = length $content;
    $env{CONTENT_TYPE}   = $content_type if defined $content_type;
    $env{CONTENT_LENGTH} = $content_length if $content_length;

    for my $field ( $headers->header_field_names ) {
        next if !defined $field;
        next if lc($field) eq 'content-type';
        next if lc($field) eq 'content-length';
        my $value = $headers->header($field);
        next if !defined $value;
        my $name = uc $field;
        $name =~ s/-/_/g;
        $env{"HTTP_$name"} = $value;
    }

    return \%env;
}

sub _resolve_response {
    my ($response) = @_;
    return $response if ref($response) eq 'ARRAY';

    if ( ref($response) eq 'CODE' ) {
        my $captured;
        $response->(
            sub {
                my ($reply) = @_;
                if ( ref($reply) eq 'ARRAY' && @{$reply} == 2 ) {
                    my $writer = Local::PSGITest::Writer->new( $reply->[0], $reply->[1] );
                    $captured = $writer;
                    return $writer;
                }
                $captured = $reply;
                return;
            }
        );

        if ( ref($captured) && $captured->isa('Local::PSGITest::Writer') ) {
            return [ $captured->status, $captured->headers, [ $captured->content ] ];
        }

        return $captured;
    }

    die "Unsupported PSGI response type";
}

sub _http_response_from_psgi {
    my ( $response, $request ) = @_;
    die "Missing resolved PSGI response" if ref($response) ne 'ARRAY';

    my ( $status, $headers, $body ) = @{$response};
    my $http_headers = HTTP::Headers->new( @{$headers || []} );
    my $content = _body_to_string($body);
    return HTTP::Response->new( $status, undef, $http_headers, $content );
}

sub _body_to_string {
    my ($body) = @_;
    return q{} if !defined $body;

    if ( ref($body) eq 'ARRAY' ) {
        return join q{}, map { defined $_ ? $_ : q{} } @{$body};
    }

    if ( ref($body) eq 'HASH' && ref( $body->{stream} ) eq 'CODE' ) {
        my $content = q{};
        $body->{stream}->(
            sub {
                my ($chunk) = @_;
                $content .= $chunk if defined $chunk;
            }
        );
        return $content;
    }

    if ( ref($body) && eval { $body->can('getline') } ) {
        my $content = q{};
        while ( defined( my $chunk = $body->getline ) ) {
            $content .= $chunk;
        }
        return $content;
    }

    return $body if !ref $body;

    die "Unsupported PSGI body type";
}

package Local::PSGITest::Writer;

use strict;
use warnings;

sub new {
    my ( $class, $status, $headers ) = @_;
    return bless {
        status  => $status,
        headers => $headers || [],
        content => q{},
    }, $class;
}

sub write {
    my ( $self, $chunk ) = @_;
    $self->{content} .= $chunk if defined $chunk;
    return;
}

sub close {
    return 1;
}

sub status {
    my ($self) = @_;
    return $self->{status};
}

sub headers {
    my ($self) = @_;
    return $self->{headers};
}

sub content {
    my ($self) = @_;
    return $self->{content};
}

1;

__END__

=pod

=head1 NAME

Local::PSGITest - minimal PSGI test harness for repository tests

=head1 DESCRIPTION

This test-only helper provides a tiny PSGI request runner for repository tests
that need to exercise PSGI apps without depending on C<Plack::Test>. It
exists so release metadata does not force end-user installers to pull the
C<Test::SharedFork> dependency chain on platforms such as Windows.

=head1 WHAT IT IS

This is a repository-owned test helper module under C<t/lib/>. It is not part
of the public runtime API and exists only to support the shipped test suite.

=head1 WHAT IT IS FOR

It provides a stable, local PSGI harness so the repository can test PSGI
routes, delayed responses, and streaming bodies without adding install-time
test dependency chains to the public distribution metadata.

=head1 PURPOSE

Keep the repository PSGI tests self-contained while preventing end-user
installers from pulling C<Plack::Test>, C<Test::TCP>, and
C<Test::SharedFork> through packaged prerequisite metadata.

=head1 FUNCTIONS

=head2 test_psgi($app, $callback)

What it does:
Runs a callback with a request helper that invokes the PSGI application.

Input arguments:
=over 4
=item * C<$app> - PSGI application coderef
=item * C<$callback> - coderef receiving a request callback
=back

Expected output:
Returns whatever C<$callback> returns.

=head2 request($app, $request)

What it does:
Converts an C<HTTP::Request> object into a PSGI environment, runs the PSGI
application, resolves delayed or streaming responses, and returns an
C<HTTP::Response>.

Input arguments:
=over 4
=item * C<$app> - PSGI application coderef
=item * C<$request> - C<HTTP::Request> instance
=back

Expected output:
An C<HTTP::Response> object containing the PSGI status, headers, and body.

=head1 WHY IT EXISTS

The repository tests need PSGI request coverage, but the public distribution
should not force install-time test dependencies such as C<Plack::Test> on end
users. This helper keeps the tests self-contained.

=head1 WHEN TO USE

Use this helper when a repository test needs to send C<HTTP::Request> objects
through a PSGI coderef and inspect the resulting C<HTTP::Response>.

=head1 HOW TO USE

Load the module from C<t/lib>, build or obtain a PSGI coderef, and either call
C<test_psgi> with a callback or call C<request> directly with an
C<HTTP::Request> instance.

=head1 WHAT USES IT

The PSGI-facing repository tests such as the web update coverage and SSL route
tests use this helper to exercise the wrapped applications without
C<Plack::Test>.

=head1 EXAMPLES

  use Local::PSGITest qw();
  Local::PSGITest::test_psgi $app, sub {
      my ($cb) = @_;
      my $response = $cb->( GET 'http://127.0.0.1/' );
      is( $response->code, 200, 'request succeeds' );
  };

=cut
