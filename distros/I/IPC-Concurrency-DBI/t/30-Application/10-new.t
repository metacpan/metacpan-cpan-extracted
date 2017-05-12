#!perl

use strict;
use warnings;

use IPC::Concurrency::DBI::Application;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 8;

use lib 't/';
use LocalTest;


can_ok(
	'IPC::Concurrency::DBI::Application',
	'new',
);

my $dbh = LocalTest::ok_database_handle();

my $tests =
[
	{
		test_name         => 'Instantiate an application by name.',
		new_args          =>
		{
			database_handle   => $dbh,
			name              => 'cron_script.pl',
		},
		expected_result   => 'success',
	},
	{
		test_name         => 'Instantiate an application by ID.',
		new_args          =>
		{
			database_handle   => $dbh,
			id                => 1,
		},
		expected_result   => 'success',
	},
	{
		test_name         => 'Instantiate an application with a missing database handle.',
		new_args          =>
		{
			id                => 1,
		},
		expected_result   => 'failure',
	},
	{
		test_name         => 'Instantiate an application with neither a name nor an ID.',
		new_args          =>
		{
			database_handle   => $dbh,
		},
		expected_result   => 'failure',
	},
	{
		test_name         => 'Instantiate an application with an invalid name.',
		new_args          =>
		{
			database_handle   => $dbh,
			name              => 'cron_script_invalid.pl',
		},
		expected_result   => 'failure',
	},
	{
		test_name         => 'Instantiate an application with an invalid ID.',
		new_args          =>
		{
			database_handle   => $dbh,
			id                => 100000000,
		},
		expected_result   => 'failure',
	},
];

foreach my $test ( @$tests )
{
	subtest(
		$test->{'test_name'},
		sub
		{
			plan( tests => 2 );

			my $application;
			my $test_sub =
			sub
			{
				$application = IPC::Concurrency::DBI::Application->new(
					%{ $test->{'new_args'} },
				);
			};

			if ( $test->{'expected_result'} eq 'success' )
			{
				lives_ok(
					sub { $test_sub->(); },
					'Instantiate application.',
				);
				isa_ok(
					$application,
					'IPC::Concurrency::DBI::Application',
					'Return value of new()',
				);
			}
			else
			{
				dies_ok(
					sub { $test_sub->(); },
					'Instantiate application.',
				);
				is(
					$application,
					undef,
					'No return value.',
				);
			}
		}
	);
}

