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
	'get_database_handle',
);

my $concurrency_manager;
lives_ok(
	sub
	{
		$concurrency_manager = IPC::Concurrency::DBI->new(
			'database_handle' => $dbh,
		);
	},
	'Instantiate a new IPC::Concurrency::DBI object.',
);

is(
	$concurrency_manager->get_database_handle(),
	$dbh,
	'The database connection handle returned by get_database_handle() matches the one passed to create the object.',
);

