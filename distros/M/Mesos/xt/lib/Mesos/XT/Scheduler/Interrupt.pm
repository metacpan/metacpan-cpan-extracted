package Mesos::XT::Scheduler::Interrupt;
use Mesos::SchedulerDriver;
use Test::Class::Moose;
with 'Mesos::XT::Role::Scheduler';

sub test_startup { shift->test_skip('TODO') }

sub new_driver {
    my ($test, %args) = @_;
    return Mesos::SchedulerDriver->new(dispatcher => 'Interrupt', %args);
}

1;
