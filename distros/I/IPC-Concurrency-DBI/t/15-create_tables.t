#!perl

use strict;
use warnings;

use IPC::Concurrency::DBI;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 3;

use lib 't/';
use LocalTest;


can_ok(
	'IPC::Concurrency::DBI',
	'create_tables',
);

my $dbh = LocalTest::ok_database_handle();

my $concurrency_manager = IPC::Concurrency::DBI->new(
	'database_handle' => $dbh,
	'verbose'         => 0,
);

lives_ok(
	sub
	{
		$concurrency_manager->create_tables(
			database_type => 'SQLite',
		);
	},
	'Create table(s).',
);
