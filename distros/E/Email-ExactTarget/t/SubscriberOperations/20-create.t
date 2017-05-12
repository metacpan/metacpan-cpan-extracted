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
	: plan( tests => 4 );

my $config = ExactTargetConfig->new();
my $all_subscribers_list_id = ExactTargetConfig->get_all_subscribers_list_id();

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

my $subscriber = Email::ExactTarget::Subscriber->new();
$subscriber->set_attributes(
	{
		'First Name'    => 'John',
		'Last Name'     => 'Public',
		'Email Address' => 'john.public@example.com',
	},
	is_live => 0,
);
$subscriber->set_lists_status(
	{
		$all_subscribers_list_id => 'Active',
	},
	is_live => 0,
);
push( @$subscribers, $subscriber );

# First set of updates to set up the testing environment.
lives_ok(
	sub
	{
		$subscriber_operations->create( $subscribers );
	},
	"Create the subscribers.",
);

# Check that there is no error on the subscriber objects.
foreach my $subscriber ( @$subscribers )
{
	ok(
		!defined( $subscriber->errors() ),
		"No error found on the subscriber object.",
	) || diag( "Errors on the subscriber object:\n" . Dumper( $subscriber->errors() ) );
}
