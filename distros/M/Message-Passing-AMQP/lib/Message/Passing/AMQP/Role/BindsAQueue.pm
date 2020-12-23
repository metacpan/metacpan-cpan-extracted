package Message::Passing::AMQP::Role::BindsAQueue;
use Moo::Role;
use Types::Standard qw( Str HashRef );
use Scalar::Util qw/ weaken /;
use namespace::autoclean;

with qw/
    Message::Passing::AMQP::Role::DeclaresExchange
    Message::Passing::AMQP::Role::DeclaresQueue
/;

has bind_routing_key => (
    isa => Str,
    is => 'ro',
    default => '#',
);

has bind_arguments => (
    isa => HashRef,
    is => 'ro',
);

after [qw[_set_queue ]] => sub {
    my $self = shift;
    if ($self->_has_exchange && $self->_has_queue) {
        weaken($self);
        $self->_channel->bind_queue(
           queue => $self->queue_name,
           exchange => $self->exchange_name,
           routing_key => $self->bind_routing_key,
           arguments => $self->bind_arguments,
           on_success => sub {
                #warn("Bound queue");
           },
           on_failure => sub {
                warn("Failed to bind queue");
           },
        );
    }
};

1;

=head1 NAME

Message::Passing::AMQP::Role::BindsAQueue

=head1 DESCRIPTION

Role for components which cause a single queue to be bound to a single exchange with a single routing key.

=head1 ATTRIBUTES

=head2 bind_arguments

Gets passed to L<Message::Passing::AMQP::ConnectionManager>, defaults to false.

=head2 bind_routing_key

Defaults to C<#>, which matches any routing key.

=head1 CONSUMES

=over

=item L<Message::Passing::AMQP::Role::BindsQueues>

=item L<Message::Passing::AMQP::Role::DeclaresExchange>

=item L<Message::Passing::AMQP::Role::DeclaresQueue>

=back

=cut
