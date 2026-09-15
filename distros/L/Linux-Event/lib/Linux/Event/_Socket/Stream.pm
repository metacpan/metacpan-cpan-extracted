package Linux::Event::_Socket::Stream;
use v5.36;
use strict;
use warnings;


use parent 'Linux::Event::_ByteStream';
use Carp qw(croak);
use Scalar::Util qw(blessed);
use Socket qw(SOL_SOCKET SO_ERROR SO_TYPE SOCK_STREAM SHUT_RD SHUT_WR);

use Linux::Event::Address;
use Linux::Event::Error;
use Linux::Event::_Socket::Connection ();
use Linux::Event::_Socket::Descriptor ();
use Linux::Event::_SocketConfig ();

# Constructors and class lifecycle

sub new ($class, %opt) {
    croak 'new(): must be called as a class method' if ref $class;
    my $loop = delete $opt{loop};
    croak 'new(): loop must be an object implementing add() and watch_fd()'
        if defined($loop) && (!ref($loop) || !$loop->can('add')
            || !$loop->can('watch_fd'));
    my $fh = delete $opt{fh};
    croak 'new(): Socket requires fh' if !defined($fh) || !defined(fileno($fh));
    croak 'new(): Socket does not accept read_fh or write_fh'
        if exists($opt{read_fh}) || exists($opt{write_fh});
    my $accepted = delete($opt{_accepted}) // 0;
    my $peer = delete $opt{peer};
    my $tls_role = delete $opt{tls_role};
    my $transport = delete $opt{transport};
    croak 'new(): transport must be an object implementing _stream_transport_bind()'
        if defined($transport)
        && (!blessed($transport) || !$transport->can('_stream_transport_bind'));
    croak 'new(): tls_role cannot be combined with accepted mode'
        if $accepted && defined $tls_role;
    my $override = Linux::Event::_SocketConfig::extract('new', \%opt);
    my $socket_descriptor = Linux::Event::_Socket::Descriptor::for_class($class);
    my ($local, $resolved_peer, $policy) = _socket_setup(
        $fh, $socket_descriptor, $override, $peer,
    );
    if (my $tls = $socket_descriptor->{tls}) {
        if (!$accepted) {
            croak 'new(): transport cannot be supplied for a TLS-declared Socket'
                if defined $transport;
            require Linux::Event::TLS;
            croak 'new(): a TLS-declared adopted fh requires tls_role'
                if !defined $tls_role;
            croak 'new(): tls_role must be client or server'
                if $tls_role ne 'client' && $tls_role ne 'server';
            $transport = $tls_role eq 'server'
                ? Linux::Event::TLS->_server_from_declaration($tls)
                : Linux::Event::TLS->_client_from_declaration($tls);
        }
        # Accepted sockets acquire TLS only from the Listener recipe.
        # A class declaration/default never activates TLS by itself.
    } elsif (defined $tls_role) {
        croak 'new(): tls_role requires a Socket subclass declaring TLS';
    }
    my $self = $class->SUPER::new(fh => $fh, _transport => $transport, %opt);
    $self->{socket_descriptor} = $socket_descriptor;
    $self->{socket_policy} = $policy;
    $self->{local} = $local;
    $self->{peer} = $resolved_peer;
    my $configured = eval {
        $self->_configure_socket(
            $fh, $accepted ? 'accepted' : 'adopted', $resolved_peer,
        );
        $self->_attach_to_loop($loop) if $loop;
        1;
    };
    if (!$configured) {
        my $failure = $@;
        eval { $self->close; 1 };
        die $failure;
    }
    return $self;
}

sub connect ($class, %opt) {
    croak 'connect(): must be called as a class method' if ref $class;
    my %stream;
    for my $name (qw(loop data transport idle_timeout read_timeout write_timeout deadline),
        Linux::Event::_ByteStream::_callback_names()) {
        $stream{$name} = delete $opt{$name} if exists $opt{$name};
    }
    my $loop = delete $stream{loop};
    croak 'connect(): loop must be an object implementing add() and watch_fd()'
        if defined($loop) && (!ref($loop) || !$loop->can('add')
            || !$loop->can('watch_fd'));
    my $override = Linux::Event::_SocketConfig::extract('connect', \%opt);
    my $socket_descriptor = Linux::Event::_Socket::Descriptor::for_class($class);
    my %policy = map {
        $_ => exists($override->{$_}) ? $override->{$_}
            : $socket_descriptor->{options}{$_}
    } Linux::Event::_SocketConfig::names();
    my $transport = delete $stream{transport};
    croak 'connect(): transport must be an object implementing _stream_transport_bind()'
        if defined($transport)
        && (!blessed($transport) || !$transport->can('_stream_transport_bind'));
    if (my $tls = $socket_descriptor->{tls}) {
        croak 'connect(): transport cannot be supplied for a TLS-declared Socket'
            if defined $transport;
        require Linux::Event::TLS;
        $transport = Linux::Event::TLS->_client_from_declaration(
            $tls, $opt{host},
        );
    }
    my $self = $class->SUPER::new(
        %stream, _pending => 1, _transport => $transport,
    );
    $self->{socket_descriptor} = $socket_descriptor;
    $self->{socket_policy} = \%policy;
    $self->{preconnect_output} = [];
    $self->{preconnect_bytes} = 0;
    $self->{read_capable} = 1;
    $self->{write_capable} = 1;
    $self->{write_ended} = 0;
    $self->{read_closed} = 0;
    $self->{connection} = Linux::Event::_Socket::Connection->new(
        %opt, stream => $self, socket_policy => \%policy,
    );
    $self->_attach_to_loop($loop) if $loop;
    return $self;
}

sub CLONE ($class) {
    Linux::Event::_Socket::Descriptor::clear_cache();
    return;
}

sub CLONE_SKIP ($class) { 1 }

# Accessors

sub local ($self) { $self->{local} }
sub peer ($self) { $self->{peer} }
sub fd ($self) { $self->read_fd }

sub tcp_nodelay ($self, @arg) {
    $self->_socket_option('tcp_nodelay', @arg);
}

sub keepalive ($self, @arg) {
    $self->_socket_option('keepalive', @arg);
}

sub keepalive_idle ($self, @arg) {
    $self->_socket_option('keepalive_idle', @arg);
}

sub keepalive_interval ($self, @arg) {
    $self->_socket_option('keepalive_interval', @arg);
}

sub keepalive_count ($self, @arg) {
    $self->_socket_option('keepalive_count', @arg);
}

sub tcp_user_timeout ($self, @arg) {
    $self->_socket_option('tcp_user_timeout', @arg);
}

sub send_buffer ($self, @arg) {
    $self->_socket_option('send_buffer', @arg);
}

sub receive_buffer ($self, @arg) {
    $self->_socket_option('receive_buffer', @arg);
}

sub selected_alpn ($self) {
    my $transport = $self->{transport};
    return $transport && $transport->can('selected_alpn')
        ? $transport->selected_alpn : undef;
}

sub tls_protocol ($self) {
    my $transport = $self->{transport};
    return $transport && $transport->can('protocol')
        ? $transport->protocol : undef;
}

sub tls_cipher ($self) {
    my $transport = $self->{transport};
    return $transport && $transport->can('cipher')
        ? $transport->cipher : undef;
}

sub tls_stats ($self) {
    my $transport = $self->{transport};
    return $transport && $transport->can('stats')
        ? $transport->stats : undef;
}

# Methods

sub close_read ($self) {
    return $self if $self->{closed} || $self->{read_closed} || $self->{read_eof};
    croak 'close_read(): directional close is unavailable for TLS sockets'
        if ($self->transport_name // 'plain') ne 'plain';
    shutdown($self->fh, SHUT_RD) or do {
        my $errno = 0 + $!;
        $self->_fail_io('shutdown_read', $errno);
        return $self;
    };
    return $self->SUPER::close_read;
}

sub close_write ($self) {
    return $self if $self->{closed} || $self->{write_ended};
    croak 'close_write(): use end() for TLS sockets'
        if ($self->transport_name // 'plain') ne 'plain';
    shutdown($self->fh, SHUT_WR) or do {
        my $errno = 0 + $!;
        $self->_fail_io('shutdown_write', $errno);
        return $self;
    };
    return $self->SUPER::close_write;
}

sub detach ($self) {
    my $handles = $self->SUPER::detach;
    return $handles->{read_fh};
}

# Private helpers and internal overrides

sub _declare_tls ($base, $target, $definition) {
    Linux::Event::_Socket::Descriptor::declare_tls($base, $target, $definition);
}

sub _socket_type ($fh) {
    my $packed = getsockopt($fh, SOL_SOCKET, SO_TYPE);
    croak 'new(): fh is not a socket' if !defined($packed) || length($packed) < 4;
    croak 'new(): fh is not a SOCK_STREAM socket'
        if unpack('i', $packed) != SOCK_STREAM;
    return;
}

sub _socket_setup ($fh, $descriptor, $override, $peer) {
    _socket_type($fh);
    my $packed_local = getsockname($fh);
    croak 'new(): could not obtain local socket address'
        if !defined $packed_local;
    my $local = Linux::Event::Address->new($packed_local);
    my %policy = map {
        $_ => exists($override->{$_})
            ? $override->{$_} : $descriptor->{options}{$_}
    } Linux::Event::_SocketConfig::names();
    Linux::Event::_SocketConfig::apply_policy(
        $fh, $local->family_number, \%policy,
    );
    if (!defined $peer) {
        my $packed_peer = getpeername($fh);
        $peer = Linux::Event::Address->new($packed_peer)
            if defined $packed_peer;
    }
    croak 'new(): fh is not a connected SOCK_STREAM socket' if !defined $peer;
    return ($local, $peer, \%policy);
}

sub _validate_accepted_configuration ($class) {
    my $descriptor = Linux::Event::_Socket::Descriptor::for_class($class);
    if (my $tls = $descriptor->{tls}) {
        require Linux::Event::TLS;
        Linux::Event::TLS->_server_from_declaration($tls);
    }
    return;
}

sub _configure_socket ($self, $fh, $role, $address) {
    my $callback = $self->{socket_descriptor}{configure_socket} or return;
    my $ok = eval { $callback->($self, $fh, $role, $address); 1 };
    return if $ok;
    my $message = "$@";
    $message =~ s/\s+\z//;
    die Linux::Event::Error->new(
        type => 'socket_configuration', operation => 'configure_socket',
        message => $message || 'configure_socket callback failed',
    );
}

sub _attach_pending ($self, $loop) {
    $self->{connection}->_attach_to_loop($loop);
    return;
}

sub _cancel_pending ($self) {
    if (my $connection = delete $self->{connection}) { $connection->cancel }
    return;
}

sub _connect_succeeded ($self, $fh) {
    return if $self->{closed};
    delete $self->{connection};
    my $packed_local = getsockname($fh);
    $self->{local} = Linux::Event::Address->new($packed_local);
    my $packed_peer = getpeername($fh);
    $self->{peer} = Linux::Event::Address->new($packed_peer)
        if defined $packed_peer;
    $self->{read_fh} = $fh;
    $self->{write_fh} = $fh;
    my $prepared = eval { $self->_prepare_handles; $self->_register_handles; 1 };
    if (!$prepared) {
        $self->_fail(Linux::Event::Error->new(
            type => 'connect', operation => 'attach', message => $@,
        ));
        return;
    }
    my $transport = $self->{transport};
    if ($transport && $transport->can('_stream_transport_start')) {
        my $started = eval { $transport->_stream_transport_start($self); 1 };
        if (!$started) {
            $self->_fail(Linux::Event::Error->new(
                type => 'transport', operation => 'start', message => $@,
            ));
            return;
        }
    }
    $self->_flush_preconnect_output;
    if (!$transport) {
        $self->_start_stream_deadlines;
        $self->_fire_ready;
    }
    return;
}

sub _connect_failed ($self, $error) {
    return if $self->{closed};
    delete $self->{connection};
    $self->_fail($error);
}

sub _on_read_terminal_ready ($self) {
    return if $self->{closed};
    my $packed = getsockopt($self->fh, SOL_SOCKET, SO_ERROR);
    if (defined($packed) && length($packed) >= 4) {
        my $errno = unpack('i', $packed);
        if ($errno) { $self->_fail_io('socket', $errno); return }
    }
    $self->SUPER::_on_read_terminal_ready;
}

sub _finish_transport_write ($self) {
    if (!$self->{transport_shutdown_started}++ && $self->{transport}
        && $self->{transport}->can('_stream_transport_begin_shutdown')) {
        my $ok = eval {
            $self->{transport}->_stream_transport_begin_shutdown($self); 1;
        };
        if (!$ok) {
            $self->_fail(Linux::Event::Error->new(
                type => $self->transport_name, operation => 'shutdown',
                message => $@ || 'transport shutdown setup failed',
            ));
            return 0;
        }
    }
    my ($status, $errno, $message) = $self->{xs_state}->_shutdown_write;
    if ($status == 2) { $self->{read_watcher}->enable_read; return 0 }
    if ($status == 3) { $self->{write_watcher}->enable_write; return 0 }
    if ($status == 5) {
        if (($self->transport_name // 'plain') ne 'plain') {
            $self->_fail(Linux::Event::Error->new(
                type => $self->transport_name, operation => 'shutdown',
                message => $message || 'transport shutdown failed',
            ));
        } else {
            $self->_fail_io('shutdown', $errno);
        }
        return 0;
    }
    return 1;
}

sub _socket_option ($self, $name, @argument) {
    croak "$name(): Socket is not established" if $self->{closed} || !$self->fh;
    croak "$name(): expected zero or one argument" if @argument > 1;
    my $family = $self->{local}->family_number;
    Linux::Event::_SocketConfig::set_option(
        $self->fh, $family, $name, $argument[0],
    ) if @argument;
    return Linux::Event::_SocketConfig::get_option($self->fh, $family, $name);
}

1;
