package Linux::Event::HTTP::Client;
use v5.36;
use parent 'Unblock::HTTP::Client';
use Linux::Event::HTTP::_Config;
use Linux::Event::HTTP::_Stream;
use Linux::Event::Kernel::Timer;
use Carp qw(croak);
use Scalar::Util qw(weaken refaddr);

our $VERSION = '0.004';

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

Linux::Event::HTTP::Client - Unblock HTTP client using Linux::Event transports

=head1 SYNOPSIS

    my $client = Linux::Event::HTTP::Client->new(loop => $loop);
    my $op = $client->get('http://localhost:8080/',
        timeout => 15,
        on_response => sub ($tx, $response) { say $response->body },
    );

=head1 DESCRIPTION

This thin Unblock::HTTP::Client subclass supplies sockets, deferred work and
cancellable Linux::Event timers. Unblock owns pooling, scheduling, operations
and transactions. C<request>, C<pool_stats>, C<pending_count>, C<network_changed>
and C<shutdown> have the Unblock semantics.

C<on_response> receives a complete bounded response by default. Supplying
C<on_data> selects streaming: C<on_response> runs at headers, C<on_data>
provides chunks, and C<on_end> signals body completion. C<on_finish> runs
at terminal cleanup. C<timeout> is in seconds and includes time in the queue.
The returned operation supports cancellation before and after dispatch.

For a streamed upload, set C<stream_body =E<gt> 1> and supply
C<on_transaction =E<gt> sub ($tx) { $tx-E<gt>write(...); $tx-E<gt>end }>. This
callback runs when queued work is admitted to the real engine. It may run
synchronously for an available connection; use the supplied Transaction.

Generic H1 C<request(on_handoff =E<gt> sub ($tx, $response, $host)
{ ... })> with explicit C<http_version =E<gt> '1.1'> transfers a
successful 101 Upgrade or CONNECT socket to the consumer returned
by the callback. The consumer implements input, EOF, error and output
resume. The original socket, TLS and ordered write queue are preserved.
The upgraded socket is removed from the HTTP pool, so normal HTTP
requests can continue on newly pooled connections. C<on_finish> refers
to the HTTP handshake, not the successor's eventual close.

This reconstruction slice supports HTTP/1 over TCP/TLS and optional HTTP/2
over TLS with C<http2 =E<gt> 1> (Unblock::HTTP2 0.13 or later). HTTPS verifies
the certificate and original hostname by default. C<tls> accepts Linux::Event
TLS options such as C<ca_file>. HTTP owns the hostname and ALPN selection.
C<native_input =E<gt> 0> selects the Perl input path for diagnostics.
HTTP/2 uses ALPN and multiplexes operations through Unblock's pool. Ordinary
requests can fall back to HTTP/1; C<http_version =E<gt> '2'> fails if HTTP/2
cannot be negotiated. HTTP/2 C<on_error> may include a third protocol error-code
argument. HTTP/3 is optional through C<http3 =E<gt> 1> using Net::QUIC 0.06 and
Unblock::HTTP3 0.14. C<quic =E<gt> { ca_file =E<gt> ... }> configures
QUIC-specific trust and transport options. Origin hostnames are resolved
asynchronously by Linux::Event UDP, and QUIC authenticates the original
HTTPS origin, even when an alternative endpoint is used.
Opt-in C<http1 =E<gt> { websocket =E<gt> 1 }> enables the inherited
C<connect_websocket()> entry point. It transfers the whole HTTP1 socket
to the established Unblock::WebSocket session without introducing a second
pool; a normal HTTP request can continue on another socket. The same-read
native input handoff is verified. Optional C<http2 =E<gt>
{ websocket =E<gt> 1 }> uses multiplexed Extended CONNECT, verified
alongside ordinary H2 requests. HTTP3 Extended CONNECT messages and
graceful WebSocket Close/FIN are verified by real QUIC loopback, with
the completion-recheck fix included in Unblock::HTTP3 0.14.
Generic H2/H3 CONNECT uses C<request(method =E<gt> 'CONNECT',
protocol =E<gt> 'raw-tunnel', http_version =E<gt> '2' or '3',
on_handoff =E<gt> sub ($tx, $response, $bridge) { ... })>.
The callback returns a byte consumer supporting C<input>,
C<input_eof>, C<transport_error> and C<resume_output>.
C<$bridge-E<gt>unblock_send> and C<unblock_finish> write/end the
stream without closing its TLS/QUIC parent. The Client waits for
peer Extended CONNECT SETTINGS automatically; normal H2/H3 sibling
HTTP operations continue through the pool. A non-2xx response
does not invoke C<on_handoff>; the unused outgoing CONNECT writer
is finished and the HTTP response is returned normally.
No redirects, cookies, authentication retries or response wrappers are added.

=cut
