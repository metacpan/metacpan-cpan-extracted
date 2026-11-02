package Linux::Event::HTTP::Client;
use v5.36;
use parent 'Unblock::HTTP::Client';
use Linux::Event::HTTP::_Config;
use Linux::Event::HTTP::_Stream;
use Linux::Event::Kernel::Timer;
use Carp qw(croak);
use Scalar::Util qw(weaken refaddr);

our $VERSION = '0.005';

sub new ($class, %option) {
    my $loop = delete $option{loop};
    Linux::Event::HTTP::_Config::loop($loop);
    my $stream_class = Linux::Event::HTTP::_Config::stream_class(\%option);
    my %protocols = Linux::Event::HTTP::_Config::protocols(\%option);
    my $tls = delete($option{tls}) // {};
    croak 'new(): tls must be a hash reference' unless ref($tls) eq 'HASH';
    croak 'new(): HTTP Client owns TLS server_name and alpn'
        if exists($tls->{server_name}) || exists($tls->{alpn});
    $tls = { %$tls };
    my $quic = delete($option{quic}) // {};
    croak 'new(): quic must be a hash reference' unless ref($quic) eq 'HASH';
    croak 'new(): quic requires http3 => 1' if %$quic && !$protocols{http3};
    for my $key (keys %$quic) {
        croak "new(): unknown quic option $key"
            unless $key =~ /\A(?:ca_file|transport|version)\z/;
    }
    $quic = { %$quic };
    $quic->{ca_file} = $tls->{ca_file}
        if !exists($quic->{ca_file}) && exists($tls->{ca_file});
    my %quic_connections;
    for my $name (qw(connect_stream connect_quic defer schedule_timer release_connection)) {
        die "new(): $name is owned by Linux::Event::HTTP\n" if exists $option{$name};
    }
    my $self = $class->SUPER::new(%option, %protocols,
        defer => sub ($callback) { $loop->defer($callback); return },
        schedule_timer => sub ($seconds, $callback) {
            my $timer = Linux::Event::Kernel::Timer->new(
                loop => $loop, after => $seconds,
                on_timer => sub ($timer) { $callback->() },
            );
            return sub { $timer->cancel };
        },
        connect_stream => sub ($origin, $alpn, $ready) {
            my %transport;
            my $verified = 0;
            if ($origin->{scheme} eq 'https') {
                require Linux::Event::TLS;
                $transport{transport} = Linux::Event::TLS->client(
                    %$tls, server_name => $origin->{host}, alpn => $alpn,
                );
                $verified = exists($tls->{verify}) ? $tls->{verify} : 1;
            }
            my $stream = $stream_class->connect(
                loop => $loop, host => $origin->{host}, port => $origin->{port},
                %transport, data => { ready => $ready, verified_origin => $verified },
            );
            return sub { $stream->close };
        },
        ($protocols{http3} ? (
            connect_quic => sub ($origin, $ready) {
                require Net::QUIC::Driver;
                require Linux::Event::HTTP::_QUICSocket;
                my $record = { cancelled => 0, completed => 0 };
                my $weak = $record;
                weaken($weak);
                my $fail = sub ($error) {
                    my $state = $weak or return;
                    return if $state->{cancelled} || $state->{completed}++;
                    $state->{socket}->close if $state->{socket};
                    $ready->(error => "$error");
                };
                my $socket = Linux::Event::HTTP::_QUICSocket->connect(
                    loop => $loop,
                    host => ($origin->{alternative_host} // $origin->{host}),
                    port => ($origin->{alternative_port} // $origin->{port}),
                    on_ready => sub ($bridge) {
                        my $state = $weak or return;
                        return if $state->{cancelled};
                        my $ok = eval {
                            my $driver = Net::QUIC::Driver->client(
                                local => $bridge->local, peer => $bridge->peer,
                                server_name => $origin->{host}, alpn => 'h3',
                                %$quic,
                                send => $bridge->send_callback,
                                set_timeout => $bridge->set_timeout_callback,
                            );
                            my $connection = $driver->connection;
                            $state->{driver} = $driver;
                            $state->{connection} = $connection;
                            $bridge->start($driver);
                            1;
                        };
                        $fail->("$@") unless $ok;
                    },
                    on_progress => sub {
                        my $state = $weak or return;
                        return if $state->{cancelled} || $state->{completed};
                        my $connection = $state->{connection} or return;
                        if ($connection->ready && !$connection->closed) {
                            $state->{completed} = 1;
                            $quic_connections{refaddr($connection)} = $state;
                            $ready->(connection => $connection, verified_origin => 1);
                        } elsif ($connection->closed) {
                            $fail->('QUIC connection closed before authentication');
                        }
                    },
                    on_error => sub ($udp, $error) { $fail->("$error") },
                );
                $record->{socket} = $socket;
                return sub {
                    return if $record->{cancelled}++;
                    delete $quic_connections{refaddr($record->{connection})}
                        if $record->{connection};
                    $record->{connection}->close
                        if $record->{connection} && !$record->{connection}->closed;
                    $record->{socket}->close if $record->{socket};
                };
            },
        ) : ()),
        release_connection => sub ($host, $engine, $protocol, $reason) {
            if ($protocol eq 'h3') {
                my $record = delete $quic_connections{refaddr($host)};
                $host->close unless $host->closed;
                $record->{socket}->close if $record && $record->{socket};
            } else {
                $host->close;
            }
        },
    );
    $self->{linux_event_loop} = $loop;
    return $self;
}

sub _release_transport ($stream, $engine, $protocol, $reason) {
    $stream->close;
    return;
}

sub loop ($self) { $self->{linux_event_loop} }
sub get ($self, $url, %option) { $self->request(%option, method => 'GET', url => $url) }
sub head ($self, $url, %option) { $self->request(%option, method => 'HEAD', url => $url) }
sub post ($self, $url, %option) { $self->request(%option, method => 'POST', url => $url) }
sub put ($self, $url, %option) { $self->request(%option, method => 'PUT', url => $url) }
sub delete ($self, $url, %option) { $self->request(%option, method => 'DELETE', url => $url) }

1;

__END__

=head1 NAME

Linux::Event::HTTP::Client - Make HTTP requests with Linux::Event

=head1 SYNOPSIS

    use v5.36;
    use Linux::Event::Loop;
    use Linux::Event::HTTP::Client;

    my $loop = Linux::Event::Loop->new;
    my $client = Linux::Event::HTTP::Client->new(loop => $loop);

    $client->get(
        'https://example.com/',
        timeout => 15,

        on_response => sub ($tx, $res) {
            say "HTTP ", $res->status;
            say $res->body;
        },

        on_error => sub ($object, $error, @details) {
            warn "Request failed: $error\n";
        },

        on_finish => sub { $loop->stop },
    );

    $loop->run;

=head1 DESCRIPTION

C<Linux::Event::HTTP::Client> makes HTTP requests without blocking the
event loop. Create one Client and reuse it for many requests. The Client
manages connections, HTTPS, and HTTP messages for you.

HTTP/1.1 works by default. HTTP/2 and HTTP/3 are optional.

=head1 MAKING REQUESTS

Call C<get>, C<post>, C<put>, C<head>, or C<delete> with a URL
followed by options. Each call returns immediately; the request is
handled while the loop runs.

To send a POST with a body and headers:

    $client->post(
        'https://example.com/messages',
        headers => [['content-type', 'text/plain']],
        body => "Hello\n",
        on_response => sub ($tx, $res) {
            say $res->status;
            say $res->body;
        },
    );

Headers are an array reference of name/value pairs. For other HTTP
methods, use C<request>:

    $client->request(
        method => 'PATCH',
        url    => 'https://example.com/item/1',
        body   => 'updated',
        on_response => sub ($tx, $res) {
            say $res->status;
        },
    );

=head1 RESPONSES AND CALLBACKS

C<on_response> receives a transaction C<$tx> and a response C<$res>.
The response is a L<Uniform::HTTP::Response> object. Common methods are:

    $res->status;                  # HTTP status code
    $res->body;                    # Response body
    $res->header('content-type');  # A header value

HTTP 404 and 500 are valid responses, not connection errors. Check
C<$res-E<gt>status> to decide how to handle them.

Response bodies are not automatically decompressed. If you want to
request plain content, pass C<headers =E<gt> [['accept-encoding',
'identity']]> in the request. Servers can still send compressed
content, so check the C<Content-Encoding> response header and
decode the body yourself when necessary.

B<By default, C<on_response> runs after the entire response body
has arrived.> C<$res-E<gt>body> is ready to read at that point.

=over 4

=item * C<on_response($tx, $res)> - receives the response.

=item * C<on_error($object, $error, @details)> - reports failures,
such as connection errors or timeouts.

=item * C<on_finish> - runs once when the operation ends, including
after success, failure, or cancellation.

=back

For a single-request program, stop the loop in C<on_finish>, not in
C<on_response>. That way the program also stops if the request fails.
An HTTP request's C<timeout> is in seconds and includes connection
waiting time.

=head1 STREAMING A RESPONSE

For a large body, add C<on_data> to process chunks as they arrive:

    $client->get(
        'https://example.com/large-file',
        on_response => sub ($tx, $res) {
            say "HTTP ", $res->status;
        },
        on_data => sub ($tx, $bytes) {
            print $bytes;
        },
        on_end => sub ($tx) {
            say "\nBody complete";
        },
        on_error => sub ($object, $error, @details) {
            warn "Request failed: $error\n";
        },
        on_finish => sub { $loop->stop },
    );

B<Adding C<on_data> changes the timing:>

=over 4

=item * Without C<on_data>, C<on_response> runs after the full body.

=item * With C<on_data>, C<on_response> runs as soon as headers arrive.

=item * C<on_data> receives body chunks; C<on_end> signals successful
body completion.

=back

Without streaming, responses are buffered up to 1 MiB by default.
If the body exceeds that limit, the request fails and C<on_error>
runs; C<on_response> does not receive a partial buffered body.

You often cannot know the body size in advance. If a response might
be larger than the limit, or its size is unknown, use C<on_data>
from the start. This works for small responses too. The Client does
not switch from buffered mode to streaming automatically. A
C<Content-Length> header is not always available, and may not
predict the amount of body data delivered.

=head1 STREAMING AN UPLOAD

Set C<stream_body =E<gt> 1> and send pieces through the transaction
provided to C<on_transaction>:

    $client->post(
        'https://example.com/upload',
        stream_body => 1,
        on_transaction => sub ($tx) {
            $tx->write("First part\n");
            $tx->end("Last part\n");
        },
        on_response => sub ($tx, $res) {
            say $res->status;
        },
    );

C<on_transaction> may run before the request call returns. Use its
C<$tx> argument, not a variable holding the returned operation.
For large producers, respect backpressure and resume sending through
C<on_drain>. A false return from C<write> means the bytes were accepted;
do not send them twice.

=head1 CANCELLING AND SHUTTING DOWN

Each request returns an operation handle:

    my $op = $client->get('https://example.com/',
        on_response => sub ($tx, $res) { say $res->status },
    );

    $op->cancel;        # Cancel when no longer needed
    $op->state;         # Current state
    $op->error;         # Error, if any
    $op->is_terminal;   # Whether it has ended
    $op->transaction;   # Available once the request starts

Call C<$client-E<gt>shutdown> to cancel queued work, let active
requests finish, and retire pooled connections. C<pool_stats> and
C<pending_count> report connection and queue information.

=head1 HTTPS AND HTTP VERSIONS

HTTPS checks certificates and hostnames by default. To trust a
private certificate authority:

    my $client = Linux::Event::HTTP::Client->new(
        loop => $loop,
        tls => { ca_file => 'ca.pem' },
    );

HTTP/1.1 is enabled by default. To enable HTTP/2, install
L<Unblock::HTTP2> 0.13 or later and pass C<http2 =E<gt> 1> to
C<new>. For HTTP/3, install L<Unblock::HTTP3> 0.14 or later and
L<Net::QUIC> 0.06 or later, then pass C<http3 =E<gt> 1>.
HTTP/3 uses HTTPS and supports a private CA through
C<quic =E<gt> { ca_file =E<gt> 'ca.pem' }>.

To require a specific HTTP version on a request, set
C<http_version =E<gt> '1.1'>, C<'2'>, or C<'3'>. If the
required version is unavailable, the request fails instead of
falling back.

=head1 MORE OPTIONS

C<new> requires C<loop =E<gt> $loop>. Other options include
C<max_connections_per_origin> (default 4),
C<max_pending_requests> (default 128), and C<idle_timeout>
(in seconds, disabled by default).

The Client does not automatically follow redirects or manage
cookies or authentication retries.

Optional WebSocket support uses C<connect_websocket> with a
protocol option such as C<http1 =E<gt> { websocket =E<gt> 1 }>.
See L<Unblock::HTTP::Client> for the full WebSocket API.
For custom Upgrade and CONNECT handoff, see C<docs/CONNECT.md>
in the distribution.

=head1 SEE ALSO

L<Linux::Event::HTTP::Server>, L<Linux::Event::Loop>,
L<Unblock::HTTP::Client>, L<Uniform::HTTP::Response>.

The distribution's C<docs/GETTING-STARTED.md> contains more
complete examples.

=cut
