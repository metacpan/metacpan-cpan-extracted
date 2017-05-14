use Test::More tests => 26;

use strict;
use warnings;

use lib 't/lib';

use TestEnvironment;
use TestHelper;
use POE;

use_ok('Hopkins');

# create a test environment.  this entails processing
# hopkins and log4perl configuration files using templates
# and also instantiating a Hopkins object.

my $env = new TestEnvironment { source => 'hopkins.xml.tt' };
isa_ok($env, 'TestEnvironment', 'hopkins test environment');

my $envl4p = new TestEnvironment { source => 'log4perl.conf.tt' };
isa_ok($env, 'TestEnvironment', 'hopkins test environment');

my $hopkins = new Hopkins { conf => [ XML => { file => $env->conf } ], l4pconf => $envl4p->conf, scan => 30, poll => 30 };
isa_ok($hopkins, 'Hopkins', 'hopkins object');

# instantiate a new TestHelper object, which is simply a
# subclass of POE::API::Peek with a few convenience methods
# added for our testing harness.

my $helper = new TestHelper;
isa_ok($helper, 'TestHelper', 'test helper');
isa_ok($helper, 'POE::API::Peek', 'POE API');

# check hopkins state: 0 timeslice

ok($helper->is_kernel_running, 'kernel is running');

isa_ok($hopkins->manager->config, 'Hopkins::Config', 'hopkins->manager->config');
ok($hopkins->manager->config->loaded, 'config loaded');

cmp_ok($helper->session_count, '==', 2, 'session count');
ok($helper->resolve_alias('manager'), 'session running: manager');

is_deeply($helper->events_waiting('manager'), [qw(init_plugins scheduler init_store init_queues config_scan)], 'queued events');

# check hopkins state: 1 timeslice

ok(POE::Kernel->run_one_timeslice, 'run one timeslice');

cmp_ok($helper->session_count, '==', 3, 'session count');
ok($helper->resolve_alias('manager'),	'session running: manager');
ok($helper->resolve_alias('store'),		'session running: store');

if ((localtime)[0] > 30) {
	is_deeply($helper->events_waiting('manager'), [qw(queue_start queue_start executor config_scan executor)], 'queued events');
} else {
	is_deeply($helper->events_waiting('manager'), [qw(queue_start queue_start config_scan executor executor)], 'queued events');
}

# check hopkins state: 2 timeslice

ok(POE::Kernel->run_one_timeslice, 'run one timeslice');

if ((localtime)[0] > 30) {
	is_deeply($helper->events_waiting('manager'), [qw(executor config_scan executor)], 'queued events');
} else {
	is_deeply($helper->events_waiting('manager'), [qw(config_scan executor executor)], 'queued events');
}

cmp_ok($helper->session_count, '==', 5, 'session count');

ok($helper->resolve_alias('manager'),			'session running: manager');
ok($helper->resolve_alias('store'),				'session running: store');
ok($helper->resolve_alias('queue.parallel'),	'session running: queue.parallel');
ok($helper->resolve_alias('queue.serial'),		'session running: queue.serial');

cmp_ok($hopkins->manager->queue('serial')->num_queued, '==', 0, 'queue length: serial');
cmp_ok($hopkins->manager->queue('parallel')->num_queued, '==', 0, 'queue length: parallel');

