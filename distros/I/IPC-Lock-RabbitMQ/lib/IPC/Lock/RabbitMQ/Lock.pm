package IPC::Lock::RabbitMQ::Lock;
use Moose;
use MooseX::Types::Moose qw/ Int /;
use Devel::GlobalDestruction;
use Scalar::Util qw/ refaddr /;
use namespace::autoclean;

with 'IPC::Lock::RabbitMQ::HasTimeout';

has locker => (
    is => 'ro',
    required => 1,
);

has lock_name => (
    is => 'ro',
    required => 1,
);

has channel => (
    is => 'ro',
    required => 1,
);

sub DEMOLISH {
    my $self = shift;
    return if in_global_destruction();
    $self->unlock;
}

sub unlock {
    my ($self) = @_;
    return 0 unless $self->channel->{_is_open}; # This is fugly, the API to AnyEvent::RabbitMQ sucks here..
    my $cv = AnyEvent->condvar;
    my $t = $self->_gen_timer($cv, 'Unlock');
    $self->channel->close(
        on_success => sub { $cv->send(1) },
        on_failure => sub { $cv->send(0) },
    );
    $cv->recv;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

IPC::Lock::RabbitMQ - Simple and reliable scoped locking for coarse grained locks.

=head1 SYNOPSIS

    my $locker = IPC::Lock::RabbitMQ->new( mq => $rabbitfoot );

    my $lock = $locker->lock("foo");
    $lock->unlock;

=head1 DESCRIPTION

See L<IPC::Lock::RabbitMQ>

=head1 METHODS

=head2 new

Constructs a lock  object. You should never need to call this

=head2 unlock

Unlocks this lock.

=head2 DEMOLISH

Called when the lock object goes out of scope. Calls the unlock method.

=head1 AUTHOR, COPYRIGHT & LICENSE

See L<IPC::Lock::RabbitMQ>.

=cut
