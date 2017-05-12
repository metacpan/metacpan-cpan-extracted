package Message::Passing::AMQP::Role::DeclaresQueue;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Scalar::Util qw/ weaken /;
use namespace::autoclean;

with 'Message::Passing::AMQP::Role::HasAChannel';

has queue_name => (
    is => 'ro',
    isa => 'Str',
    predicate => '_has_queue_name',
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->_queue->method_frame->queue;
    }
);

# FIXME - Should auto-build from _queue as above
has queue_durable => (
    is => 'ro',
    isa => 'Bool',
    default => 1,
);

has queue_exclusive => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

has queue_auto_delete => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);


has _queue => (
    is => 'ro',
    writer => '_set_queue',
    predicate => '_has_queue',
);

has queue_arguments => (
    isa => 'HashRef',
    is => 'ro',
    default => sub { {} }, # E.g. 'x-ha-policy' => 'all'
);

after '_set_channel' => sub {
    my $self = shift;
    weaken($self);
    $self->_channel->declare_queue(
        arguments => $self->queue_arguments,
        durable => $self->queue_durable,
        exclusive => $self->queue_exclusive,
        auto_delete => $self->queue_auto_delete,
        $self->_has_queue_name ? (queue => $self->queue_name) : (),
        on_success => sub {
            $self->_set_queue(shift());
        },
        on_failure => sub {
            warn("Failed to get queue");
            $self->_clear_channel;
        },
    );
};

1;

=head1 NAME

Message::Passing::AMQP::Role::DeclaresQueue - Role for instances which have an AMQP queue.

=head1 ATTRIBUTES

=head2 queue_name

Defines the queue name, defaults to the name returned by the server.

=head2 queue_durable

Defines if the queue is durable, defaults to true.

=head2 queue_exclusive

Defines if the queue is exclusive, defaults to false.

=head2 queue_arguments

Defines queue arguments, defaults to an empty hashref.

=head2 queue_auto_delete

If true, the queue is flagged as auto-delete, defaults to false.

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing::AMQP>.

=cut
