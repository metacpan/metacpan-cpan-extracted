package Message::Passing::AMQP::Role::DeclaresExchange;
use Moo::Role;
use Types::Standard qw( Bool Str Enum );
use Scalar::Util qw/ weaken /;
use namespace::autoclean;

with 'Message::Passing::AMQP::Role::HasAChannel';

has exchange_name => (
    is => 'ro',
    required => 1,
    isa => Str,
);

has exchange_type => (
    is => 'ro',
    isa => Enum([qw( topic direct fanout headers )]),
    default => 'topic',
);

has exchange_durable => (
    is => 'ro',
    isa => Bool,
    default => 1,
);

has exchange_auto_delete => (
    is => 'ro',
    isa => Bool,
    default => 0,
);

has _exchange => (
    is => 'ro',
    writer => '_set_exchange',
    predicate => '_has_exchange',
);

after _set_channel => sub {
    my $self = shift;
    weaken($self);
    $self->_channel->declare_exchange(
        type => $self->exchange_type,
        durable => $self->exchange_durable,
        auto_delete => $self->exchange_auto_delete,
        exchange => $self->exchange_name,
        on_success => sub {
            $self->_set_exchange(shift()->method_frame);
        },
        on_failure => sub {
            $self->_clear_channel;
        },
    );
};

1;

=head1 NAME

Message::Passing::AMQP::Role::DeclaresExchange - Role for instances which have an AMQP exchange.

=head1 ATTRIBUTES

=head2 exchange_name

Defines the exchange name, required.

=head2 exchange_type

Is one of topic, direct, fanout or headers, defaults to topic.

=head2 exchange_durable

Defines if the exchange is durable, defaults to true.

=head2 exchange_auto_delete

Defines if the exchange will be auto-deleted after the connection is closed,
defaults to false.

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing::AMQP>.

=cut
