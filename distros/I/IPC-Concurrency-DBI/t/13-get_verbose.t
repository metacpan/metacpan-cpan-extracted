#!perl -T

use strict;
use warnings;

use IPC::Concurrency::DBI;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;

use lib 't/';
use LocalTest;


my $dbh = LocalTest::ok_database_handle();

can_ok(
	'IPC::Concurrency::DBI',
	'get_verbose',
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

