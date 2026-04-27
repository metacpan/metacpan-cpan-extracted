package IPC::Manager::Client::AtomicPipe;
use strict;
use warnings;

our $VERSION = '0.000035';

use File::Spec;
use Atomic::Pipe;
use Carp qw/croak/;
use POSIX qw/mkfifo/;

use parent 'IPC::Manager::Base::FS::Handle';
use Object::HashBase qw{
    permissions
    +pipe
    +pipe_cache
};

use Role::Tiny::With;
with 'IPC::Manager::Role::Outbox';

sub _viable           { require Atomic::Pipe; Atomic::Pipe->VERSION('0.026'); 1 }
sub suspend_supported { 0 }

sub check_path { -p $_[1] }
sub path_type  { 'FIFO' }

sub have_handles_for_select { 1 }
sub handles_for_select { $_[0]->{+PIPE} ? $_[0]->{+PIPE}->rh : () }

sub make_path {
    my $self  = shift;
    my $path  = $self->path;
    my $perms = $self->{+PERMISSIONS} //= 0700;
    mkfifo($path, $perms) or die "Failed to make fifo '$path': $!";
    my $p = Atomic::Pipe->read_fifo($path);
    $p->blocking(0);
    $p->resize_or_max($p->max_size) if $p->max_size;

    $self->{+PIPE} = $p;
}

sub pre_disconnect_hook {
    my $self = shift;
    unlink($self->{+PATH}) or warn "Could not unlink fifo: $!";
}

sub init {
    my $self = shift;

    $self->SUPER::init();

    $self->{+BUFFER} //= [];
}

sub pre_suspend_hook {
    my $self = shift;

    $self->pid_check;

    # Get all messages and re-queue them
    my $p = $self->{+PIPE};

    my @msgs;
    while ($p->{$p->IN_BUFFER_SIZE}) {
        push @msgs => $p->read_message;
    }

    if (@msgs) {
        $self->requeue_message(@msgs);
    }

    $self->SUPER::pre_suspend_hook(@_);
}

sub fill_buffer {
    my $self = shift;
    my $msg = $self->{+PIPE}->read_message // return @{$self->{+BUFFER}} ? 1 : 0;
    push @{$self->{+BUFFER}} => $msg;
    return 1;
}

sub _process_msg {
    my $self = shift;
    my ($in) = @_;

    my $msg = IPC::Manager::Message->new($self->{+SERIALIZER}->deserialize($in));
    $self->{+STATS}->{read}->{$msg->{from}}++;
    return $msg;
}

sub get_messages {
    my $self = shift;

    my $p = $self->{+PIPE};

    my @out;

    push @out => $self->read_resume_file;

    push @out => map { $self->_process_msg($_) } @{$self->{+BUFFER}};

    while (my $msg = $p->read_message) {
        push @out => $self->_process_msg($msg);
    }

    @{$self->{+BUFFER}} = ();

    return $self->sort_messages(@out);
}

sub peer_left {
    my $self = shift;

    my $p = $self->{+PIPE} or return 0;
    my $state = $p->{Atomic::Pipe::STATE()} or return 0;

    my %tags;
    $tags{$_} = 1 for keys %{$state->{parts}   // {}};
    $tags{$_} = 1 for keys %{$state->{buffers} // {}};

    my $removed = 0;
    for my $tag (keys %tags) {
        my ($pid) = split /:/, $tag, 2;
        next unless $pid && $pid =~ m/^-?\d+$/;

        # pid_is_running returns 1 (ours), -1 (running but not ours), or 0
        # (gone).  Only clear the tag when the pid is genuinely gone.
        next if $self->pid_is_running($pid);

        delete $state->{parts}->{$tag};
        delete $state->{buffers}->{$tag};
        $removed++;
    }

    return $removed;
}

sub _peer_pipe {
    my ($self, $peer) = @_;

    my $fifo = $self->peer_exists($peer) or return undef;
    return $self->{+PIPE_CACHE}->{$fifo} //= do {
        my $w = Atomic::Pipe->write_fifo($fifo);
        $w->write_blocking($self->send_blocking ? 1 : 0);
        $w;
    };
}

sub _outbox_set_blocking {
    my ($self, $bool) = @_;
    for my $p (values %{$self->{+PIPE_CACHE} // {}}) {
        $p->write_blocking($bool ? 1 : 0);
    }
}

sub _outbox_can_send {
    my ($self, $peer) = @_;

    my $p = $self->_peer_pipe($peer) or return 0;

    require IO::Select;
    my $s = IO::Select->new($p->wh);
    return $s->can_write(0) ? 1 : 0;
}

sub _outbox_try_write {
    my ($self, $peer, $payload) = @_;

    $self->pid_check;
    my $p = $self->_peer_pipe($peer)
        or die "'$peer' is not a valid message recipient";

    # Non-blocking write. write_message pushes into OUT_BUFFER and
    # calls flush(). With write_blocking(0) on the underlying pipe,
    # flush() partial-writes on EAGAIN and leaves the unwritten tail
    # in OUT_BUFFER for a later drain_pending to resume.
    $p->write_message($payload);

    return 0 if $p->pending_output;

    $self->{+STATS}->{sent}->{$peer}++;
    return 1;
}

# Atomic::Pipe owns its own OUT_BUFFER, which IS the per-peer
# queue. Role::Outbox's _OUTBOX would double-buffer the payload
# (write_message pushes into OUT_BUFFER, then drain_pending replays
# the same payload, which write_message then enqueues a SECOND
# time). The next four methods bypass _OUTBOX and use OUT_BUFFER
# directly so each payload reaches the kernel exactly once.

sub try_send_message {
    my $self = shift;

    # Mirror send_message's call signature so callers can pass
    # ($peer, \%content) and friends without having to serialize.
    # The pre-serialized fast path is ($peer, $string).
    my ($peer, $payload);
    if (@_ >= 2 && ref($_[1]) eq '' && !ref($_[0])) {
        ($peer, $payload) = @_;
    }
    else {
        my $msg = $self->build_message(@_);
        $peer    = $msg->to or croak "No peer specified";
        $payload = $self->{+SERIALIZER}->serialize($msg);
    }

    $self->pid_check;
    my $p = $self->_peer_pipe($peer)
        or die "'$peer' is not a valid message recipient";

    $p->write_message($payload);

    return 0 if $p->pending_output;

    $self->{+STATS}->{sent}->{$peer}++;
    return 1;
}

sub drain_pending {
    my $self = shift;

    my $delivered = 0;
    for my $p (values %{$self->{+PIPE_CACHE} // {}}) {
        next unless $p->pending_output;
        $p->flush;
        $delivered++ unless $p->pending_output;
    }
    return $delivered;
}

sub pending_sends {
    my $self = shift;
    my $n = 0;
    for my $p (values %{$self->{+PIPE_CACHE} // {}}) {
        $n++ if $p->pending_output;
    }
    return $n;
}

sub have_pending_sends {
    my $self = shift;
    for my $p (values %{$self->{+PIPE_CACHE} // {}}) {
        return 1 if $p->pending_output;
    }
    return 0;
}

sub pending_sends_to {
    my ($self, $peer) = @_;
    my $fifo = $self->peer_exists($peer) or return 0;
    my $p = $self->{+PIPE_CACHE}->{$fifo} or return 0;
    return $p->pending_output ? 1 : 0;
}

sub have_writable_handles {
    my $self = shift;
    for my $p (values %{$self->{+PIPE_CACHE} // {}}) {
        return 1 if $p->pending_output;
    }
    return 0;
}

sub writable_handles {
    my $self = shift;
    my @h;
    for my $p (values %{$self->{+PIPE_CACHE} // {}}) {
        next unless $p->pending_output;
        push @h => $p->wh;
    }
    return @h;
}

sub _outbox_writable_handle {
    my ($self, $peer) = @_;
    my $p = $self->_peer_pipe($peer) or return undef;
    return $p->wh;
}

# send_message respects send_blocking. In blocking mode, drain any
# backlog blocking, then write blocking. In non-blocking mode,
# delegate to try_send_message.
sub send_message {
    my $self = shift;
    my $msg  = $self->build_message(@_);

    my $peer_id = $msg->to or croak "No peer specified";
    my $payload = $self->{+SERIALIZER}->serialize($msg);

    $self->pid_check;

    if ($self->send_blocking) {
        $self->_drain_blocking($peer_id) if $self->pending_sends_to($peer_id);

        my $p = $self->_peer_pipe($peer_id)
            or die "'$peer_id' is not a valid message recipient";

        $p->write_message($payload);
        $p->flush(blocking => 1);
        $self->{+STATS}->{sent}->{$peer_id}++;
        return 1;
    }

    return $self->try_send_message($peer_id, $payload);
}

sub _drain_blocking {
    my ($self, $peer) = @_;

    my $p = $self->_peer_pipe($peer) or return;

    # AtomicPipe never populates _OUTBOX (the pipe's OUT_BUFFER is
    # the queue). Flushing pending_output blocking drains it.
    $p->flush(blocking => 1) if $p->pending_output;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Client::AtomicPipe - Use FIFO pipes for message transfers.

=head1 DESCRIPTION

Each client has a FIFO pipe, L<Atomic::Pipe> is used to allow multi-writer,
single-reader use of the pipe.

=head1 SYNOPSIS

    use IPC::Manager qw/ipcm_spawn ipcm_connect/;

    my $spawn = ipcm_spawn(protocol => 'AtomicPipe');

    my $con1 = $spawn->connect('con1');
    my $con2 = ipcm_connect(con2, $spawn->info);

    $con1->send_message(con1 => {'hello' => 'con2'});

    my @messages = $con2->get_messages;

=head1 CONSTRUCTOR PARAMETERS

=over 4

=item permissions => $octal

File permission bits used when creating the FIFO.  Defaults to C<0700>.

=back

=head1 METHODS

See L<IPC::Manager::Client> and L<IPC::Manager::Base::FS> for inherited methods.

=over 4

=item $con->pre_suspend_hook

Before suspending, drains any messages still buffered in the pipe and writes
them to the resume file so they are not lost across the suspend/reconnect
cycle.

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
