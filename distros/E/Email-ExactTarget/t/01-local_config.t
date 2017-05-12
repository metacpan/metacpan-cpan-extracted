#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More;
use Test::Type;

use Email::ExactTarget;
use Email::ExactTarget::Subscriber;


eval 'use ExactTargetConfig';
$@
	? plan( skip_all => 'Local connection information for ExactTarget required to run tests.' )
	: plan( tests => 3 );


# Username and password are mandatory arguments for Email::ExactTarget->new().
subtest(
	'Verify arguments that will be passed to new().',
	sub
	{
		plan( tests => 4 );

		can_ok(
			'ExactTargetConfig',
			'new',
		);
		my $config = ExactTargetConfig->new();

		ok_hashref(
			$config,
			name => 'Arguments to pass to new()',
		);
		like(
			$config->{'username'},
			qr/\w/,
			'The username is defined.',
		);
		like(
			$config->{'password'},
			qr/\w/,
			'The password is defined.',
		);
	}
);

# Verify the 'All Subscribers' list ID.
subtest(
	'Verify the "All Subscribers" list ID.',
	sub
	{
		plan( tests => 2 );

		can_ok(
			'ExactTargetConfig',
			'get_all_subscribers_list_id',
		);
		my $all_subscribers_list_id = ExactTargetConfig->get_all_subscribers_list_id();

		like(
			$all_subscribers_list_id,
			qr/^\d+$/,
			'The "All Subscribers" list ID is an integer.',
		);
	}
);

# Verify the test list IDs.
subtest(
	'Verify the test list IDs that will be used to test adding/removing subscribers to lists.',
	sub
	{
		plan( tests => 4 );

		can_ok(
			'ExactTargetConfig',
			'get_test_list_ids',
		);
		my $list_ids = ExactTargetConfig->get_test_list_ids();

		ok_arrayref(
			$list_ids,
			 name => '$list_ids',
		);
		$list_ids ||= [];

		ok(
			scalar( @$list_ids ) >= 2,
			'At least 2 test lists are defined in the "test_lists" key of the config',
		);

		subtest(
			'Verify that all the test list IDs are integers.',
			sub
			{
				plan( tests => scalar( @$list_ids ) );

				foreach my $list_id ( @$list_ids )
				{
					like(
						$list_id,
						qr/^\d+$/,
						'The list ID is an integer.',
					);
				}
			}
		);
	}
);
