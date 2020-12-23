package Message::Passing::AMQP::Role::HasAChannel;
use Moo::Role;
use Scalar::Util qw/ weaken /;
use AnyEvent;
use AnyEvent::RabbitMQ;
use namespace::autoclean;

with 'Message::Passing::AMQP::Role::HasAConnection';

has _channel => (
    is => 'ro',
    writer => '_set_channel',
    clearer => '_clear_channel',
);

sub connected {
    my ($self, $connection) = @_;
    weaken($self);
    $connection->open_channel(
        on_success => sub {
            my $channel = shift;
            $self->_set_channel($channel);
        },
        on_failure => sub {
            $self->_clear_channel;
        },
        on_close => sub {
            $self->_clear_channel;
        },
    );
}
sub disconnected {}

1;

=head1 NAME

Message::Passing::AMQP::Role::HasAChannel - Role for instances which have an AMQP channel.

=head1 ATTRIBUTES

=head1 METHODS

=head2 connected

Called when the channel has connected

=head2 disconnected

Called when the channel disconnects.

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing::AMQP>.

=cut

