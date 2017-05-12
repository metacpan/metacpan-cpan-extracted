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
	'get_name',
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
	$application->get_name(),
	'cron_script.pl',
	'Check the name of the application.',
);
