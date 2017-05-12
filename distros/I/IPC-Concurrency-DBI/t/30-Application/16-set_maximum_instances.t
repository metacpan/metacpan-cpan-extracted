#!perl

use strict;
use warnings;

use IPC::Concurrency::DBI::Application;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 6;

use lib 't/';
use LocalTest;


can_ok(
	'IPC::Concurrency::DBI::Application',
	'set_maximum_instances',
);

my $dbh = LocalTest::ok_database_handle();

my $application;
lives_ok(
	sub
	{
		$application = IPC::Concurrency::DBI::Application->new(
			database_handle   => $dbh,
			name              => 'cron_script.pl',
		);
	},
	'Instantiate application.',
);

is(
	$application->get_maximum_instances(),
	10,
	'Check the maximum instances allowed.',
);

lives_ok(
	sub
	{
		$application->set_maximum_instances( 5 );
	},
	'Set a new maximum instances number.',
);

is(
	$application->get_maximum_instances(),
	5,
	'Check the maximum instances allowed.',
);

