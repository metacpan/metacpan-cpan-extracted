package Mesos::XT::Scheduler::IOAsync;
use IO::Async::Loop;
use Mesos::Dispatcher::IOAsync;
use Mesos::SchedulerDriver;
use Test::Class::Moose;
with 'Mesos::XT::Role::Scheduler';

sub new_driver {
    my ($test, %args) = @_;
    my $loop = IO::Async::Loop->new;
    my $disp = Mesos::Dispatcher::IOAsync->new(loop => $loop);
    return Mesos::SchedulerDriver->new(dispatcher => $disp, %args);
}

1;
