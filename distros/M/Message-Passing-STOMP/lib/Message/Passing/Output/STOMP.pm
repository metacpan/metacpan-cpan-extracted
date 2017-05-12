package Message::Passing::Output::STOMP;
use Moose;
use namespace::autoclean;

with qw/
    Message::Passing::STOMP::Role::HasAConnection
    Message::Passing::Role::Output
/;

has destination => (
    isa => 'Str',
    is => 'ro',
    required => 1,
);

sub connected {
    my $self = shift;
}

sub consume {
    my $self = shift;
    my $data = shift;
    my $destination = $self->destination;
    my $headers = undef;
    $self->connection_manager->connection->send($data, $destination, $headers);
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Message::Passing::Output::STOMP - output messages to STOMP.

=head1 SYNOPSIS

    message-pass --input STDIN --output STOMP --output_options \
        '{"destination":"/queue/foo","hostname":"localhost","port":"6163","username":"guest","password":"guest"}'
    {"data":{"some":"data"},"@metadata":"value"}

=head1 DESCRIPTION

A L<Message::Passing> L<AnyEvent::STOMP> output class.

=head1 ATTRIBUTES

=head2 destination

The queue name to subscribe to on the server.

=head2 hostname

Server hostname to connect to.

=head2 port

Server port number to connect to (default 6163).

=head2 username

The username to connect with (defaults to 'guest').

=head2 password

The password to connect with (defaults to 'guest').

=head1 METHODS

=head2 consume

Sends a message.

=head2 connected

Called by L<Message::Passing::STOMP::ConnectionManager> to indicate a
connection to the STOMP server has been made.

=head1 SEE ALSO

=over

=item L<Message::Passing::STOMP>

=item L<Message::Passing::Input::STOMP>

=item L<Message::Passing>

=item L<STOMP>

=back

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing::STOMP>.

=cut

