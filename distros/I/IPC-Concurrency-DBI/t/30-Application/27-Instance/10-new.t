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
	'new',
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
	'Create test application.',
);

my $tests =
[
	{
		test_name         => 'Create an instance with an application.',
		new_args          =>
		{
			application => $application,
		},
		expected_result   => 'success',
	},
	{
		test_name         => 'Instantiate with an incorrect application key',
		new_args          =>
		{
			application => {} ,
		},
		expected_result   => 'failure',
	},
	{
		test_name         => 'Instantiate with no application key',
		new_args          =>
		{
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

			my $instance;
			my $test_sub =
			sub
			{
				$instance = IPC::Concurrency::DBI::Application::Instance->new(
					%{ $test->{'new_args'} },
				);
			};

			if ( $test->{'expected_result'} eq 'success' )
			{
				lives_ok(
					sub { $test_sub->(); },
					'Create new instance.',
				);
				isa_ok(
					$instance,
					'IPC::Concurrency::DBI::Application::Instance',
					'Return value of new()',
				);
			}
			else
			{
				dies_ok(
					sub { $test_sub->(); },
					'Create new instance.',
				);
				is(
					$instance,
					undef,
					'No return value.',
				) || diag( explain( $instance ) ) ;
			}
		}
	);
}


