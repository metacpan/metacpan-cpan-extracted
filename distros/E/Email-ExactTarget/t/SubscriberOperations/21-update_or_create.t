#!perl -T

use strict;
use warnings;

use Data::Dumper;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More;

use Email::ExactTarget;
use Email::ExactTarget::Subscriber;


eval 'use ExactTargetConfig';
$@
	? plan( skip_all => 'Local connection information for ExactTarget required to run tests.' )
	: plan( tests => 9 );

my $config = ExactTargetConfig->new();
my $test_list_ids = ExactTargetConfig->get_test_list_ids();

# Create an object to communicate with Exact Target.
my $exact_target = Email::ExactTarget->new( %$config );
ok(
	defined( $exact_target ),
	'Create a new Email::ExactTarget object.',
) || diag( explain( $exact_target ) );

# Get a subscriber operations object.
ok(
	my $subscriber_operations = $exact_target->subscriber_operations(),
	"Subscriber operations object retrieved.",
);

# Create new Subscriber objects.
my $subscribers = [];

# (this one should already exist, per our previous tests)
ok(
	my $subscriber1 = Email::ExactTarget::Subscriber->new(),
	'Created Email::ExactTarget::Subscriber object.',
);
lives_ok(
	sub
	{
		$subscriber1->set_attributes(
			{
				'First Name'    => 'John Q.',
				'Last Name'     => 'Public',
				'Email Address' => 'john.q.public@example.com',
			},
			'is_live' => 0,
		);
		$subscriber1->set_lists_status(
			{
				$test_list_ids->[0] => 'Active',
			},
			'is_live' => 0,
		);
	},
	'Staged changes on the first subscriber.',
);
push( @$subscribers, $subscriber1 );

# (this one will be new)
ok(
	my $subscriber2 = Email::ExactTarget::Subscriber->new(),
	'Created Email::ExactTarget::Subscriber object.',
);
lives_ok(
	sub
	{
		$subscriber2->set_attributes(
			{
				'First Name'    => 'John',
				'Last Name'     => 'Doe',
				'Email Address' => 'john.doe@example.com',
			},
			'is_live' => 0,
		);
		$subscriber2->set_lists_status(
			{
				$test_list_ids->[1] => 'Active',
			},
			'is_live' => 0,
		);
	},
	'Staged changes on the second subscriber.',
);
push( @$subscribers, $subscriber2 );

# First set of updates to set up the testing environment.
lives_ok(
	sub
	{
		$subscriber_operations->update_or_create( $subscribers );
	},
	"No error found when updating/creating the objects.",
);

# Check that there is no error on the subscriber objects.
foreach my $subscriber ( @$subscribers )
{
	ok(
		!defined( $subscriber->errors() ),
		"No error found on the subscriber object.",
	) || diag( "Errors on the subscriber object:\n" . Dumper( $subscriber->errors() ) );
}
