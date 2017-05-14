use strict;
use warnings;
use FindBin::libs;
use Test::More;
use Mesos::Test::Utils;

use_ok('Mesos::ExecutorDriver');

my $driver = Mesos::ExecutorDriver->new(
    executor => test_executor,
);
isa_ok($driver, 'Mesos::ExecutorDriver');

ok($driver->does('Mesos::Role::Dispatcher'), 'driver does Mesos::Role::Dispatcher');

my $channel = $driver->channel;
ok($channel->does('Mesos::Role::Channel'), 'driver returned a channel');


done_testing;
