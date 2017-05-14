use strict;
use warnings;
use FindBin::libs;
use Test::More;
use Mesos::Test::Utils;

use_ok('Mesos::SchedulerDriver');

my $driver = Mesos::SchedulerDriver->new(
    scheduler => test_scheduler,
    master    => test_master,
    framework => test_framework
);
isa_ok($driver, 'Mesos::SchedulerDriver');

ok($driver->does('Mesos::Role::Dispatcher'), 'driver does Mesos::Role::Dispatcher');

my $channel = $driver->channel;
ok($channel->does('Mesos::Role::Channel'), 'driver returned a channel');


done_testing;
