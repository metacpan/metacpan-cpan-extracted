#!perl

use strict;
use warnings;

use IPC::Concurrency::DBI;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 10;

use lib 't/';
use LocalTest;


my $dbh = LocalTest::ok_database_handle();

my $concurrency_manager = IPC::Concurrency::DBI->new(
	'database_handle' => $dbh,
	'verbose'         => 0,
);

my $application = $concurrency_manager->get_application(
	name => 'cron_script.pl',
);

ok(
	defined( $application ),
	'Retrieve application.',
);

is(
	$application->get_instances_count(),
	0,
	'Check that no instances have been started.',
);

my $instance = $application->start_instance();
ok(
	defined( $instance ),
	'Start a new instance.',
);

is(
	$application->get_instances_count(),
	1,
	'Current instances is 1.',
);

# Start the second instance in a new scope, to test DESTROY().
{
	my $instance2 = $application->start_instance();
	ok(
		defined( $instance2 ),
		'Start a new instance.',
	);

	is(
		$application->get_instances_count(),
		2,
		'Current instances is 2.',
	);

	ok(
		$instance->finish(),
		'Finish the first instance.',
	);

	is(
		$application->get_instances_count(),
		1,
		'Current instances is 1 again.',
	);
}

# If DESTROY() works correctly, $instance2 going out of scope will have resulted
# in it being destroyed and the count of current instances being 0 again.
is(
	$application->get_instances_count(),
	0,
	'Verify that an instance object going out of scope flags the instance as finished.',
);
