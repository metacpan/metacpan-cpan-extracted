package Mesos::XT::Role::Scheduler;
use File::Spec::Functions qw(catfile);
use Mesos::Test::Scheduler;
use Mesos::Test::Utils qw(
    test_framework
    test_master
);
use Test::Class::Moose::Role;
requires qw(new_driver);

sub test_scheduler_without_executor {
    my ($test) = @_;

    my $scheduler = Mesos::Test::Scheduler->new(
        registered     => sub {},
        resourceOffers => sub {
            my ($self, $driver, $offers) = @_;
            $driver->declineOffer($_->{id}) for @$offers;
        },
    );
    my $driver = $test->new_driver(
        framework => test_framework(sprintf "%s test", ref($test)),
        master    => test_master,
        scheduler => $scheduler,
    );

    {
        $driver->run_once;
        my $last = $scheduler->last_event;
        my ($event, $frameworkId, $masterInfo) = @$last;

        is $event, 'registered', 'received registered event';
        is ref($frameworkId), 'Mesos::FrameworkID', 'registered event called with framework id';
        is ref($masterInfo),  'Mesos::MasterInfo', 'registered event called with master info';
    }

    {
        $driver->run_once;
        my $last = $scheduler->last_event;
        my ($event, $resourceOffers) = @$last;

        is $event, 'resourceOffers', 'received resource offers';
        is ref($resourceOffers), 'ARRAY', 'resource offers event called with array of offers';
        is ref($_), 'Mesos::Offer', 'offer array element was a Mesos::Offer'
            for @$resourceOffers;
    }

    $driver->stop;
}

1;
