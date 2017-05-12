#!perl

use strict;
use warnings;

use IPC::Concurrency::DBI::Application;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;

use lib 't/';
use LocalTest;


can_ok(
	'IPC::Concurrency::DBI::Application',
	'get_id',
);

my $dbh = LocalTest::ok_database_handle();

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
	$application->get_id(),
	1,
	'The ID of the application matches.',
);
