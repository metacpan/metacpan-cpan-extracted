package IPC::Manager::Client::AtomicPipe;
use strict;
use warnings;

our $VERSION = '0.000027';

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

sub _viable           { require Atomic::Pipe; Atomic::Pipe->VERSION('0.022'); 1 }
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

sub send_message {
    my $self = shift;
    my $msg  = $self->build_message(@_);

    my $peer_id = $msg->to or croak "No peer specified";

    $self->pid_check;
    my $fifo = $self->peer_exists($peer_id) or die "'$peer_id' is not a valid message recipient";

    my $p = $self->{+PIPE_CACHE}->{$fifo} //= Atomic::Pipe->write_fifo($fifo);
    $p->write_message($self->{+SERIALIZER}->serialize($msg));

    $self->{+STATS}->{sent}->{$msg->{to}}++;
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
