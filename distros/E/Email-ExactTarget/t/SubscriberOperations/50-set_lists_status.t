#!perl -T

use strict;
use warnings;

use Data::Dumper;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More;

use Email::ExactTarget;


eval 'use ExactTargetConfig';
$@
	? plan( skip_all => 'Local connection information for ExactTarget required to run tests.' )
	: plan( tests => 13 );

my $config = ExactTargetConfig->new();
my $test_list_ids = ExactTargetConfig->get_test_list_ids();
my $all_subscribers_list_id = ExactTargetConfig->get_all_subscribers_list_id();

# Create an object to communicate with Exact Target.
my $exact_target = Email::ExactTarget->new( %$config );
ok(
	defined( $exact_target ),
	'Create a new Email::ExactTarget object.',
) || diag( explain( $exact_target ) );

# Get a subscriber operations object.
my $subscriber_operations = $exact_target->subscriber_operations();
ok(
	defined( $subscriber_operations ),
	"Subscriber operations object retrieved.",
);

# Retrieve the subscribers.
my $subscribers = retrieve_subscribers( $subscriber_operations );

# Verify the initial state of list subscriptions.
my $initial_state =
{
	'john.q.public@example.com'        =>
	{
		$all_subscribers_list_id => 'Active',
		$test_list_ids->[0]      => 'Active',
	},
	'john.doe@example.com' =>
	{
		$all_subscribers_list_id => 'Active',
		$test_list_ids->[1]      => 'Active'
	},
};
foreach my $email ( sort keys %$initial_state )
{
	my $list_subscriptions = $subscribers->{ $email }->get_lists_status( 'is_live' => 1 );
	cmp_deeply(
		$list_subscriptions,
		$initial_state->{ $email },
		"Verify the initial list subscriptions for $email.",
	) || diag( 'ExactTarget list subscriptions: ' . Dumper( $list_subscriptions ) );
}

# Stage a few list subscription changes.
my $changes =
{
	'john.q.public@example.com'        =>
	{
		$test_list_ids->[1] => 'Active',
	},
	'john.doe@example.com' =>
	{
		# This tests unsubscribing as well.
		$test_list_ids->[0] => 'Unsubscribed',
		$test_list_ids->[1] => 'Unsubscribed',
	},
};
foreach my $email ( sort keys %$changes )
{
	$subscribers->{ $email }->set_lists_status(
		$changes->{ $email },
		'is_live' => 0,
	);
}
$subscribers->{'john.doe@example.com'}->set_attributes(
	{
		'First Name' => 'Guillaume',
	},
	'is_live' => 0,
);

# Perform the updates.
lives_ok(
	sub
	{
		$subscriber_operations->update(
			[values %$subscribers ]
		);
	},
	"No error found when updating the objects.",
);

# Check that the subscription status were updated locally.
foreach my $email ( sort keys %$changes )
{
	subtest(
		"Verify that the subscription status were updated locally for $email.",
		sub
		{
			plan( tests => scalar( keys %{ $changes->{ $email } } ) );

			my $new_lists_status = $subscribers->{ $email }->get_lists_status( 'is_live' => 1 );

			while ( my ( $list_id, $status ) = each( %{ $changes->{ $email } } ) )
			{
				is(
					exists( $new_lists_status->{ $list_id } )
						? $new_lists_status->{ $list_id }
						: undef,
					$status,
					"The status for list ID $list_id matches the submitted changes.",
				);
			}
		}
	);
}

# Retrieve the subscribers again to check that ExactTarget's value have
# really been updated.
$subscribers = retrieve_subscribers( $subscriber_operations );

# Check that the subscription status were updated remotely.
foreach my $email ( sort keys %$changes )
{
	subtest(
		"Verify that the subscription status were updated remotely for $email.",
		sub
		{
			plan( tests => scalar( keys %{ $changes->{ $email } } ) );

			my $new_lists_status = $subscribers->{ $email }->get_lists_status( 'is_live' => 1 );

			while ( my ( $list_id, $status ) = each( %{ $changes->{ $email } } ) )
			{
				is(
					exists( $new_lists_status->{ $list_id } )
						? $new_lists_status->{ $list_id }
						: undef,
					$status,
					"The status for list ID $list_id matches the submitted changes.",
				);
			}
		}
	);
}


sub retrieve_subscribers
{
	my ( $subscriber_operations ) = @_;

	# Retrieve the subscriber objects.
	my $subscribers;
	lives_ok(
		sub
		{
			$subscribers = $subscriber_operations->retrieve(
				'email' =>
				[
					'john.q.public@example.com',
					'john.doe@example.com',
				],
			);
		},
		'Retrieve the Email::ExactTarget::Subscriber objects.',
	);

	# Retrieve the list subscriptions.
	lives_ok(
		sub
		{
			$subscriber_operations->pull_list_subscriptions( $subscribers );
		},
		'Retrieve the list subscriptions.',
	);

	# Return a hash associating emails with the corresponding subscriber objects.
	return
	{
		map
		{
			$_->get_attribute('Email Address') => $_
		}
		@$subscribers
	};
}
