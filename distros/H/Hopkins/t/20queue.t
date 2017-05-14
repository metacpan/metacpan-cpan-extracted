use Test::More tests => 47;

use strict;
use warnings;

use lib 't/lib';

use Test::MockObject;

use TestEnvironment;
use TestHelper;

use_ok('Hopkins');
use_ok('Hopkins::Queue');
use_ok('Class::MOP');

# create a test environment.  this entails processing
# hopkins and log4perl configuration files using templates
# and also instantiating a Hopkins object.

my $env = new TestEnvironment;
isa_ok($env, 'TestEnvironment', 'hopkins test environment');

my $config = new Test::MockObject;
isa_ok($config, 'Test::MockObject', 'fake config');

$config->mock('fetch', sub { return $env->scratch->mkdir('state') });

my $args	= [];
my $class	= Class::MOP::Class->create('Hopkins::Worker');

$class->add_method(new => sub { $args = [ @_ ] });

# create a queue object and start testing some things

my $queue = new Hopkins::Queue { kernel => $env->kernel, config => $config, name => 'general' };

isa_ok($queue, 'Hopkins::Queue', 'queue');
cmp_ok($queue->alias, 'eq', 'queue.general', 'queue alias');
isa_ok($queue->works, 'Tie::IxHash', 'queue work list');
isa_ok($queue->cache, 'Cache::FileCache', 'queue state');
cmp_ok($queue->halted, '==', 0, 'queue halted flag');
cmp_ok($queue->frozen, '==', 0, 'queue frozen flag');

# test out the halted/frozen flags and supporting action
# methods

$queue->freeze;

cmp_ok($queue->halted, '==', 0, 'queue halted flag');
cmp_ok($queue->frozen, '==', 1, 'queue frozen flag');

$queue->halt;

cmp_ok($queue->halted, '==', 1, 'queue halted flag');
cmp_ok($queue->frozen, '==', 1, 'queue frozen flag');

$queue->thaw;

cmp_ok($queue->halted, '==', 1, 'queue halted flag');
cmp_ok($queue->frozen, '==', 0, 'queue frozen flag');

$queue->continue;

cmp_ok($queue->halted, '==', 0, 'queue halted flag');
cmp_ok($queue->frozen, '==', 0, 'queue frozen flag');

# let's try spawning a worker

#$env->work->set_always('queue', $queue);

my $worker = $queue->spawn_worker('A', $env->work);
is_deeply($args, [ 'Hopkins::Worker', { postback => 'A', work => $env->work, queue => $queue } ], 'spawned worker');

# test adding Work to the Queue

cmp_ok($queue->num_queued, '==', 0, 'queue->num_queued');
$queue->enqueue($env->work);
cmp_ok($queue->num_queued, '==', 1, 'queue->num_queued');

# test state loading by instantiating a new Queue object.
# in order to thoroughly test this, we'll do it twice - once
# without a mock Config->get_task_info method and once with.
# only the second attempt should result in the Queue being
# populated.

$config->set_always('get_task_info', $env->task);

$queue = new Hopkins::Queue { kernel => $env->kernel, config => $config, name => 'general' };

isa_ok($queue, 'Hopkins::Queue', 'queue');
cmp_ok($queue->num_queued, '==', 1, 'queue->num_queued');
cmp_ok($queue->alias, 'eq', 'queue.general', 'queue->alias');

# ensure that when the Task object is looked up, it's not
# there.  this should cause the Work object to be discarded
# from the queue.

$config->set_always('get_task_info', undef);

$queue = new Hopkins::Queue { kernel => $env->kernel, config => $config, name => 'general' };
isa_ok($queue, 'Hopkins::Queue', 'queue');
cmp_ok($queue->num_queued, '==', 0, 'queue->num_queued');

# re-enable the Task lookup.  since it was discarded in the
# last state load, the lookup attempt shouldn't happen.

$config->set_always('get_task_info', $env->task);

$queue = new Hopkins::Queue { kernel => $env->kernel, config => $config, name => 'general' };

isa_ok($queue, 'Hopkins::Queue', 'queue');
cmp_ok($queue->num_queued, '==', 0, 'queue->num_queued');
cmp_ok($queue->alias, 'eq', 'queue.general', 'queue->alias');

# re-queue the Work and then access it using Queue->find.

$queue->enqueue($env->work);

my $work = $queue->find($env->work->id);

isa_ok($work, 'Hopkins::Work', 'queue work');
is($work->id,				'DEADBEEF',				'work->id');
is($work->task->name,		'counter',				'work->task');
is($work->date_enqueued,	'2009-06-01T20:24:42',	'work->date_enqueued');
is_deeply($work->options,	{ fruit => 'apple' },	'work->options');

# reload the queue from state and try to access it again
# using Queue->find

$queue = new Hopkins::Queue { kernel => $env->kernel, config => $config, name => 'general' };
isa_ok($queue, 'Hopkins::Queue', 'queue');
cmp_ok($queue->num_queued, '==', 1, 'queue->num_queued');

$work = $queue->find($env->work->id);

isa_ok($work, 'Hopkins::Work', 'queue work');
is($work->id,				'DEADBEEF',				'work->id');
is($work->task->name,		'counter',				'work->task');
is($work->date_enqueued,	'2009-06-01T20:24:42',	'work->date_enqueued');
is_deeply($work->options,	{ fruit => 'apple' },	'work->options');

# test prioritization

my $pri = \&Hopkins::Queue::prioritize;

my $a = new Test::MockObject;
my $b = new Test::MockObject;

no warnings 'once';

$Hopkins::Queue::a = $a;
$Hopkins::Queue::b = $b;

use warnings 'once';

$a->set_always(priority => 2);
$b->set_always(priority => 1);
cmp_ok($pri->(), '==', 1, 'prioritize: a=2 b=1');

$a->set_always(priority => 1);
$b->set_always(priority => 1);
cmp_ok($pri->(), '==', 0, 'prioritize: a=1 b=1');

$a->set_always(priority => 0);
$b->set_always(priority => 1);
cmp_ok($pri->(), '==', 0, 'prioritize: a=0 b=1');

$a->set_always(priority => 354);
$b->set_always(priority => 9);
cmp_ok($pri->(), '==', 0, 'prioritize: a=354 b=9');

$a->set_always(priority => 8);
$b->set_always(priority => 9);
cmp_ok($pri->(), '==', -1, 'prioritize: a=8 b=9');

