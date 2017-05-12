#!perl -T

use strict;
use warnings;

use IPC::Concurrency::DBI::Application;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;

use lib 't/';
use LocalTest;


my $dbh = LocalTest::ok_database_handle();

can_ok(
	'IPC::Concurrency::DBI::Application',
	'get_database_handle',
);

my $application;
lives_ok(
	sub
	{
		$application = IPC::Concurrency::DBI::Application->new(
			database_handle   => $dbh,
			id                => 1,
		);
	},
	'Instantiate application.',
);

is(
	$application->get_database_handle(),
	$dbh,
	'The database connection handle returned by get_database_handle() matches the one passed to create the object.',
);

