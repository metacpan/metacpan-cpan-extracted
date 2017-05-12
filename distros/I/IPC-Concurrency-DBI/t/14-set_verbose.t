#!perl -T

use strict;
use warnings;

use IPC::Concurrency::DBI;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 8;

use lib 't/';
use LocalTest;


my $dbh = LocalTest::ok_database_handle();

can_ok(
	'IPC::Concurrency::DBI',
	'set_verbose',
);

my $concurrency_manager;
lives_ok(
	sub
	{
		$concurrency_manager = IPC::Concurrency::DBI->new(
			'database_handle' => $dbh,
			'verbose'         => 2,
		);
	},
	'Instantiate a new IPC::Concurrency::DBI object.',
);

is(
	$concurrency_manager->get_verbose(),
	2,
	'Verbose level is correct.',
);

lives_ok(
	sub
	{
		$concurrency_manager->set_verbose( 1 );
	},
	'Set verbose level to 1.',
);

is(
	$concurrency_manager->get_verbose(),
	1,
	'Verbose level is correct.',
);

lives_ok(
	sub
	{
		$concurrency_manager->set_verbose( 0 );
	},
	'Set verbose level to 0.',
);

is(
	$concurrency_manager->get_verbose(),
	0,
	'Verbose level is correct.',
);
