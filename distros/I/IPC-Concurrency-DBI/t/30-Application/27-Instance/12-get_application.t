#!perl

use strict;
use warnings;

use IPC::Concurrency::DBI::Application;
use IPC::Concurrency::DBI::Application::Instance;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 6;

use lib 't/';
use LocalTest;


can_ok(
	'IPC::Concurrency::DBI::Application::Instance',
	'get_application',
);

my $dbh = LocalTest::ok_database_handle();

ok(
	defined(
		my $application = IPC::Concurrency::DBI::Application->new(
			database_handle   => $dbh,
			name              => 'cron_script.pl',
		)
	),
	'Create test application.',
);

ok(
	defined(
		my $instance = IPC::Concurrency::DBI::Application::Instance->new(
			application => $application,
		)
	),
	'Create instance.',
);

my $retrieved_application;
lives_ok(
	sub
	{
		$retrieved_application = $instance->get_application();
	},
	'Call get_application().',
);

is(
	$retrieved_application,
	$application,
	'The retrieved application matches the application passed to new().',
);
