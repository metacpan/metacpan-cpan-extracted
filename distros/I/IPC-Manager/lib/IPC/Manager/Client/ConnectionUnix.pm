package IPC::Manager::Client::ConnectionUnix;
use strict;
use warnings;

our $VERSION = '0.000035';

use Carp qw/croak/;
use Errno qw/EAGAIN EWOULDBLOCK EINTR/;
use Fcntl qw/O_WRONLY O_CREAT O_EXCL/;
use Time::HiRes qw/time/;
use IO::Socket::UNIX 1.55 qw/SOCK_STREAM SOMAXCONN/;
use IO::Select;

use IPC::Manager::Util qw/USE_IO_SELECT/;

use parent 'IPC::Manager::Base::FS';
use Role::Tiny::With;
with 'IPC::Manager::Role::Client::Connection';
with 'IPC::Manager::Role::Outbox';

use Object::HashBase qw{
    listen
    +listen_socket
    +connections
    +backlog
};

# sun_path budget — same constraint as Client::UnixSocket.
use constant _SUN_PATH_LIMIT => 104;

sub _viable { require IO::Socket::UNIX; IO::Socket::UNIX->VERSION('1.55'); 1 }

sub suspend_supported { 0 }
sub suspend           { croak "suspend is not supported by the ConnectionUnix driver" }

sub check_path { -S $_[1] || -f $_[1] }
sub path_type  { 'UNIX Socket or marker file' }

sub max_on_disk_name_length {
    my $self = shift;
    return _SUN_PATH_LIMIT - length($self->{+ROUTE}) - 2; # '/' + NUL
}

sub have_handles_for_select         { 1 }
sub have_dynamic_handles_for_select { 1 }

sub handles_for_select {
    my $self = shift;
    my @h;
    push @h => $self->{+LISTEN_SOCKET} if $self->{+LISTEN_SOCKET};
    for my $entry (values %{$self->{+CONNECTIONS} // {}}) {
        push @h => $entry->{fh} if $entry->{fh};
    }
    return @h;
}

sub init {
    my $self = shift;

    $self->{+LISTEN}      //= 1;
    $self->{+CONNECTIONS} //= {};
    $self->{+BACKLOG}     //= SOMAXCONN;

    $self->SUPER::init();
}

sub make_path {
    my $self = shift;
    my $path = $self->path;

    if ($self->{+LISTEN}) {
        my $s = IO::Socket::UNIX->new(
            Type     => SOCK_STREAM,
            Local    => $path,
            Listen   => $self->{+BACKLOG},
            Blocking => 0,
        ) or die "Cannot create listen socket '$path': $!";
        $self->{+LISTEN_SOCKET} = $s;
    }
    else {
        # Drop a regular empty file as a presence marker.  Use sysopen with
        # O_EXCL so we never silently clobber an existing socket file.
        sysopen(my $fh, $path, O_WRONLY | O_CREAT | O_EXCL, 0600)
            or die "Cannot create marker file '$path': $!";
        close($fh);
    }
}

sub pre_disconnect_hook {
    my $self = shift;
    # Unlink the on-disk entry so no new peer can connect to us, but keep
    # the listen socket fd and existing connection fds open: the base
    # disconnect loop runs after this and still needs them to drain any
    # pending inbound messages.
    return unless defined $self->{+PATH};
    return unless -e $self->{+PATH};
    unlink($self->{+PATH}) or warn "Could not unlink '$self->{+PATH}': $!";
}

sub post_disconnect_hook {
    my $self = shift;

    # Now safe to tear down sockets — base disconnect has already drained
    # whatever messages it was going to drain.
    for my $peer (keys %{$self->{+CONNECTIONS} // {}}) {
        $self->_close_connection($peer);
    }

    if (my $s = delete $self->{+LISTEN_SOCKET}) {
        eval { $s->close };
    }

    $self->SUPER::post_disconnect_hook;
}

sub peer_is_listener {
    my $self = shift;
    my ($peer) = @_;
    my $path = $self->peer_exists($peer) or return 0;
    return -S $path ? 1 : 0;
}

sub listening_peers {
    my $self = shift;
    return grep { $self->peer_is_listener($_) } $self->peers;
}

# --- Role::Client::Connection requirements ---

sub _connections { $_[0]->{+CONNECTIONS} }

sub _close_connection {
    my $self = shift;
    my ($peer) = @_;

    my $entry = delete $self->{+CONNECTIONS}->{$peer} or return;
    if (my $fh = $entry->{fh}) {
        eval { $fh->close };
    }
    return;
}

# --- Wire framing ---
#
# Each frame: 4-byte big-endian length + JSON payload.
#
# After connecting outbound, the initiator immediately sends a hello frame:
#   {"hello": "<my id>"}
# so the acceptor can key the cached connection by remote peer id.

sub _send_frame {
    my ($self, $fh, $payload) = @_;

    # Frame on the wire: 4-byte big-endian length prefix, then payload bytes.
    my $bytes = pack('N', length $payload) . $payload;
    my $total = length $bytes;
    my $off   = 0;

    # Sockets are non-blocking, but we need to deliver the whole frame before
    # returning, so loop until every byte is written.  Partial writes advance
    # $off; EAGAIN/EWOULDBLOCK means the kernel buffer is full so we wait
    # briefly with select() for it to drain.  EINTR retries; anything else is
    # a real I/O error and we propagate it to the caller.
    while ($off < $total) {
        my $n;
        {
            no warnings 'closed', 'unopened';
            $n = syswrite($fh, $bytes, $total - $off, $off);
        }
        if (defined $n) {
            $off += $n;
            next;
        }
        if ($! == EAGAIN || $! == EWOULDBLOCK) {
            my $w = '';
            vec($w, fileno($fh), 1) = 1;
            select(undef, $w, undef, 0.5);
            next;
        }
        next if $! == EINTR;
        die "write failed: $!";
    }
}

# Non-blocking: drain as much of $entry->{send_buffer} as the kernel will
# accept right now, then return.  Stops on EAGAIN/EWOULDBLOCK without
# blocking; retries on EINTR; raises on any other error.
sub _flush_send_buffer {
    my ($self, $entry) = @_;
    my $fh = $entry->{fh} or return 0;

    while (length $entry->{send_buffer}) {
        my $n;
        {
            no warnings 'closed', 'unopened';
            $n = syswrite($fh, $entry->{send_buffer});
        }
        if (defined $n) {
            substr($entry->{send_buffer}, 0, $n) = '';
            next;
        }
        last if $! == EAGAIN || $! == EWOULDBLOCK;
        next if $! == EINTR;
        die "write failed: $!";
    }

    return length($entry->{send_buffer}) ? 0 : 1;
}

sub _drain_reads {
    my ($self, $fh, $buf_ref) = @_;

    # During global destruction perl may have already destroyed the
    # IO::Socket::UNIX in $entry->{fh} before our Client's DESTROY runs
    # disconnect.  Treat a missing handle as already-closed.
    return 1 unless defined $fh;

    # Pull everything currently readable on $fh into the caller's buffer
    # without blocking, and report whether the peer has closed.  Caller is
    # responsible for slicing complete frames out of the buffer afterwards
    # via _extract_frames.
    my $eof = 0;
    while (1) {
        my $chunk;
        my $n = sysread($fh, $chunk, 65536);
        if (defined $n) {
            # 0 bytes = peer closed cleanly; otherwise append and keep reading.
            if ($n == 0) {
                $eof = 1;
                last;
            }
            $$buf_ref .= $chunk;
            next;
        }
        # No more data right now — done draining, not an error.
        last if $! == EAGAIN || $! == EWOULDBLOCK;
        next if $! == EINTR;
        # Treat other read errors as EOF: connection is broken.
        $eof = 1;
        last;
    }

    return $eof;
}

sub _extract_frames {
    my ($self, $buf_ref) = @_;

    # Slice as many complete frames as are present out of the caller's read
    # buffer, leaving any partial trailing frame in place for the next call.
    # Each frame is `pack('N', $len) . $payload`; we peek at the length
    # prefix, bail if the full payload has not arrived yet, and otherwise
    # consume the prefix+payload from the buffer.
    my @out;
    while (length($$buf_ref) >= 4) {
        my $len = unpack('N', substr($$buf_ref, 0, 4));
        last if length($$buf_ref) < 4 + $len;
        my $payload = substr($$buf_ref, 4, $len);
        substr($$buf_ref, 0, 4 + $len) = '';
        push @out => $payload;
    }
    return @out;
}

sub _connect_to_peer {
    my $self = shift;
    my ($peer_id) = @_;

    my $sock = $self->peer_exists($peer_id);
    die "'$peer_id' is not a valid message recipient" unless $sock;
    die "'$peer_id' is not listening" unless -S $sock;

    my $s = IO::Socket::UNIX->new(
        Type => SOCK_STREAM,
        Peer => $sock,
    ) or die "Cannot connect to '$sock': $!";

    $s->blocking(0);

    my $entry = {
        fh           => $s,
        last_active  => time,
        role         => 'initiator',
        read_buffer  => '',
        send_buffer  => '',
        sent_hello   => 0,
        recv_hello   => 1,    # we initiated; we know who they are by definition
    };

    # Send hello frame first.
    my $hello = $self->{+SERIALIZER}->serialize({hello => $self->{+ID}});
    $self->_send_frame($s, $hello);
    $entry->{sent_hello} = 1;

    $self->{+CONNECTIONS}->{$peer_id} = $entry;
    return $entry;
}

sub _accept_pending {
    my $self = shift;

    my $ls = $self->{+LISTEN_SOCKET} or return;

    while (my $client = $ls->accept) {
        $client->blocking(0);

        # Park under a temporary key until we read the hello frame.  We use a
        # special hash slot keyed by stringified handle so the new connection
        # is included in select handles immediately.
        my $tmp_key = "_pending_" . fileno($client);
        $self->{+CONNECTIONS}->{$tmp_key} = {
            fh           => $client,
            last_active  => time,
            role         => 'listener',
            read_buffer  => '',
            send_buffer  => '',
            sent_hello   => 0,
            recv_hello   => 0,
            _pending_key => $tmp_key,
        };
    }
}

sub _resolve_pending {
    my $self = shift;

    my $cons = $self->{+CONNECTIONS};
    for my $key (keys %$cons) {
        next unless $key =~ /^_pending_/;
        my $entry = $cons->{$key};

        my $eof = $self->_drain_reads($entry->{fh}, \$entry->{read_buffer});
        my @frames = $self->_extract_frames(\$entry->{read_buffer});

        if (@frames) {
            my $hello_raw = shift @frames;
            my $hello;
            my $hello_ok = eval { $hello = $self->{+SERIALIZER}->deserialize($hello_raw); 1 };
            unless ($hello_ok) {
                # Malformed hello — drop the connection.
                warn "ConnectionUnix: malformed hello frame: $@";
                eval { $entry->{fh}->close };
                delete $cons->{$key};
                next;
            }

            my $peer_id = ref($hello) eq 'HASH' ? $hello->{hello} : undef;
            unless (defined $peer_id && length $peer_id) {
                warn "ConnectionUnix: hello frame missing peer id";
                eval { $entry->{fh}->close };
                delete $cons->{$key};
                next;
            }

            # If we already have a connection to this peer it is necessarily
            # stale: the remote side dropped the previous fd and reconnected.
            # Drain anything still buffered on the old entry, then close it,
            # so the new connection becomes the live one.
            if (my $old = delete $cons->{$peer_id}) {
                if (my $lf = delete $old->{leftover_frames}) {
                    $entry->{leftover_frames} ||= [];
                    unshift @{$entry->{leftover_frames}}, @$lf;
                }
                $self->_drain_reads($old->{fh}, \$old->{read_buffer});
                my @stale = $self->_extract_frames(\$old->{read_buffer});
                if (@stale) {
                    $entry->{leftover_frames} ||= [];
                    unshift @{$entry->{leftover_frames}}, @stale;
                }
                eval { $old->{fh}->close };
            }

            $entry->{recv_hello} = 1;
            $entry->{last_active} = time;
            # Move to its real key.
            delete $entry->{_pending_key};
            $cons->{$peer_id} = $entry;
            delete $cons->{$key};

            # Any frames after hello are real messages — push them back into
            # the buffer so the normal reader picks them up.  Easier: stash
            # leftover frames on the entry and let _read_messages pull them.
            if (@frames) {
                $entry->{leftover_frames} ||= [];
                push @{$entry->{leftover_frames}} => @frames;
            }
        }
        elsif ($eof) {
            eval { $entry->{fh}->close };
            delete $cons->{$key};
        }
    }
}

sub _read_messages {
    my $self = shift;

    my @msgs;

    my $cons = $self->{+CONNECTIONS};
    for my $peer (keys %$cons) {
        next if $peer =~ /^_pending_/;
        my $entry = $cons->{$peer};

        # Pop any leftover frames captured during hello resolution first.
        if (my $lf = delete $entry->{leftover_frames}) {
            for my $raw (@$lf) {
                my $msg = $self->_decode_message($raw, $entry, $peer) or next;
                push @msgs => $msg;
            }
        }

        my $eof = $self->_drain_reads($entry->{fh}, \$entry->{read_buffer});
        my @frames = $self->_extract_frames(\$entry->{read_buffer});

        for my $raw (@frames) {
            my $msg = $self->_decode_message($raw, $entry, $peer) or next;
            push @msgs => $msg;
        }

        if (@frames) {
            $entry->{last_active} = time;
        }

        if ($eof && length($entry->{read_buffer}) == 0) {
            $self->_close_connection($peer);
        }
    }

    return @msgs;
}

sub _decode_message {
    my ($self, $raw, $entry, $peer) = @_;
    my $data;
    unless (eval { $data = $self->{+SERIALIZER}->deserialize($raw); 1 }) {
        warn "ConnectionUnix: malformed frame from '$peer': $@";
        return undef;
    }
    return undef unless ref($data) eq 'HASH';
    # Tolerate a stray hello (shouldn't happen on an already-resolved entry).
    return undef if exists $data->{hello} && keys(%$data) == 1;

    my $msg = IPC::Manager::Message->new($data);
    $self->{+STATS}->{read}->{$msg->{from}}++;
    return $msg;
}

# --- Public API ---

sub pending_messages {
    my $self = shift;
    $self->pid_check;

    return 1 if $self->have_resume_file;

    # Any buffered frames already?
    my $cons = $self->{+CONNECTIONS};
    for my $entry (values %$cons) {
        return 1 if $entry->{leftover_frames} && @{$entry->{leftover_frames}};
        return 1 if length($entry->{read_buffer} // '') >= 4
            && length($entry->{read_buffer}) >= 4 + unpack('N', substr($entry->{read_buffer}, 0, 4));
    }

    if (USE_IO_SELECT()) {
        my @h = $self->handles_for_select;
        return 0 unless @h;
        my $sel = IO::Select->new(@h);
        return $sel->can_read(0) ? 1 : 0;
    }

    return 0;
}

sub ready_messages {
    my $self = shift;
    $self->pid_check;

    return 1 if $self->have_resume_file;
    return 1 if $self->pending_messages;

    return 0;
}

sub get_messages {
    my $self = shift;

    my @out;
    push @out => $self->read_resume_file;

    $self->_accept_pending;
    $self->_resolve_pending;

    push @out => $self->_read_messages;

    return $self->sort_messages(@out);
}

sub send_message {
    my $self = shift;
    my $msg  = $self->build_message(@_);

    my $peer_id = $msg->to or croak "No peer specified";

    $self->pid_check;

    my $payload = $self->{+SERIALIZER}->serialize($msg);

    # Inside a service the client has set_send_blocking(0) and the
    # service event loop drains queued frames when the connection
    # becomes writable.  Outside a service we still block until the
    # bytes are committed so short-lived caller code keeps the
    # synchronous semantics it has always had.
    return $self->try_send_message($peer_id, $payload)
        unless $self->send_blocking;

    my $entry = $self->{+CONNECTIONS}->{$peer_id};

    if (!$entry) {
        # No cached connection — must be able to connect.  peer_exists will
        # be undef for unknown peers; peer_is_listener gates non-listeners.
        die "'$peer_id' is not a valid message recipient" unless $self->peer_exists($peer_id);
        die "no active connection to '$peer_id' and peer is not listening"
            unless $self->peer_is_listener($peer_id);

        $entry = $self->_connect_to_peer($peer_id);
    }

    # Drain any leftover non-blocking partial frame for this peer first,
    # otherwise our new frame would interleave with it on the wire.
    $self->_flush_send_buffer($entry) if length $entry->{send_buffer};

    # Send the frame.  No auto-reconnect: SOCK_STREAM peer churn is the
    # caller's problem, just like with sockets generally.  Auto-retrying
    # would also silently lose any queued bytes already in send_buffer
    # that were flushed (or partially flushed) before the EPIPE.
    my $ok = eval { $self->_send_frame($entry->{fh}, $payload); 1 };
    unless ($ok) {
        my $err = $@;
        # Defensive eval: _close_connection only evals close() today, but
        # future hooks could throw and would mask the real send error.
        eval { $self->_close_connection($peer_id); 1 }
            or warn "ConnectionUnix: error closing connection to '$peer_id' after send failure: $@";
        die $err;
    }
    $entry->{last_active} = time;

    $self->{+STATS}->{sent}->{$msg->{to}}++;
    return 1;
}

# --- Role::Outbox plumbing ---
#
# Connection-oriented framing means a partial write of a frame must NOT be
# re-sent from the start: the peer would see a corrupt mix of trailing bytes
# from the old attempt and length prefix from the new.  So instead of using
# the role's whole-payload queue we maintain a per-connection
# $entry->{send_buffer} of raw outbound bytes.  _outbox_try_write always
# accepts the new frame (returns 1), appending to send_buffer if necessary,
# and the role's queue stays empty.  The framework calls drain_pending /
# writable_handles which we override to walk send_buffers instead.

sub _outbox_try_write {
    my ($self, $peer, $payload) = @_;

    $self->pid_check;

    my $entry = $self->{+CONNECTIONS}->{$peer};
    if (!$entry) {
        die "'$peer' is not a valid message recipient" unless $self->peer_exists($peer);
        die "no active connection to '$peer' and peer is not listening"
            unless $self->peer_is_listener($peer);
        $entry = $self->_connect_to_peer($peer);
    }

    my $frame = pack('N', length $payload) . $payload;
    $entry->{send_buffer} .= $frame;

    my $flushed_ok = eval { $self->_flush_send_buffer($entry); 1 };
    unless ($flushed_ok) {
        my $err = $@;
        # Hard write error (e.g. EPIPE).  Drop the connection and lose the
        # in-flight bytes; future sends to this peer reconnect.
        warn "ConnectionUnix: send to '$peer' failed: $err";
        eval { $self->_close_connection($peer); 1 }
            or warn "ConnectionUnix: error closing connection to '$peer' after send failure: $@";
        return 1;
    }

    $entry->{last_active} = time;
    $self->{+STATS}->{sent}->{$peer}++;
    return 1;
}

sub _outbox_writable_handle {
    my ($self, $peer) = @_;
    my $entry = $self->{+CONNECTIONS}->{$peer} or return undef;
    return $entry->{fh};
}

sub _outbox_set_blocking {
    # Sockets stay non-blocking either way (reads need it).  send_message
    # branches on send_blocking() to choose the synchronous _send_frame
    # loop or the deferred-via-send_buffer path.
    return;
}

sub _outbox_can_send {
    my ($self, $peer) = @_;
    my $entry = $self->{+CONNECTIONS}->{$peer} or return 0;
    return length($entry->{send_buffer}) ? 0 : 1;
}

# Override the role's queue-based bookkeeping: our partial frames live in
# per-connection send_buffers, not in the role's _OUTBOX hash, so the role
# would otherwise always report "nothing pending" and the service loop
# would never pick our writable handles.

sub pending_sends {
    my $self = shift;
    my $n = 0;
    for my $key (keys %{$self->{+CONNECTIONS} // {}}) {
        next if $key =~ /^_pending_/;
        my $entry = $self->{+CONNECTIONS}->{$key};
        $n++ if length($entry->{send_buffer} // '');
    }
    return $n;
}

sub have_pending_sends {
    my $self = shift;
    for my $key (keys %{$self->{+CONNECTIONS} // {}}) {
        next if $key =~ /^_pending_/;
        return 1 if length($self->{+CONNECTIONS}->{$key}->{send_buffer} // '');
    }
    return 0;
}

sub pending_sends_to {
    my ($self, $peer) = @_;
    my $entry = $self->{+CONNECTIONS}->{$peer} or return 0;
    return length($entry->{send_buffer} // '') ? 1 : 0;
}

sub drain_pending {
    my $self = shift;

    my $delivered = 0;
    for my $key (keys %{$self->{+CONNECTIONS} // {}}) {
        next if $key =~ /^_pending_/;
        my $entry = $self->{+CONNECTIONS}->{$key};
        next unless length($entry->{send_buffer} // '');

        my $ok = eval { $self->_flush_send_buffer($entry); 1 };
        unless ($ok) {
            my $err = $@;
            warn "ConnectionUnix: send to '$key' failed during drain: $err";
            eval { $self->_close_connection($key); 1 }
                or warn "ConnectionUnix: error closing connection to '$key' after drain failure: $@";
            next;
        }

        if (!length($entry->{send_buffer})) {
            $entry->{last_active} = time;
            $delivered++;
        }
    }

    return $delivered;
}

sub have_writable_handles {
    my $self = shift;
    for my $key (keys %{$self->{+CONNECTIONS} // {}}) {
        next if $key =~ /^_pending_/;
        return 1 if length($self->{+CONNECTIONS}->{$key}->{send_buffer} // '');
    }
    return 0;
}

sub writable_handles {
    my $self = shift;
    my @h;
    for my $key (keys %{$self->{+CONNECTIONS} // {}}) {
        next if $key =~ /^_pending_/;
        my $entry = $self->{+CONNECTIONS}->{$key};
        next unless length($entry->{send_buffer} // '');
        push @h => $entry->{fh} if $entry->{fh};
    }
    return @h;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Client::ConnectionUnix - Connection-oriented UNIX socket IPC client.

=head1 DESCRIPTION

A connection-oriented IPC client built on C<SOCK_STREAM> UNIX sockets.

Unlike L<IPC::Manager::Client::UnixSocket> (which uses C<SOCK_DGRAM> and is
effectively connectionless), each C<ConnectionUnix> client either listens for
incoming connections or does not, and messages flow over established
per-peer connections.

A client may be created with C<< listen => 0 >> to indicate it does not accept
incoming connections; in that case it can only receive messages back over
connections that it has itself initiated.  Listening clients (the default)
expose a UNIX socket that any other client can connect to.

Messages may be sent only to peers that are listening, or to peers with whom
this client already has an active connection.  Attempts to send to a
non-listener with no cached connection throw an exception.

=head1 SYNOPSIS

    use IPC::Manager qw/ipcm_spawn ipcm_connect/;

    my $spawn = ipcm_spawn(protocol => 'ConnectionUnix');

    my $listener = $spawn->connect('listener');                  # listen => 1 default
    my $caller   = ipcm_connect('caller', $spawn->info, listen => 0);

    $caller->send_message(listener => {hello => 'there'});

    my @msgs = $listener->get_messages;

    # listener can reply over the same connection caller opened
    $listener->send_message(caller => {hi => 'back'});

    my @reply = $caller->get_messages;

=head1 CONSTRUCTOR PARAMETERS

=over 4

=item listen => 0|1

Whether this client accepts incoming connections.  Defaults to 1.  When 0,
the client only writes a marker file under the route directory rather than a
listen socket.

=item backlog => $n

Listen backlog for C<SOCK_STREAM>; defaults to C<SOMAXCONN>.

=back

=head1 NOTES

Suspend is not usable in this protocol.

=head1 METHODS

See L<IPC::Manager::Client> and L<IPC::Manager::Base::FS> for inherited
methods.  Per-connection management methods (C<has_connection>,
C<disconnect_connection>, C<close_idle_connections>, C<connections>,
C<last_activity>) are provided by L<IPC::Manager::Role::Client::Connection>.

=over 4

=item $bool = $con->peer_is_listener($peer_id)

True iff the peer's on-disk path exists and is a UNIX socket (as opposed to a
non-listener marker file).

=item @peers = $con->listening_peers

Subset of C<< $con->peers >> for which C<peer_is_listener> is true.

=back

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://github.com/exodist/IPC-Manager>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
