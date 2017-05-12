package IPC::Lock::RabbitMQ::HasTimeout;
use Moose::Role;
use MooseX::Types::Moose qw/ Int /;
use AnyEvent;
use Devel::GlobalDestruction;
use namespace::autoclean;

has timeout => (
    is => 'ro',
    isa => Int,
    default => 30,
);

sub _gen_timer {
    my ($self, $cv, $name) = @_;
    return unless $self->timeout;
    AnyEvent->now_update;
    AnyEvent->timer(
        after => $self->timeout,
        cb => sub {
            return if in_global_destruction;
            $cv->croak("$name  timed out after " . $self->timeout);
        },
    );
}

1;

=head1 NAME

IPC::Lock::RabbitMQ::HasTimeout - Role for things which timeout.

=head1 ATTRIBUTES

=head2 timeout

The timeout value, in secions.

=head1 METHODS

=head2 _gen_timer

Genertes an AnyEvent->timer for the timeout.

=cut


