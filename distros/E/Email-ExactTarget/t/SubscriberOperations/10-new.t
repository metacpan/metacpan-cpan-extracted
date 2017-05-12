#!perl -T

use strict;
use warnings;

use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More;

use Email::ExactTarget;


eval 'use ExactTargetConfig';
$@
	? plan( skip_all => 'Local connection information for ExactTarget required to run tests.' )
	: plan( tests => 4 );

my $config = ExactTargetConfig->new();

# Create an object to communicate with Exact Target
my $exact_target = Email::ExactTarget->new( %$config );
ok(
	defined( $exact_target ),
	'Create a new Email::ExactTarget object.',
) || diag( explain( $exact_target ) );

# Get a subscriber operations object.
can_ok(
	$exact_target,
	'subscriber_operations',
);
my $subscriber_operations;
lives_ok(
	sub
	{
		$subscriber_operations = $exact_target->subscriber_operations();
	},
	'Retrieve a SubscriberOperations object.',
);
isa_ok(
	$subscriber_operations,
	'Email::ExactTarget::SubscriberOperations',
	'The object returned by subscriber_operations()',
);

