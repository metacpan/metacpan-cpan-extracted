package Mesos::Role::SchedulerDriver;
use strict;
use warnings;
use Mesos;
use Mesos::Utils qw(import_methods);
use Types::Standard qw(:all);
use Type::Params qw(validate);
use Mesos::Types qw(:all);

use Moo::Role;
import_methods('Mesos::XS::SchedulerDriver');

=head1 NAME

Mesos::Role::SchedulerDriver - role for perl Mesos scheduler drivers

=cut

sub BUILD { shift->xs_init(@_) }

requires qw(
    xs_init
    channel
    start
    stop
    abort
    join
    run
    requestResources
    launchTask
    launchTasks
    killTask
    declineOffer
    reviveOffers
    sendFrameworkMessage
    reconcileTasks    
);

has scheduler => (
    is       => 'ro',
    isa      => Scheduler,
    required => 1,
);

has framework => (
    is       => 'ro',
    isa      => FrameworkInfo,
    coerce   => 1,
    required => 1,
);

has master => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has credential => (
    is     => 'ro',
    isa    => Credential,
    coerce => 1,
);

sub run {
    my ($self) = @_;
    $self->start;
    $self->join;
}

around requestResources => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(validate(\@args, ArrayRef[Request]));
};

around launchTasks => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(validate(\@args, ArrayRef[OfferID], ArrayRef[TaskInfo], Optional[Filters]));
};

around launchTask => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(validate(\@args, OfferID, ArrayRef[TaskInfo], Optional[Filters]));
};

around killTask => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(validate(\@args, TaskID));
};

around declineOffer => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(validate(\@args, OfferID, Optional[Filters]));
};

around sendFrameworkMessage => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(validate(\@args, ExecutorID, SlaveID, Str));
};

around reconcileTasks => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(validate(\@args, ArrayRef[TaskStatus]));
};

=head1 METHODS

=over 4

=item new(scheduler => $scheduler, framework => $frameworkInfo, master => $master, credentials => $credentials)

=item start()

=item stop($failover)

=item abort()

=item join()

=item run()

=item requestResources($requests)

=item launchTasks($offerIds, $tasks, $filters)

=item launchTask($offerId, $tasks, $filters)

=item killTask($taskId)

=item declineOffer($offerId, $filters)

=item reviveOffers()

=item sendFrameworkMessage($executorId, $slaveId, $data)

=item reconcileTasks($statuses)

=back

=cut

1;
