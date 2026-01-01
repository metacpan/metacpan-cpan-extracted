package IPC::Manager::Client::UnixSocket;
use strict;
use warnings;

our $VERSION = '0.000001';

use File::Spec;
use Carp qw/croak/;
use POSIX qw/mkfifo/;
use IO::Socket::UNIX qw/SOCK_DGRAM/;
use IO::Select;

use parent 'IPC::Manager::Base::FS';
use Object::HashBase qw{
    +buffer
    +socket
    +select
};

sub check_path { -S $_[1] }
sub path_type  { 'UNIX Socket' }

sub suspend { croak "suspend is not supported by the UnixSocket driver" }

sub make_path {
    my $self = shift;
    my $path = $self->path;

    my $s = IO::Socket::UNIX->new(
        Type     => SOCK_DGRAM,
        Local    => $path,
        Blocking => 0,
    ) or die "Cannot create reader socket: $!";

    $self->{+SOCKET} = $s;
}

sub pre_disconnect_hook {
    my $self = shift;
    unlink($self->{+PATH}) or warn "Could not unlink socket: $!";
}

sub init {
    my $self = shift;

    $self->{+BUFFER} //= [];

    $self->SUPER::init();
}

sub select {
    my $self = shift;

    return $self->{+SELECT} if $self->{+SELECT};

    my $sel = IO::Select->new;
    $sel->add($self->{+SOCKET});

    return $self->{+SELECT} = $sel;
}

sub pending_messages {
    my $self = shift;

    $self->pid_check;

    return 1 if $self->have_resume_file;
    return 1 if @{$self->{+BUFFER}};

    my $sel = $self->select;

    return 1 if $sel->can_read(0);
    return 0;
}

sub ready_messages {
    my $self = shift;

    $self->pid_check;

    return 1 if $self->have_resume_file;

    return 1 if @{$self->{+BUFFER}};

    return 0 unless $self->pending_messages;

    my $s = $self->{+SOCKET};
    while (my $msg = <$s>) {
        push @{$self->{+BUFFER}} => $msg;
    }

    return 0;
}

sub get_messages {
    my $self = shift;

    my @out;

    push @out => $self->read_resume_file;
    push @out => @{$self->{+BUFFER}};

    my $s = $self->{+SOCKET};
    while (my $msg = <$s>) {
        $msg = IPC::Manager::Message->new($self->{+SERIALIZER}->deserialize($msg));
        push @out => $msg;
        $self->{+STATS}->{read}->{$msg->{from}}++;
    }

    @{$self->{+BUFFER}} = ();

    return sort { $a->stamp <=> $b->stamp } @out;
}

sub send_message {
    my $self = shift;
    my $msg  = $self->build_message(@_);

    my $peer_id = $msg->to or croak "No peer specified";

    $self->pid_check;
    my $sock = $self->peer_exists($peer_id) or die "'$peer_id' is not a valid message recipient";

    my $s = IO::Socket::UNIX->new(
        Type => SOCK_DGRAM,
        Peer => $sock,
    ) or die "Cannot connect to socket: $!";

    $s->send($self->{+SERIALIZER}->serialize($msg) . "\n") or die "Cannot send message: $!";

    $self->{+STATS}->{sent}->{$msg->{to}}++;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Client::UnixSocket - Use UNIX sockets for message transfers.

=head1 DESCRIPTION

Each client has a unix socket used in SOCK_DGRAM mode to allow multi-writer,
single-reader use of the socket.

=head1 NOTES

Suspend is not usable in this protocol.

=head1 SYNOPSIS

    use IPC::Manager qw/ipcm_spawn ipcm_connect/;

    my $spawn = ipcm_spawn(protocol => 'UnixSocket');

    my $con1 = $spawn->connect('con1');
    my $con2 = ipcm_connect(con2, $spawn->info);

    $con1->send_message(con1 => {'hello' => 'con2'});

    my @messages = $con2->get_messages;

=head1 METHODS

See L<IPC::Manager::Client>.

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://https://github.com/exodist/IPC-Manager>.

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
