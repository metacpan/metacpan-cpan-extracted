package IPC::Manager::Client::AtomicPipe;
use strict;
use warnings;

our $VERSION = '0.000007';

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

sub viable { eval { require Atomic::Pipe; 1 } || 0 }

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
    push @{$self->{+BUFFER}} => $self->{+PIPE}->read_message;
    return @{$self->{+BUFFER}} ? 1 : 0;
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

    return sort { $a->stamp <=> $b->stamp } @out;
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

=head1 METHODS

See L<IPC::Manager::Client>.

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
