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

my $concurrency_manager;
lives_ok(
	sub
	{
		# Configure the concurrency object.
		$concurrency_manager = IPC::Concurrency::DBI->new(
			'database_handle' => $dbh,
			'verbose'         => 0,
		);
	},
	'Create a new IPC::Concurrency::DBI object.',
);

ok(
	defined( $concurrency_manager ),
	'The object is defined.',
);

ok(
	$concurrency_manager->isa( 'IPC::Concurrency::DBI' ),
	'The object is of type IPC::Concurrency::DBI.',
);
