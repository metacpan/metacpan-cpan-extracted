package Mesos::XT::Scheduler::Mojo;
use Mesos::Dispatcher::Mojo;
use Mesos::SchedulerDriver;
use Mojo::IOLoop;
use Test::Class::Moose;
with 'Mesos::XT::Role::Scheduler';

sub new_driver {
    my ($test, %args) = @_;
    my $loop = Mojo::IOLoop->singleton;
    my $disp = Mesos::Dispatcher::Mojo->new(loop => $loop);
    return Mesos::SchedulerDriver->new(dispatcher => $disp, %args);
}

1;
