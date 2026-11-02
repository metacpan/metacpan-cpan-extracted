package Linux::Event::HTTP::Server;
use v5.36;
use Carp qw(croak);
use Scalar::Util qw(weaken refaddr);
use Unblock::HTTP::Server 0.03;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::_Config;
use Linux::Event::HTTP::_Stream;

our $VERSION = '0.005';

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

Linux::Event::HTTP::Server - Serve HTTP requests with Linux::Event

=head1 SYNOPSIS

    use v5.36;
    use Linux::Event::Loop;
    use Linux::Event::HTTP::Server;

    my $loop = Linux::Event::Loop->new;

    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 8080,

        on_request => sub ($tx, $req) {
            $tx->respond(
                status  => 200,
                headers => [['content-type', 'text/plain']],
                body    => "Hello from Linux::Event!\n",
            );
        },
    );

    say "Listening on http://127.0.0.1:8080/";
    $loop->run;

Save this as C<server.pl> and run C<perl server.pl>. In another
terminal, try:

    curl http://127.0.0.1:8080/

The server keeps running until you stop it.

=head1 DESCRIPTION

C<Linux::Event::HTTP::Server> listens for HTTP requests and calls your
code to handle them. You do not need to read from sockets or parse HTTP
yourself. HTTP/1.1 works by default; HTTP/2 and HTTP/3 are optional.

=head1 HANDLING REQUESTS

C<on_request> runs when a complete request arrives. It receives:

=over 4

=item * C<$req> - the request, with its method, URL target, headers, and body.

=item * C<$tx> - the transaction you use to send a response.

=back

Read the request with:

    $req->method;                  # GET, POST, ...
    $req->target;                  # /items?color=blue
    $req->header('content-type');  # A request header
    $req->body;                    # Complete request body

C<target> includes the query string. This module does not provide
a router; you can inspect the method and target yourself.

For example, replace C<on_request> in the first example with:

    on_request => sub ($tx, $req) {
        if ($req->method eq 'GET' && $req->target eq '/') {
            $tx->respond(status => 200, body => "Welcome\n");
        }
        elsif ($req->method eq 'POST' && $req->target eq '/echo') {
            $tx->respond(status => 200, body => $req->body);
        }
        else {
            $tx->respond(status => 404, body => "Not found\n");
        }
    },

Use C<$tx-E<gt>respond> to send the status, headers, and body.
Headers are an array reference of name/value pairs:

    $tx->respond(
        status  => 200,
        headers => [['content-type', 'text/html; charset=utf-8']],
        body    => '<h1>Hello</h1>',
    );

=head1 RECEIVING LARGE REQUESTS

By default, the server collects each request body before calling
C<on_request>. The body has a 1 MiB limit by default. A larger
non-streamed body fails rather than using unlimited memory.

If an upload might be large, receive it a chunk at a time. Supply
C<on_headers> alongside C<on_request> in the server constructor:

    on_headers => sub ($tx, $req) {
        $tx->on_data(sub ($tx, $bytes) {
            say "Received ", length($bytes), " bytes";
        });
    },

    on_request => sub ($tx, $req) {
        $tx->respond(status => 200, body => "Upload complete\n");
    },

C<on_headers> runs before body data arrives. Registering C<on_data>
there tells the server to stream the body instead of collecting it
in C<$req-E<gt>body>. C<on_request> still runs after the upload
finishes successfully; it does not run if the request fails.

To change the HTTP/1 buffered body limit, pass
C<http1 =E<gt> { max_buffered_body_bytes =E<gt> $bytes }>
to C<new>.

=head1 SENDING LARGE RESPONSES

For a response made in pieces, start with C<stream_body =E<gt> 1>,
then send data with C<write> and finish with C<end>:

    $tx->respond(status => 200, stream_body => 1);
    $tx->write("First part\n");
    $tx->end("Last part\n");

If a producer sends lots of data, use C<on_drain> to resume when the
connection has room again. A false result from C<write> means
the bytes were B<accepted>, but you must pause before writing more.
Do not resend that chunk.

=head1 HTTPS AND HTTP VERSIONS

To serve HTTPS, give the server a certificate and private key:

    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 8443,
        tls => {
            cert_file => 'cert.pem',
            key_file  => 'key.pem',
        },
        on_request => sub ($tx, $req) {
            $tx->respond(status => 200, body => "Secure\n");
        },
    );

HTTP/1.1 is enabled by default. To also serve HTTP/2, install
L<Unblock::HTTP2> 0.13 or newer and set C<http2 =E<gt> 1>.
HTTP/2 servers require TLS.

To also serve HTTP/3, install L<Unblock::HTTP3> 0.14 or newer
and L<Net::QUIC> 0.06 or newer, then set C<http3 =E<gt> 1>.
HTTP/3 needs TLS, a specific C<host> address (not a wildcard),
and a TCP listener alongside its UDP listener.

The same C<on_request> callback handles all enabled HTTP versions.

=head1 ERRORS AND SERVER CONTROL

C<on_error> reports HTTP transaction errors. C<on_listener_error>
reports problems accepting connections. Both are optional options
to C<new>:

    on_error => sub ($tx, $error, @details) {
        warn "HTTP error: $error\n";
    },
    on_listener_error => sub ($listener, $error) {
        warn "Listener error: $error\n";
    },

C<host> and C<port> return the listening address and port.
C<connection_count> returns the number of live connections.
C<pause> and C<resume> control acceptance of new connections.

C<close> stops accepting new connections but does not immediately
discard work already in progress. To shut down gracefully:

    $server->shutdown(
        grace => 30,
        on_complete => sub ($server) {
            $loop->stop;
        },
    );

C<grace> is in seconds. The server finishes admitted work when
possible and closes remaining connections at the deadline.
C<on_complete> runs when shutdown is done; it may run immediately
if the server is idle.

=head1 WEBSOCKETS AND CONNECT

WebSockets are optional. Enable them for an HTTP version, such as
C<http1 =E<gt> { websocket =E<gt> 1 }>, and provide
C<on_websocket>. See L<Unblock::HTTP::Server> for the WebSocket
callback options.

For custom protocol upgrades and CONNECT tunnels, see
C<docs/CONNECT.md> in the distribution. Neither feature is needed
for ordinary HTTP servers.

=head1 SEE ALSO

L<Linux::Event::HTTP::Client>, L<Linux::Event::Loop>,
L<Uniform::HTTP::Request>.

The distribution's C<docs/GETTING-STARTED.md> has more examples.

=cut
