package Linux::Event::HTTP::_QUICSocket;
use v5.36;
use Carp qw(croak);
use POSIX qw(isfinite);
use Scalar::Util qw(weaken refaddr looks_like_number);
use Socket qw(AF_INET6 inet_pton);
use Linux::Event::Address;
use Linux::Event::IO::Sock::Dgram;
use Linux::Event::Kernel::Timer;

# This adapter deliberately binds one concrete address. Linux::Event's
# datagram callback has no per-packet destination address for wildcard binds.
# Net::QUIC cannot route a received packet using a wildcard local address.
sub _concrete ($address) {
    return 0 unless $address && ($address->family eq 'inet' || $address->family eq 'inet6');
    my $host = $address->host;
    return $host ne '0.0.0.0' if $address->family eq 'inet';
    my $packed = inet_pton(AF_INET6, $host);
    return defined($packed) && $packed ne ("\0" x 16);
}

sub new ($class, %option) {
    my $loop = delete $option{loop};
    my $host = delete $option{host};
    my $port = delete $option{port};
    my $on_error = delete $option{on_error};
    my $on_progress = delete $option{on_progress};
    croak 'QUIC socket requires loop, host and port'
        unless $loop && defined($host) && defined($port);
    croak 'QUIC socket on_error must be a coderef'
        if defined($on_error) && ref($on_error) ne 'CODE';
    croak 'QUIC socket on_progress must be a coderef'
        if defined($on_progress) && ref($on_progress) ne 'CODE';
    croak 'QUIC socket unknown options: ' . join(', ', sort keys %option) if %option;
    croak 'QUIC socket requires a concrete local host, not a wildcard address'
        if $host eq '0.0.0.0' || $host eq '::';
    my $self = bless { loop => $loop, on_error => $on_error,
        on_progress => $on_progress }, $class;
    my $weak = $self;
    weaken($weak);
    $self->{socket} = Linux::Event::IO::Sock::Dgram->new(
        loop => $loop, host => $host, port => $port,
        on_datagram => sub ($socket, $bytes, $peer) {
            my $owner = $weak or return;
            my $manager = $owner->{manager} or return;
            $manager->receive($bytes, $owner->{local}, $peer->sockaddr);
            $owner->_progress;
        },
        on_drain => sub {
            my $owner = $weak or return;
            my $manager = $owner->{manager} or return;
            $manager->writable;
            $owner->_progress;
        },
        on_error => sub ($socket, $error) {
            my $owner = $weak or return;
            $owner->{on_error}->($socket, $error) if $owner->{on_error};
        },
        on_close => sub {
            my $owner = $weak or return;
            $owner->close;
        },
    );
    my $local = $self->{socket}->local;
    unless (_concrete($local)) {
        $self->close;
        croak 'QUIC socket requires a concrete IPv4/IPv6 local address';
    }
    $self->{local} = $local->sockaddr;
    return $self;
}

sub socket ($self) { $self->{socket} }
sub local ($self) { $self->{local} }


# A connected socket delegates hostname resolution to Linux::Event's async
# datagram resolver. QUIC TLS still authenticates the original HTTP origin.
sub connect ($class, %option) {
    my $loop = delete $option{loop};
    my $host = delete $option{host};
    my $port = delete $option{port};
    my $on_ready = delete $option{on_ready};
    my $on_error = delete $option{on_error};
    my $on_progress = delete $option{on_progress};
    croak 'QUIC connect requires loop, host and port'
        unless $loop && defined($host) && defined($port);
    for my $pair ([on_ready => $on_ready], [on_error => $on_error],
                  [on_progress => $on_progress]) {
        croak "QUIC connect $pair->[0] must be a coderef"
            if defined($pair->[1]) && ref($pair->[1]) ne 'CODE';
    }
    croak 'QUIC connect requires on_ready' unless $on_ready;
    croak 'QUIC connect unknown options: ' . join(', ', sort keys %option)
        if %option;
    my $self = bless {
        loop => $loop, connected => 1, on_error => $on_error,
        on_progress => $on_progress,
    }, $class;
    my $weak = $self;
    weaken($weak);
    $self->{socket} = Linux::Event::IO::Sock::Dgram->connect(
        loop => $loop, host => $host, port => $port,
        on_ready => sub ($socket) {
            my $owner = $weak or return;
            return if $owner->{closed};
            my $local = $socket->local;
            unless (_concrete($local) && $socket->peer) {
                $owner->{on_error}->($socket, 'QUIC client needs a concrete local and peer')
                    if $owner->{on_error};
                $owner->close;
                return;
            }
            $owner->{local} = $local->sockaddr;
            $owner->{peer} = $socket->peer->sockaddr;
            $on_ready->($owner);
        },
        on_datagram => sub ($socket, $bytes, $peer) {
            my $owner = $weak or return;
            my $manager = $owner->{manager} or return;
            $manager->receive($bytes, $owner->{local}, $peer->sockaddr);
            $owner->_progress;
        },
        on_drain => sub {
            my $owner = $weak or return;
            my $manager = $owner->{manager} or return;
            $manager->writable;
            $owner->_progress;
        },
        on_error => sub ($socket, $error) {
            my $owner = $weak or return;
            $owner->{on_error}->($socket, $error) if $owner->{on_error};
        },
        on_close => sub {
            my $owner = $weak or return;
            $owner->close;
        },
    );
    return $self;
}

sub peer ($self) { $self->{peer} }

sub _progress ($self) {
    $self->{on_progress}->($self) if !$self->{closed} && $self->{on_progress};
    return;
}

sub send_callback ($self) {
    my $weak = $self;
    weaken($weak);
    return sub ($packet) {
        my $owner = $weak or croak 'QUIC socket no longer exists';
        croak 'QUIC socket is closed' if $owner->{closed};
        croak 'QUIC datagram uses a different source address'
            if $packet->local ne $owner->{local};
        if ($owner->{connected}) {
            croak 'QUIC datagram uses a different destination address'
                if $packet->peer ne $owner->{peer};
            return $owner->{socket}->send($packet->data);
        }
        return $owner->{socket}->send(
            $packet->data,
            to => Linux::Event::Address->new($packet->peer),
        );
    };
}

sub set_timeout_callback ($self) {
    my $weak = $self;
    weaken($weak);
    return sub ($seconds) {
        my $owner = $weak or return;
        return if $owner->{closed};
        $owner->_set_timeout($seconds);
    };
}

sub _set_timeout ($self, $seconds) {
    if (my $old = delete $self->{timer}) {
        $old->cancel;
    }
    return unless defined $seconds;
    croak 'QUIC timeout must be finite, non-negative seconds'
        unless !ref($seconds) && looks_like_number($seconds)
            && isfinite(0 + $seconds) && $seconds >= 0;
    my $weak = $self;
    weaken($weak);
    $self->{timer} = Linux::Event::Kernel::Timer->new(
        loop => $self->{loop}, after => $seconds,
        on_timer => sub ($timer) {
            my $owner = $weak or return;
            return if $owner->{closed};
            my $current = $owner->{timer} or return;
            return unless refaddr($current) == refaddr($timer);
            delete $owner->{timer};
            my $manager = $owner->{manager} or return;
            $manager->timeout;
            $owner->_progress;
        },
    );
    return;
}

sub start ($self, $manager) {
    croak 'QUIC socket has been closed' if $self->{closed};
    croak 'QUIC socket already started' if $self->{manager};
    croak 'QUIC manager must implement start, receive, timeout and writable'
        unless ref($manager) && !grep { !$manager->can($_) }
            qw(start receive timeout writable);
    $self->{manager} = $manager;
    $manager->start;
    $self->_progress;
    return $self;
}

sub close ($self) {
    return $self if $self->{closed}++;
    my $timer = delete $self->{timer};
    $timer->cancel if $timer;
    delete $self->{manager};
    delete $self->{on_progress};
    delete $self->{on_error};
    my $socket = delete $self->{socket};
    $socket->close if $socket && $socket->is_active;
    return $self;
}

1;
