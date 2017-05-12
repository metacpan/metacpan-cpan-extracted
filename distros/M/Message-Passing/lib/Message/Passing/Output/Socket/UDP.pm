package Message::Passing::Output::Socket::UDP;
use Moo;
use IO::Socket::INET;
use namespace::clean -except => 'meta';

with qw/
    Message::Passing::Role::Output
    Message::Passing::Role::HasHostnameAndPort
    Message::Passing::Role::HasErrorChain
/;

has '+port' => (
    required => 1,
);

sub _default_port { die "You must supply a port #" }

has handle => (
    is => 'ro',
    builder => '_build_handle',
    lazy => 1,
);

sub BUILD {
    my $self = shift;
    $self->handle;
}

sub _build_handle {
    my $self = shift;
    IO::Socket::INET->new(
        Proto    => 'udp',
        PeerAddr => $self->hostname,
        PeerPort => $self->port,
    ) or die "Could not create UDP socket: $!\n";
}

sub consume {
    my ($self, $msg) = @_;
    $self->handle->send($msg);
}

1;

=head1 NAME

Message::Passing::Output::Socket::UDP

=head1 DESCRIPTION

Outputs messages to a UDP socket.

=head1 METHODS

=head2 consume

Consumes a message by emitting it over UDP.

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut