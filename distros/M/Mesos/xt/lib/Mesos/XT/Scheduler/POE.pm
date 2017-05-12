package Mesos::XT::Scheduler::POE;
use Mesos::SchedulerDriver;
use POE qw(Loop::Select);
use Test::Class::Moose;
with 'Mesos::XT::Role::Scheduler';
POE::Kernel->run;

sub new_driver {
    my ($test, %args) = @_;
    return Mesos::SchedulerDriver->new(dispatcher => 'POE', %args);
}

1;
