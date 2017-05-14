use Test::More tests => 62;

use strict;
use warnings;

use lib 't/lib';

use TestEnvironment;
use Test::MockObject;
use Test::MockObject::Extends;

use_ok('Hopkins::Config::XML');

my $env		= new TestEnvironment { source => 'hopkins.xml.tt' };
my $config	= new Hopkins::Config::XML { file => $env->conf };
my $status	= undef;

isa_ok($config, 'Hopkins::Config', 'hopkins config object');
isa_ok($config, 'Hopkins::Config::XML', 'hopkins config object');
ok(!defined($config->config), 'hopkins config tree');

$status = $config->load;

isa_ok($status, 'Hopkins::Config::Status', 'hopkins config status object');

ok($status->ok,					'status indicates OK condition');
is($status->errmsg, undef,		'status error message is undefined');
ok(!$status->failed,			'status does not indicate failure condition');
ok($status->parsed,				'status indicates parsing succeeded');
ok(!$status->store_modified,	'status does not indicate store was modified');

isa_ok($config->config, 'HASH', 'hopkins config tree');

is_deeply
(
	$config->fetch('database'),
	{
		dsn		=> 'dbi:SQLite:dbname=' . $env->scratch . '/hopkins.db',
		user	=> 'root',
		pass	=> '',
		options	=>
		{
			AutoCommit	=> 1,
			RaiseError	=> 1,
			name_sep	=> '.',
			quote_char	=> ''
		},
	},
	'hopkins config tree: database'
);

my $dt		= DateTime->now;
my $queue	= undef;
my $task	= undef;
my @a		= ();

# Hopkins::Config->get_queue_names

@a = $config->get_queue_names;

cmp_ok(scalar(@a), '==', 2, 'get_queue_names length');
is_deeply([ sort @a ], [ 'parallel', 'serial' ], 'get_queue_names contents');

# Hopkins::Config->get_queue_info

$queue = $config->get_queue_info('serial');

isa_ok($queue, 'HASH', 'get_queue_info contents');
is($queue->{name}, 'serial', 'get_queue_info: queue name');
is($queue->{concurrency}, '1', 'get_queue_info: queue concurrency');

# Hopkins::Config->get_task_names

@a = $config->get_task_names;

cmp_ok(scalar(@a), '==', 4, 'get_queue_names length');
is_deeply([ sort @a ], [ 'Count', 'Email', 'Sum', 'Wrench' ], 'get_task_names contents');

# Hopkins::Config->get_task_info

$task = $config->get_task_info('Count');

isa_ok($task,			'Hopkins::Task',	'get_task_info contents');
isa_ok($task->schedule, 'DateTime::Set',	'get_task_info->task->schedule');
isa_ok($task->chain,	'ARRAY',			'get_task_info->task->chain');

is($task->name,		'Count',				'get_task_info->task->name');
is($task->class,	'Hopkins::Test::Count',	'get_task_info->task->class');
is($task->queue,	'serial',				'get_task_info->task->queue');

ok(!$task->enabled, 'get_task_info->task->enabled');

$dt->set(year => 2009,	month	=> 5,	day		=> 15);
$dt->set(hour => 14,	minute	=> 26,	second	=> 42);

ok(!$task->schedule->contains($dt), 'not scheduled for 2009-05-15 14:26:42');

$dt->set(year => 2009,	month	=> 5,	day		=> 15);
$dt->set(hour => 14,	minute	=> 27,	second	=> 00);

ok($task->schedule->contains($dt), 'scheduled for 2009-05-15 14:27:00');

cmp_ok(scalar(@{ $task->chain }), '==', 1, 'chained item 1');

# chained items

$task = $task->chain->[0];

isa_ok($task,			'Hopkins::Task',		'task->chain->[0] contents');
isa_ok($task->options,	'HASH',					'task->chain->[0]->options');
isa_ok($task->chain,	'ARRAY',				'task->chain->[0]->chain');
is($task->class,		'Hopkins::Test::Sum',	'task->chain->[0]->class');

ok(!defined($task->schedule), 'task->chain->[0]->schedule');
cmp_ok(scalar(keys %{ $task->options }), '==', 2, 'chained item 1 options');

is($task->options->{arg0}, '1', 'task->chain->[0]->options->{arg0}');
is($task->options->{arg1}, '2', 'task->chain->[0]->options->{arg0}');

cmp_ok(scalar(@{ $task->chain }), '==', 1, 'chained item 1');

# subchained item

$task = $task->chain->[0];

isa_ok($task,			'Hopkins::Task',	'task->chain->[0]->chain->[0] contents');
isa_ok($task->options,	'HASH',				'task->chain->[0]->chain->[0]->options');
is($task->cmd,			'/usr/bin/mail',	'task->chain->[0]->chain->[0]->cmd');

ok(!defined($task->chain),		'task->chain->[0]->chain->[0]->chain');
ok(!defined($task->schedule),	'task->chain->[0]->chain->[0]->schedule');
cmp_ok(scalar(keys %{ $task->options }), '==', 1, 'chained item 2 options');

is($task->options->{dest}, 'test@domain.com', 'task->chain->[0]->chain->[0]->options->{dest}');

# Hopkins::Config->get_task_info

$task = $config->get_task_info('Sum');

isa_ok($task,			'Hopkins::Task', 'get_task_info contents');
isa_ok($task->schedule, 'DateTime::Set', 'get_task_info->task->schedule');

is($task->name,		'Sum',					'get_task_info->task->name');
is($task->class,	'Hopkins::Test::Sum',	'get_task_info->task->class');
is($task->queue,	'parallel',				'get_task_info->task->queue');

ok($task->enabled, 'get_task_info->task->enabled');

ok(!$task->schedule->contains($dt), 'not scheduled for 2009-05-15 14:27:00');

$dt->set(year => 2009,	month	=> 5,	day		=> 20);
$dt->set(hour => 3,		minute	=> 15,	second	=> 00);

ok($task->schedule->contains($dt), 'scheduled for 2009-05-20 03:15:00');

my $dt1		= $dt->clone->truncate(to => 'year');
my $dt2		= $dt->clone->add(years => 1)->truncate(to => 'year');
my $span	= DateTime::Span->from_datetimes(start => $dt1, end => $dt2);

is_deeply
(
	[ map { $_->iso8601 } $task->schedule->as_list(span => $span) ],
	[
		'2009-01-10T03:15:00',
		'2009-01-20T03:15:00',
		'2009-02-10T03:15:00',
		'2009-02-20T03:15:00',
		'2009-03-10T03:15:00',
		'2009-03-20T03:15:00',
		'2009-04-10T03:15:00',
		'2009-04-20T03:15:00',
		'2009-05-10T03:15:00',
		'2009-05-20T03:15:00',
		'2009-06-10T03:15:00',
		'2009-06-20T03:15:00',
		'2009-07-10T03:15:00',
		'2009-07-20T03:15:00',
		'2009-08-10T03:15:00',
		'2009-08-20T03:15:00',
		'2009-09-10T03:15:00',
		'2009-09-20T03:15:00',
		'2009-10-10T03:15:00',
		'2009-10-20T03:15:00',
		'2009-11-10T03:15:00',
		'2009-11-20T03:15:00',
		'2009-12-31T02:30:00'
	],
	'multiple schedules'
);

# Hopkins::Config->scan

ok(!$config->scan, 'scan config for changes to unchanged file');

# reload the configuration after making a small change to
# the running database configuration.  the config data
# structure should now differ under the database node.

$env->source('hopkins.xml2.tt');

ok($config->scan, 'scan config for changes to updated file');

$status = $config->load;

isa_ok($status, 'Hopkins::Config::Status', 'hopkins config status object');

ok($status->ok,				'status indicates OK condition');
ok(!$status->failed,		'status does not indicate failure condition');
ok($status->parsed,			'status indicates parsing succeeded');
ok($status->store_modified,	'status indicates store was modified');

is_deeply
(
	$config->fetch('database'),
	{
		dsn		=> 'dbi:SQLite:dbname=' . $env->scratch . '/hopkins.db',
		user	=> 'toor',
		pass	=> 'secret',
		options	=>
		{
			AutoCommit	=> 1,
			RaiseError	=> 1,
			name_sep	=> '.',
			quote_char	=> ''
		},
	},
	'hopkins config tree: database'
);

