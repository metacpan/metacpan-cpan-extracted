package IPC::Manager::Client::UnixSocket;
use strict;
use warnings;

our $VERSION = '0.000035';

use File::Spec;
use Carp qw/croak/;
use Errno qw/EAGAIN EWOULDBLOCK/;
use POSIX qw/mkfifo/;
use IO::Socket::UNIX 1.55 qw/SOCK_DGRAM/;

use parent 'IPC::Manager::Base::FS::Handle';
use Object::HashBase qw{
    +buffer
    +socket
    +socket_cache
};

use Role::Tiny::With;
with 'IPC::Manager::Role::Outbox';

sub _viable { require IO::Socket::UNIX; IO::Socket::UNIX->VERSION('1.55'); 1 }

sub check_path { -S $_[1] }
sub path_type  { 'UNIX Socket' }

# sun_path is 108 bytes on Linux, 104 on some BSDs. The socket file
# path "<route>/<on_disk_name>" (NUL-terminated) must fit. Leave room
# for the route, a separator, and the trailing NUL.
use constant _SUN_PATH_LIMIT => 104;

sub max_on_disk_name_length {
    my $self = shift;
    return _SUN_PATH_LIMIT - length($self->{+ROUTE}) - 2; # '/' + NUL
}

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
    return unless defined $self->{+PATH};
    unlink($self->{+PATH}) or warn "Could not unlink socket: $!";
}

sub init {
    my $self = shift;

    $self->{+BUFFER} //= [];

    $self->SUPER::init();
}

sub _recv_all {
    my $self = shift;

    my $s = $self->{+SOCKET};
    while (1) {
        my $msg;
        my $ret = $s->recv($msg, 65536, 0);
        last unless defined $ret && length $msg;
        push @{$self->{+BUFFER}} => $msg;
    }
}

sub fill_buffer {
    my $self = shift;

    $self->_recv_all;

    return @{$self->{+BUFFER}} ? 1 : 0;
}

sub get_messages {
    my $self = shift;

    my @out;

    push @out => $self->read_resume_file;

    $self->_recv_all;
    for my $msg (@{$self->{+BUFFER}}) {
        $msg = IPC::Manager::Message->new($self->{+SERIALIZER}->deserialize($msg));
        push @out => $msg;
        $self->{+STATS}->{read}->{$msg->{from}}++;
    }

    @{$self->{+BUFFER}} = ();

    return $self->sort_messages(@out);
}

sub _peer_socket {
    my ($self, $peer) = @_;

    my $sock = $self->peer_exists($peer) or return undef;

    return $self->{+SOCKET_CACHE}->{$sock} //= do {
        my $w = IO::Socket::UNIX->new(
            Type     => SOCK_DGRAM,
            Peer     => $sock,
            Blocking => $self->send_blocking ? 1 : 0,
        ) or die "Cannot connect to socket: $!";
        $w;
    };
}

sub _outbox_set_blocking {
    my ($self, $bool) = @_;
    for my $s (values %{$self->{+SOCKET_CACHE} // {}}) {
        $s->blocking($bool ? 1 : 0);
    }
}

sub _outbox_can_send {
    my ($self, $peer) = @_;

    my $s = $self->_peer_socket($peer) or return 0;

    require IO::Select;
    my $sel = IO::Select->new($s);
    return $sel->can_write(0) ? 1 : 0;
}

sub _outbox_try_write {
    my ($self, $peer, $payload) = @_;

    $self->pid_check;
    my $s = $self->_peer_socket($peer)
        or die "'$peer' is not a valid message recipient";

    my $rc = $s->send($payload);
    if (defined $rc) {
        $self->{+STATS}->{sent}->{$peer}++;
        return 1;
    }
    return 0 if $! == EAGAIN || $! == EWOULDBLOCK;
    die "Cannot send message: $!";
}

sub _outbox_writable_handle {
    my ($self, $peer) = @_;
    return $self->_peer_socket($peer);
}

sub send_message {
    my $self = shift;
    my $msg  = $self->build_message(@_);

    my $peer_id = $msg->to or croak "No peer specified";
    my $payload = $self->{+SERIALIZER}->serialize($msg);

    $self->pid_check;

    if ($self->send_blocking) {
        $self->_drain_blocking($peer_id) if $self->pending_sends_to($peer_id);

        my $s = $self->_peer_socket($peer_id)
            or die "'$peer_id' is not a valid message recipient";

        $s->send($payload) or die "Cannot send message: $!";
        $self->{+STATS}->{sent}->{$peer_id}++;
        return 1;
    }

    return $self->try_send_message($peer_id, $payload);
}

sub _drain_blocking {
    my ($self, $peer) = @_;

    my $s = $self->_peer_socket($peer) or return;

    while ($self->{_OUTBOX}{$peer} && @{$self->{_OUTBOX}{$peer}}) {
        my $entry = shift @{$self->{_OUTBOX}{$peer}};
        my ($payload) = @$entry;
        $s->send($payload) or die "Cannot send message: $!";
        $self->{+STATS}->{sent}->{$peer}++;
    }
    delete $self->{_OUTBOX}{$peer};
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
