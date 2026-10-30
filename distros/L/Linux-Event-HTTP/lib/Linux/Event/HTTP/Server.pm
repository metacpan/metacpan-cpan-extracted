package Linux::Event::HTTP::Server;
use v5.36;
use Carp qw(croak);
use Scalar::Util qw(weaken refaddr);
use Unblock::HTTP::Server 0.03;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::_Config;
use Linux::Event::HTTP::_Stream;

our $VERSION = '0.004';

sub new ($class, %option) {
    my $loop = delete $option{loop};
    Linux::Event::HTTP::_Config::loop($loop);
    my $stream_class = Linux::Event::HTTP::_Config::stream_class(\%option);
    my %protocols = Linux::Event::HTTP::_Config::protocols(\%option);
    # Keep the capability check for mixed or incomplete installations.
    # Check once at construction, before binding, never per request.
    if ($protocols{http1}) {
        require Unblock::HTTP1::Server;
        croak 'new(): Unblock::HTTP1::Server lacks drain() required for HTTP/1 graceful shutdown; install a compatible Unblock::HTTP1 build'
            unless Unblock::HTTP1::Server->can('drain');
    }
    my $quic = delete($option{quic}) // {};
    croak 'new(): quic must be a hash reference' unless ref($quic) eq 'HASH';
    croak 'new(): quic requires http3 => 1' if %$quic && !$protocols{http3};
    my %callbacks;
    for my $name (qw(on_headers on_request on_error on_websocket on_handoff)) {
        $callbacks{$name} = delete $option{$name} if exists $option{$name};
    }
    # H2/H3 Extended CONNECT WebSocket output must be scheduled outside
    # the native protocol receive stack. H1 Upgrade does not use this hook.
    my $defer = sub ($callback) { $loop->defer($callback) };
    my $definition = Unblock::HTTP::Server->new(
        %protocols, %callbacks, defer => $defer,
    );
    my $self = bless { loop => $loop, definition => $definition,
        connections => {} }, $class;
    my $state = { server => $self };
    weaken($state->{server});
    my %stream = (class => $stream_class, data => $state);
    for my $name (qw(tls tuning)) {
        $stream{$name} = delete $option{$name} if exists $option{$name};
    }
    croak 'new(): HTTP/2 Server requires tls for ALPN negotiation'
        if exists($protocols{http2}) && !exists($stream{tls});
    if (exists $protocols{http3}) {
        croak 'new(): HTTP3 requires a concrete host (not a wildcard)'
            unless defined($option{host})
                && $option{host} ne '0.0.0.0' && $option{host} ne '::';
        croak 'new(): HTTP3 requires TLS cert_file and key_file'
            unless ref($stream{tls}) eq 'HASH'
                && $stream{tls}{cert_file} && $stream{tls}{key_file};
        croak 'new(): HTTP3-only listeners are not implemented yet'
            unless exists($protocols{http1}) || exists($protocols{http2});
    }
    if (exists $stream{tls}) {
        croak 'new(): tls must be a hash reference' unless ref($stream{tls}) eq 'HASH';
        croak 'new(): HTTP Server owns TLS alpn' if exists $stream{tls}{alpn};
        $stream{tls} = { %{ $stream{tls} }, alpn => [$definition->alpn_protocols] };
    }
    my $on_error = delete $option{on_listener_error};
    my %listen;
    for my $name (qw(host port path fh backlog reuseaddr reuseport v6only unlink_on_close)) {
        $listen{$name} = delete $option{$name} if exists $option{$name};
    }
    croak 'new(): unknown option: ' . join(', ', sort keys %option) if %option;
    $self->{listener} = Linux::Event::IO::Sock::Listener->new(
        loop => $loop, %listen, stream => \%stream,
        on_accept => sub ($listener, $stream) {
            my $server = $state->{server};
            $server ? $server->_track($stream) : $stream->close;
        },
        (defined($on_error) ? (on_error => $on_error) : ()),
    );
    if (exists $protocols{http3}) {
        require Unblock::HTTP::QUIC;
        require Linux::Event::HTTP::_QUICSocket;
        my $socket = Linux::Event::HTTP::_QUICSocket->new(
            loop => $loop, host => $listen{host}, port => $self->port,
            (defined($on_error) ? (on_error => $on_error) : ()),
            on_progress => sub {
                my $server = $state->{server} or return;
                $server->_quic_progress;
            },
        );
        my $manager = Unblock::HTTP::QUIC->server(
            server => $definition,
            certificate_file => $stream{tls}{cert_file},
            private_key_file => $stream{tls}{key_file},
            %$quic,
            send => $socket->send_callback,
            set_timeout => $socket->set_timeout_callback,
            on_ready => sub ($engine, $quic_manager) {
                my $server = $state->{server} or return;
                $server->_quic_ready($engine);
            },
        );
        $self->{quic} = { socket => $socket, manager => $manager };
        $socket->start($manager);
    }
    return $self;
}

sub loop ($self) { $self->{loop} }
sub listener ($self) { $self->{listener} }
sub host ($self) { $self->{listener}->host }
sub port ($self) { $self->{listener}->port }
sub pause ($self) { $self->{listener}->pause; return $self }
sub resume ($self) { $self->{listener}->resume; return $self }
sub close ($self) {
    $self->{listener}->close;
    if ($self->{quic} && !$self->{quic_closing}++) {
        for my $engine ($self->{quic}{manager}->sessions) {
            $engine->shutdown_notice unless $engine->shutdown_notice_sent;
            $engine->shutdown unless $engine->shutdown_started;
        }
        $self->_quic_progress;
    }
    return $self;
}
sub connection_count ($self) {
    my $count = scalar keys %{ $self->{connections} };
    $count += scalar($self->{quic}{manager}->sessions) if $self->{quic};
    return $count;
}

sub shutdown ($self, %option) {
    my $grace = delete($option{grace}) // 30;
    my $complete = delete $option{on_complete};
    croak 'shutdown(): grace must be a non-negative number of seconds'
        unless !ref($grace) && $grace =~ /\A(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)\z/;
    croak 'shutdown(): on_complete must be a coderef'
        if defined($complete) && ref($complete) ne 'CODE';
    croak 'shutdown(): unknown option: ' . join(', ', sort keys %option) if %option;
    return $self if $self->{shutdown};
    $self->{shutdown} = 1;
    $self->{shutdown_complete} = $complete;
    $self->close;
    # A synchronous close can remove a stream while this snapshot is drained.
    for my $stream (values %{ $self->{connections} }) {
        $stream->_http_drain;
    }
    if ($self->connection_count) {
        my $weak = $self;
        weaken($weak);
        $self->{shutdown_timer} = Linux::Event::Kernel::Timer->new(
            loop => $self->{loop}, after => $grace,
            on_timer => sub {
                my $server = $weak or return;
                $_->close for values %{ $server->{connections} };
                if (my $quic = delete $server->{quic}) {
                    $quic->{socket}->close;
                }
                $server->_shutdown_done;
            },
        );
    }
    $self->_quic_progress if $self->{quic};
    $self->_shutdown_done;
    return $self;
}

sub _shutdown_done ($self) {
    return unless $self->{shutdown} && !$self->connection_count && !$self->{quic};
    return if $self->{shutdown_notified}++;
    my $timer = delete $self->{shutdown_timer};
    $timer->cancel if $timer;
    my $complete = delete $self->{shutdown_complete};
    $complete->($self) if $complete;
    return;
}


sub _quic_ready ($self, $engine) {
    if ($self->{quic_closing}) {
        $engine->quic->close unless $engine->quic->closed;
    }
    return;
}

sub _quic_progress ($self) {
    my $quic = $self->{quic} or return;
    return unless $self->{quic_closing};
    my @sessions = $quic->{manager}->sessions;
    for my $engine (@sessions) {
        my $connection = $engine->quic;
        next if $connection->closed;
        if ($self->{shutdown} && ($engine->failed || $engine->drained)) {
            $connection->close;
        }
    }
    # If no sessions are admitted, a handshake in progress has no HTTP
    # application transaction to preserve. Close the UDP listener.
    if (!@sessions) {
        delete $self->{quic};
        $quic->{socket}->close;
        $self->_shutdown_done if $self->{shutdown};
    }
    return;
}

sub _track ($self, $stream) {
    return if $stream->is_closed;
    return $stream->close if $self->{shutdown};
    $self->{connections}{refaddr($stream)} = $stream;
    return;
}

sub _attach ($self, $stream) {
    if ($self->{shutdown}) { $stream->close; return }
    $self->_track($stream);
    return $self->{definition}->attach_stream(
        transport => $stream, alpn => $stream->selected_alpn,
    );
}

sub _closed ($self, $stream) {
    delete $self->{connections}{refaddr($stream)};
    $self->_shutdown_done if $self->{shutdown};
    return;
}

1;

__END__

=head1 NAME

Linux::Event::HTTP::Server - Native Linux listener for Unblock HTTP

=head1 SYNOPSIS

    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop, port => 8080,
        on_request => sub ($tx, $request) {
            $tx->respond(status => 200, body => "Hello\n");
        },
    );

=head1 DESCRIPTION

HTTP/1 is enabled by default. Callbacks receive real Unblock transactions
and Uniform messages. C<on_headers> runs before the body; C<on_request> runs
once after successful body completion. Set C<$tx-E<gt>on_data(...)> during
C<on_headers> to stream a request. Otherwise Unblock buffers up to 1 MiB;
configure C<http1 =E<gt> { max_buffered_body_bytes =E<gt> ... }> to change it.

C<tls> and C<tuning> configure the Linux::Event listener's accepted streams.
HTTP owns TLS ALPN selection; do not specify C<tls =E<gt> { alpn =E<gt> ... }>.
C<native_input =E<gt> 0> selects the Perl input path for diagnostics.
C<on_listener_error> receives listener failures; C<on_error> is the HTTP
engine error callback. Unknown options are rejected.

C<loop>, C<listener>, C<host>, C<port>, C<pause>, C<resume>, C<close> and
C<connection_count> expose listener controls and live connection count.
C<close> stops accepting connections; existing connections continue.

C<shutdown(grace =E<gt> 30, on_complete =E<gt> sub ($server) { ... })>
stops listening, drains admitted HTTP/1 requests, and closes remaining owned
connections when the grace period expires. TLS handshakes without admitted
requests close immediately. Completion runs once after owned connections
and their transactions have finished; it can run synchronously if idle.
Repeated shutdown calls have no effect. C<grace> is non-negative seconds.
C<on_handoff> enables generic HTTP1 101 Upgrade and successful CONNECT
handoff for non-WebSocket protocols. It runs after HTTP accepts the
switch response into the existing write queue and receives
C<($tx, $request, $response, $transport)>. Return a successor protocol
object implementing C<input>, C<input_eof>, C<transport_error>
and C<resume_output>. The Linux::Event stream transitions in place;
any same-read native input tail is preserved without duplication.
The successor owns the socket after handoff. WebSocket handshakes take
precedence when both callbacks are enabled. For HTTP2/HTTP3, C<on_handoff($tx, $request, $bridge)> returns a
stream-local consumer for a CONNECT request (not a whole socket).
The Server responds with status 200, forwards DATA and EOF to the
consumer, and preserves ordinary sibling streams. Return undef to
reject with 403. Configure C<http2 =E<gt>
{ enable_connect_protocol =E<gt> 1 }> or C<http3 =E<gt>
{ enable_extended_connect =E<gt> 1 }> for Extended CONNECT; no
WebSocket advertisement is required. The bridge accepts
C<unblock_send>, C<unblock_finish>, and C<unblock_abort>, with
deferred bounded output. It invokes C<resume_output> for flow
control. Generic handoff never replaces the multiplexed transport.

C<http2 =E<gt> 1> enables optional Unblock::HTTP2 (at least 0.13). Server
HTTP/2 requires TLS and uses ALPN, with HTTP/1 fallback unless C<http1 =E<gt> 0>.
A hashref supplies HTTP/2 engine tuning. Shutdown sends GOAWAY and drains
admitted streams. Cleartext HTTP/2 remains unimplemented.
HTTP/2 C<on_error> may include a third protocol error-code argument.
Optional C<http3 =E<gt> 1> uses Unblock::HTTP3 0.14 and Net::QUIC 0.06 on UDP
alongside the TCP listener at the same concrete host and port. Its
credentials are taken from C<tls =E<gt> { cert_file, key_file }>.
C<quic =E<gt> { ... }> configures Net::QUIC server transport policy.
Wildcard-bound HTTP3 and H3-only listeners are not yet supported.
C<close> stops H3 admission by sending GOAWAY to attached sessions;
C<shutdown> also waits for draining sessions until the grace deadline.
Forced expiry releases the UDP socket and timer. The supported concrete-address
HTTP3 lifecycle passed the Stage D QUIC loopback and cleanup tests.

Opt-in C<http1 =E<gt> { websocket =E<gt> 1 }> with C<on_websocket>
uses Unblock's HTTP1 handshake and transitions the same Linux::Event
socket to WebSocket without losing same-read bytes. Native and Perl
input paths are tested. C<http2 =E<gt> { websocket =E<gt> 1 }> and
C<http3 =E<gt> { websocket =E<gt> 1 }> enable Extended CONNECT on
individual multiplexed streams. The H2 path passes real TLS loopback.
H2 and H3 WebSocket Extended CONNECT are verified by real TLS and QUIC
loopback with independent ordinary HTTP streams. Unblock::HTTP3 0.14
includes the completion-order fix for WebSocket Close and stream FIN.
WebSocket remains an optional dependency, loaded only when enabled.

=cut
