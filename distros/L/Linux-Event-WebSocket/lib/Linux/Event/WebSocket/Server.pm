package Linux::Event::WebSocket::Server;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);

use Linux::Event::IO::Sock::Listener;
use Linux::Event::WebSocket::Server::Connection;
use Linux::Event::WebSocket::Server::_HTTPConnection;

our $VERSION = '0.003';

my $DEFAULT_MAX_MESSAGE_SIZE = 16 * 1024 * 1024;

sub _load_connection_class ($class) {
    croak 'new(): connection_class must be a package name'
        if !defined($class) || ref($class)
        || $class !~ /\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/;

    if (!$class->can('send_text')) {
        (my $file = "$class.pm") =~ s{::}{/}g;
        require $file;
    }

    croak 'new(): connection_class must inherit Linux::Event::WebSocket::Server::Connection'
        if !$class->isa('Linux::Event::WebSocket::Server::Connection');
    return $class;
}

sub _take_callback ($name, $option) {
    return undef if !exists $option->{$name};
    my $callback = delete $option->{$name};
    croak "new(): $name must be a coderef" if ref($callback) ne 'CODE';
    return $callback;
}

sub _subprotocols ($value) {
    croak 'new(): subprotocols must be an array reference'
        if ref($value) ne 'ARRAY';

    my @copy;
    for my $token (@$value) {
        croak 'new(): each subprotocol must be a WebSocket token'
            if !defined($token) || ref($token)
            || $token !~ /\A[!#\$%&'*+\-.^_`|~0-9A-Za-z]+\z/;
        push @copy, "$token";
    }
    return \@copy;
}

sub _positive_integer ($where, $value) {
    croak "$where must be a positive integer"
        if !defined($value) || ref($value)
        || "$value" !~ /\A[0-9]+\z/ || $value < 1;
    return 0 + $value;
}

sub _nonnegative_number ($where, $value) {
    croak "$where must be a non-negative number"
        if !defined($value) || ref($value)
        || "$value" !~ /\A(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)\z/;
    return 0 + $value;
}

sub new ($class, %option) {
    my $connection_class = _load_connection_class(
        delete($option{connection_class})
            // 'Linux::Event::WebSocket::Server::Connection',
    );

    my %callbacks;
    for my $name (qw(on_open on_message on_close on_error on_drain)) {
        my $callback = _take_callback($name, \%option);
        (my $short = $name) =~ s/\Aon_//;
        $callbacks{$short} = $callback if $callback;
    }

    my $on_handshake = _take_callback('on_handshake', \%option);
    my $on_listener_error = _take_callback('on_listener_error', \%option);

    my $subprotocols = _subprotocols(
        exists($option{subprotocols}) ? delete($option{subprotocols}) : [],
    );
    my $close_timeout = _nonnegative_number(
        'new(): close_timeout',
        exists($option{close_timeout}) ? delete($option{close_timeout}) : 5,
    );
    my $max_message_size = _positive_integer(
        'new(): max_message_size',
        exists($option{max_message_size})
            ? delete($option{max_message_size})
            : $DEFAULT_MAX_MESSAGE_SIZE,
    );
    my $data = delete $option{data};
    my $secure = exists($option{tls}) ? 1 : 0;

    my $config = bless {
        connection_class => $connection_class,
        callbacks        => \%callbacks,
        on_handshake      => $on_handshake,
        subprotocols      => $subprotocols,
        close_timeout     => $close_timeout,
        max_message_size  => $max_message_size,
        data              => $data,
        secure            => $secure,
    }, 'Linux::Event::WebSocket::Server::_Config';

    my %stream = (
        class => 'Linux::Event::WebSocket::Server::_HTTPConnection',
        data  => $config,
    );
    for my $name (qw(tls tuning)) {
        $stream{$name} = delete $option{$name} if exists $option{$name};
    }
    my $listener = Linux::Event::IO::Sock::Listener->new(
        %option, stream => \%stream,
        (defined($on_listener_error)
            ? (on_error => $on_listener_error) : ()),
    );

    return bless {
        listener         => $listener,
        config           => $config,
        data             => $data,
        connection_class => $connection_class,
    }, $class;
}

# Retain the old convenience accessor for source compatibility. With
# standalone Unblock::HTTP1 owning only the opening handshake there is no
# longer an HTTP Server object; listener() is the clear accessor.
sub http_server      ($self) { $self->{listener} }
sub listener         ($self) { $self->{listener} }
sub connection_class ($self) { $self->{connection_class} }
sub data             ($self) { $self->{data} }
sub loop             ($self) { $self->{listener}->loop }
sub host             ($self) { $self->{listener}->host }
sub port             ($self) { $self->{listener}->port }
sub path             ($self) { $self->{listener}->path }
sub state            ($self) { $self->{listener}->state }

sub pause ($self) { $self->{listener}->pause; return $self }
sub resume ($self) { $self->{listener}->resume; return $self }
sub close ($self) { $self->{listener}->close; return $self }

1;

__END__

=head1 NAME

Linux::Event::WebSocket::Server - callback-first WebSocket server

=head1 SYNOPSIS

    use v5.36;
    use Linux::Event::Loop;
    use Linux::Event::WebSocket::Server;

    my $loop = Linux::Event::Loop->new;

    my $server = Linux::Event::WebSocket::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 8080,

        on_open => sub ($ws) {
            $ws->send_text('hello');
        },

        on_message => sub ($ws, $payload, $type) {
            $ws->send_text("echo: $payload") if $type eq 'text';
        },

        on_close => sub ($ws, $code, $reason) {
            ...;
        },
    );

    $loop->run;

=head1 DESCRIPTION

C<Linux::Event::WebSocket::Server> attaches the standalone
L<Unblock::HTTP1> engine to a Linux::Event listener for the HTTP/1.1 Upgrade. A successful
handshake transitions the same live Linux::Event stream in place to
L<Linux::Event::WebSocket::Server::Connection>.

The socket, TLS transport, queued output, backpressure state, and already-read
post-HTTP bytes remain on that same connection object.

C<listener> returns the native Linux::Event listener. The older
C<http_server> accessor is retained as an alias to the listener; it no longer
returns an HTTP Server object, because opening handshakes run directly through
Unblock::HTTP1.

=head1 CALLBACKS

C<on_open> receives the established WebSocket connection. C<on_message>
receives the connection, payload, and type (C<text> or C<binary>). Text payloads
are decoded UTF-8 Perl strings; binary payloads remain bytes.

C<on_close> receives the connection, peer close code, and reason. C<on_error>
receives the connection and an error. C<on_drain> follows Linux::Event output
backpressure semantics.

C<on_handshake> is optional and receives the parsed HTTP Request before
WebSocket validation. Return true to continue or false to reject the Upgrade
with HTTP 403.

=head1 LIMITS

C<max_message_size> defaults to 16 MiB and may be set to another positive byte
limit. The same bound also protects the frame reader from allocating an
unreasonably large single frame.

=head1 SUBPROTOCOLS

    my $server = Linux::Event::WebSocket::Server->new(
        loop => $loop,
        port => 8080,
        subprotocols => [qw(chat superchat)],
        on_message => sub ($ws, $payload, $type) { ... },
    );

The established connection exposes the negotiated value through
C<< $ws->subprotocol >>.

=head1 TLS

Pass Linux::Event listener C<tls> options to serve C<wss://>.
TLS remains attached when the HTTP connection transitions to WebSocket.

=head1 CONNECTION SUBCLASSES

C<connection_class> may name a subclass of
L<Linux::Event::WebSocket::Server::Connection>. The hierarchy remains ordinary
single inheritance.

Callback options take precedence over optional subclass hooks named
C<websocket_open>, C<websocket_message>, C<websocket_close>,
C<websocket_error>, and C<websocket_drain>.

=cut
