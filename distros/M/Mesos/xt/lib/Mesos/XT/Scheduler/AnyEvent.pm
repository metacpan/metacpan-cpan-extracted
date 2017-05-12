package Mesos::XT::Scheduler::AnyEvent;
use Mesos::SchedulerDriver;
use Test::Class::Moose;
with 'Mesos::XT::Role::Scheduler';

sub new_driver {
    my ($test, %args) = @_;
    return Mesos::SchedulerDriver->new(%args);
}

1;
