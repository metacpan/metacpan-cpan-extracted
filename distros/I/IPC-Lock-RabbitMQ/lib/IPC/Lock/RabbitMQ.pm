package IPC::Lock::RabbitMQ;
use Moose;
use MooseX::Types::Moose qw/ HashRef /;
use AnyEvent;
use IPC::Lock::RabbitMQ::Types qw/ MQ /;
use Scalar::Util qw/ refaddr /;
use IPC::Lock::RabbitMQ::Lock;
use namespace::autoclean;

our $VERSION = '0.007';

with 'IPC::Lock::RabbitMQ::HasTimeout';

has mq => (
    isa => MQ,
    is => 'ro',
    coerce => 1,
    required => 1,
);

# NOTE - We use an auto_delete queue for each lock, and we lock by
#        trying to start a consumer with 'exclusive'. WE DO NOT make
#        the queue exclusive, so someone else can grab the lock before
#        the queue is auto-deleted once we let it go. If someone is
#        already consuming this queue, then we get an AMQP fault and
#        our channel gets torn down. If we disconnect / crash, then
#        our consumtion is cancelled and the queue is auto deleted.

# Relevant parts of the AMQP spec follow.

#<field name="auto delete" type="bit">
#  auto-delete queue when unused
#  <doc>
#    If set, the queue is deleted when all consumers have finished
#    using it. Last consumer can be cancelled either explicitly or because
#    its channel is closed. If there was no consumer ever on the queue, it
#    won't be deleted.
#  </doc>
#  <rule implement="SHOULD">
#    <test>amq_queue_02</test>
#    The server SHOULD allow for a reasonable delay between the point
#    when it determines that a queue is not being used (or no longer
#    used), and the point when it deletes the queue.  At the least it
#    must allow a client to create a queue and then create a consumer
#    to read from it, with a small but non-zero delay between these
#    two actions.  The server should equally allow for clients that may
#    be disconnected prematurely, and wish to re-consume from the same
#    queue without losing messages.  We would recommend a configurable
#    timeout, with a suitable default value being one minute.
#  </rule>
# </field>

#<field name = "exclusive" type = "bit">
#  request exclusive access
#  <doc>
#    Request exclusive consumer access, meaning only this consumer can
#    access the queue.
#  </doc>
#  <doc name = "rule" test = "amq_basic_02">
#    If the server cannot grant exclusive access to the queue when asked,
#    - because there are other consumers active - it MUST raise a channel
#    exception with return code 403 (access refused).
#  </doc>
#</field>

sub lock {
    my ($self, $key) = @_;

    my $lock_cv = AnyEvent->condvar;

    my $channel_cv = AnyEvent->condvar;
    my $t = $self->_gen_timer($channel_cv, 'Open channel');
    $self->mq->open_channel(
         on_success => sub { $channel_cv->send(shift()) },
         on_failure => sub { $channel_cv->croak(shift()) },
         on_close => sub { $lock_cv->send(0) }, # Channel torn down if we consume locked queue.
    );
    my $channel = $channel_cv->recv;
    undef $t;
    my $queue_cv = AnyEvent->condvar;
    $t = $self->_gen_timer($queue_cv, 'Declare queue');
    $channel->declare_queue(
         queue => 'lock_' . $key,
         auto_delete => 1,
         on_success => sub { $queue_cv->send(1) },
         on_failure => sub { $queue_cv->croak(shift()) },
    );
    $queue_cv->recv;
    undef $t;
    $t = $self->_gen_timer($lock_cv, 'Start consume');
    $channel->consume(
        consumer_tag => refaddr($self) . $key,
        queue => 'lock_' . $key,
        exclusive => 1,
        on_consume => sub {
            warn("Saw message on lock queue lock_" . $key);
        },
        on_success => sub { $lock_cv->send(1) },
        on_failure => sub { $lock_cv->send(0) },
    );
    if ($lock_cv->recv) {
        undef $t;
        return IPC::Lock::RabbitMQ::Lock->new( locker => $self, lock_name => $key, channel => $channel, timeout => $self->timeout );
    }
    return;
}

1;

=head1 NAME

IPC::Lock::RabbitMQ - Simple and reliable scoped locking for coarse grained locks.

=head1 SYNOPSIS

    my $locker1 = IPC::Lock::RabbitMQ->new( mq => $rabbitfoot );
    my $locker2 = IPC::Lock::RabbitMQ->new( mq => $rabbitfoot );

    {
        my $lock  = $locker1->lock("foo");
        my $false = $locker2->lock("foo");
    }
    # $lock out of scope here, i.e.
    # $lock = undef;

    my $new_lock = $locker2->lock("foo");
    $new_lock->unlock;

=head1 DESCRIPTION

This module uses RabbitMQ to provide locking for coarse grained locks. The idea being
that you want to take a lock to stop duplicate jobs doing the same work you are doing.

The lock taken whilst your job is running can last quite a while, and you don't
want your lock to be broken by another process if you're still working. Equally well,
if you crash, you want the lock to be freed so that another process can retry the job.

=head1 METHODS

=head2 new

Constructs a lock manager object. Supply it with the C<mq> parameter which contains either
an instance of L<AnyEvent::RabbitMQ> or L<Net::RabbitFoot>

=head2 lock ($key)

Take a lock named with a specified key. Returns false if the lock is already held, returns
a L<IPC::Lock::RabbitMQ::Lock> object if the lock was successful.

The lock is unlocked either by latting the L<IPC::Lock::RabbitMQ::Lock> object
go out of scope, or by explicitly calling the unlock method on it.

=head1 AUTHOR

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>.

=head1 COPYRIGHT & LICENSE

Copyright 2011 the above author(s).

This sofware is free software, and is licensed under the same terms as perl itself.

=cut

