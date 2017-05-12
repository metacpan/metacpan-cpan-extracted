package HTTP::Server::Simple::PSGI;
use strict;
use 5.005_03;
use vars qw($VERSION);
$VERSION = '0.16';

use base qw/HTTP::Server::Simple::CGI/;

# copied from HTTP::Status
my %StatusCode = (
    100 => 'Continue',
    101 => 'Switching Protocols',
    102 => 'Processing',                      # RFC 2518 (WebDAV)
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    207 => 'Multi-Status',                    # RFC 2518 (WebDAV)
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    307 => 'Temporary Redirect',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Large',
    415 => 'Unsupported Media Type',
    416 => 'Request Range Not Satisfiable',
    417 => 'Expectation Failed',
    422 => 'Unprocessable Entity',            # RFC 2518 (WebDAV)
    423 => 'Locked',                          # RFC 2518 (WebDAV)
    424 => 'Failed Dependency',               # RFC 2518 (WebDAV)
    425 => 'No code',                         # WebDAV Advanced Collections
    426 => 'Upgrade Required',                # RFC 2817
    449 => 'Retry with',                      # unofficial Microsoft
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported',
    506 => 'Variant Also Negotiates',         # RFC 2295
    507 => 'Insufficient Storage',            # RFC 2518 (WebDAV)
    509 => 'Bandwidth Limit Exceeded',        # unofficial
    510 => 'Not Extended',                    # RFC 2774
);

sub app {
    my $self = shift;
    $self->{psgi_app} = shift if @_;
    $self->{psgi_app};
}

sub handler {
    my $self = shift;

    my $env = {
        CONTENT_LENGTH  => $ENV{CONTENT_LENGTH},
        CONTENT_TYPE    => $ENV{CONTENT_TYPE},
        SCRIPT_NAME     => '',
        REQUEST_METHOD  => $ENV{REQUEST_METHOD},
        PATH_INFO       => $ENV{PATH_INFO},
        QUERY_STRING    => $ENV{QUERY_STRING},
        REQUEST_URI     => $ENV{REQUEST_URI},
        SERVER_NAME     => $ENV{SERVER_NAME},
        SERVER_PORT     => $ENV{SERVER_PORT},
        SERVER_PROTOCOL => $ENV{SERVER_PROTOCOL},
        REMOTE_ADDR     => $ENV{REMOTE_ADDR},
        HTTP_COOKIE     => $ENV{COOKIE}, # HTTP::Server::Simple bug
        'psgi.version'    => [1,1],
        'psgi.url_scheme' => 'http',
        'psgi.input'      => $self->stdin_handle,
        'psgi.errors'     => *STDERR,
        'psgi.multithread'  => 0,
        'psgi.multiprocess' => 0,
        'psgi.run_once'     => 0,
        'psgi.streaming'    => 1,
        'psgi.nonblocking'  => 0,
        'psgix.io'          => $self->stdio_handle,
    };

    while (my ($k, $v) = each %ENV) {
        $env->{$k} = $v if $k =~ /^HTTP_/;
    }

    my $res = eval { $self->{psgi_app}->($env) }
        || [ 500, [ 'Content-Type', 'text/plain' ], [ "Internal Server Error" ] ];

    if (ref $res eq 'ARRAY') {
        $self->_handle_response($res);
    } elsif (ref $res eq 'CODE') {
        $res->(sub {
            $self->_handle_response($_[0]);
        });
    } else {
        die "Bad response $res";
    }
}

sub _handle_response {
    my ($self, $res) = @_;

    my $message = $StatusCode{$res->[0]};

    my $response = "HTTP/1.0 $res->[0] $message\015\012";
    my $headers = $res->[1];
    while (my ($k, $v) = splice(@$headers, 0, 2)) {
        $response .= "$k: $v\015\012";
    }
    $response .= "\015\012";

    print STDOUT $response;

    my $body = $res->[2];
    my $cb = sub { print STDOUT $_[0] };

    if (defined $body) {
        if (ref $body eq 'ARRAY') {
            for my $line (@$body) {
                $cb->($line) if length $line;
            }
        } else {
            local $/ = \65536 unless ref $/;
            while (defined(my $line = $body->getline)) {
                $cb->($line) if length $line;
            }
            $body->close;
        }
    } else {
        return HTTP::Server::Simple::PSGI::Writer->new($cb);
    }
}

package HTTP::Server::Simple::PSGI::Writer;

sub new   { bless $_[1], $_[0] }
sub write { $_[0]->($_[1]) }
sub close { }

package HTTP::Server::Simple::PSGI;

1;

__END__

=head1 NAME

HTTP::Server::Simple::PSGI - PSGI handler for HTTP::Server::Simple

=head1 SYNOPSIS

    use HTTP::Server::Simple::PSGI;

    my $server = HTTP::Server::Simple::PSGI->new($port);
    $server->host($host);
    $server->app($app);
    $server->run;

=head1 DESCRIPTION

HTTP::Server::Simple::PSGI is a HTTP::Server::Simple based HTTP server
that can run PSGI applications. This module only depends on
L<HTTP::Server::Simple>, which itself doesn't depend on any non-core
modules so it's best to be used as an embedded web server.

=head1 AUTHOR

Tokuhiro Matsuno

Kazuhiro Osawa

Tatsuhiko Miyagawa

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::Server::Simple>, L<Plack>, L<HTTP::Server::PSGI>

=cut
