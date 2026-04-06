package IPC::Manager::Client::UnixSocket;
use strict;
use warnings;

our $VERSION = '0.000011';

use File::Spec;
use Carp qw/croak/;
use POSIX qw/mkfifo/;
use IO::Socket::UNIX 1.55 qw/SOCK_DGRAM/;

use parent 'IPC::Manager::Base::FS::Handle';
use Object::HashBase qw{
    +buffer
    +socket
    +socket_cache
};

sub viable { local $@; eval { require IO::Socket::UNIX; IO::Socket::UNIX->VERSION('1.55'); 1 } || 0 }

sub check_path { -S $_[1] }
sub path_type  { 'UNIX Socket' }

sub have_handles_for_select { 1 }
sub handles_for_select { $_[0]->{+SOCKET} }

sub suspend_supported { 0 }
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

sub fill_buffer {
    my $self = shift;

    my $s = $self->{+SOCKET};
    while (my $msg = <$s>) {
        push @{$self->{+BUFFER}} => $msg;
    }

    return @{$self->{+BUFFER}} ? 1 : 0;
}

sub get_messages {
    my $self = shift;

    my @out;

    push @out => $self->read_resume_file;

    my $s = $self->{+SOCKET};
    push @{$self->{+BUFFER}} => <$s>;
    for my $msg (@{$self->{+BUFFER}}) {
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

    my $s = $self->{+SOCKET_CACHE}->{$sock} //= IO::Socket::UNIX->new(
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
