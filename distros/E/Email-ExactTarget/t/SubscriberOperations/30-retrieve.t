#!perl -T

use strict;
use warnings;

use Data::Dumper;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More;

use Email::ExactTarget;


eval 'use ExactTargetConfig';
$@
	? plan( skip_all => 'Local connection information for ExactTarget required to run tests.' )
	: plan( tests => 10 );


# Retrieve the list of addresses to use for testing.
my $test_emails = {};
foreach my $line ( <DATA> )
{
	chomp( $line );
	next if !defined( $line ) || substr( $line, 0, 1 ) eq '#' || $line !~ /\w/;
	my ( $email, $is_valid ) = split( /\t/, $line );
	$test_emails->{ $email } = $is_valid;
}
my $test_emails_count = scalar( keys %$test_emails );
isnt(
	$test_emails_count,
	0,
	'Find test emails.'
);

# Make sure we have a mix of valid and invalid emails for proper testing.
my $valid_emails_count = scalar( grep { $_ } values %$test_emails );
isnt(
	$valid_emails_count,
	0,
	'Valid emails exist in the list of test emails.',
);
isnt(
	$test_emails_count - $valid_emails_count,
	0,
	'Invalid emails exist in the list of test emails.',
) || diag( "Found $valid_emails_count valid emails out of $test_emails_count." );

# Retrieve the local config.
my $config = ExactTargetConfig->new();

# Create an object to communicate with Exact Target.
my $exact_target = Email::ExactTarget->new( %$config );
ok(
	defined( $exact_target ),
	'Create a new Email::ExactTarget object.',
) || diag( explain( $exact_target ) );

# Get a subscriber operations object.
my $subscriber_operations = $exact_target->subscriber_operations();
isa_ok(
	$subscriber_operations,
	'Email::ExactTarget::SubscriberOperations',
	'$subscriber_operations',
);

# Retrieve the subscriber objects.
my $subscribers;
lives_ok(
	sub
	{
		$subscribers = $subscriber_operations->retrieve(
			'email' => [ keys %$test_emails ],
		);
	},
	'Retrieve subscribers.',
);

is(
	scalar( @$subscribers ),
	$valid_emails_count,
	'The number of subscribers retrieved matches the number of valid subscriber emails.',
);
subtest(
	'The objects returned are of type Email::ExactTarget::Subscriber.',
	sub
	{
		Test::More::plan( tests => scalar( @$subscribers ) );

		foreach my $subscriber ( @$subscribers )
		{
			isa_ok(
				$subscriber,
				'Email::ExactTarget::Subscriber',
				'Object returned',
			);
		}
	}
);

# Make it easier later to test individual results by accessing the objects.
# by email.
my $subscribers_by_email =
{
	map
		{ $_->get_attribute('Email Address') => $_ }
		@$subscribers
};

# Test that we retrieved the correct objects.
subtest(
	'The results have the expected Email::ExactTarget::Subscriber objects.',
	sub
	{
		Test::More::plan( tests => scalar( keys %$test_emails ) );

		while ( my ( $email, $is_valid ) = each( %$test_emails ) )
		{
			if ( $is_valid )
			{
				ok(
					defined( $subscribers_by_email->{ $email } ),
					"Subscriber object exists for $email.",
				);
			}
			else
			{
				ok(
					!exists( $subscribers_by_email->{ $email } ),
					"Invalid email $email has no Subscriber object.",
				);
			}
		}
	}
);

# Test that the ExactTarget ID is set correctly.
subtest(
	'The ID is set on the Email::ExactTarget::Subscriber objects.',
	sub
	{
		Test::More::plan( tests => scalar( @$subscribers ) );

		foreach my $subscriber ( @$subscribers )
		{
			ok(
				defined( $subscriber->id() ),
				"The subscriber ID is set.",
			);
		}
	}
);

__DATA__
#Email	Is valid?
john.q.public@example.com	1
john.doe@example.com	1
not_in_database@example.com	0
