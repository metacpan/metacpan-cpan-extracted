package Mesos::SchedulerDriver;
use Mesos::XS;
use Mesos::Types qw(:all);
use Type::Params qw(validate);
use Types::Standard qw(:all);
use Moo;
use namespace::autoclean;
with 'Mesos::Role::HasDispatcher';

=head1 NAME

Mesos::SchedulerDriver - perl interface to MesosSchedulerDriver

=head1 ATTRIBUTES

=head2 credential

A Mesos::Credential message

=head2 dispatcher

Either a Mesos::Dispatcher instance, or the short name of a dispatcher to instantiate(such as AnyEvent). The short name cannot be used if the dispatcher has required arguments.

Defaults to AnyEvent

=head2 framework

A Mesos::FrameworkInfo message

=head2 master

The address of a Mesos master

=head2 scheduler

A Mesos::Scheduler instance

=cut

has credential => (
    is     => 'ro',
    isa    => Credential,
    coerce => 1,
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

has scheduler => (
    is       => 'ro',
    isa      => Scheduler,
    required => 1,
);
sub event_handler { shift->scheduler }

around requestResources => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(validate \@args, ArrayRef[Request]);
};

around launchTasks => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(
        validate \@args,
        ArrayRef[OfferID],
        ArrayRef[TaskInfo],
        Optional[Filters],
    );
};

around launchTask => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(
        validate \@args,
        OfferID,
        ArrayRef[TaskInfo],
        Optional[Filters],
    );
};

around killTask => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(validate \@args, TaskID);
};

around declineOffer => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(validate \@args, OfferID, Optional[Filters]);
};

around sendFrameworkMessage => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(validate \@args, ExecutorID, SlaveID, Str);
};

around reconcileTasks => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(validate \@args, ArrayRef[TaskStatus]);
};

sub BUILD {
    my ($self) = @_;

    my @xs_args = map $self->$_, qw(dispatcher framework master);
    push @xs_args, $self->credential if $self->credential;

    $self->_xs_init(@xs_args);
}

=head1 METHODS

=over 4

=item new(%args)

    my $driver = Mesos::SchedulerDriver(%args)

        %args
            REQUIRED framework
            REQUIRED scheduler
            REQUIRED master
            OPTIONAL credential
            OPTIONAL dispatcher

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
