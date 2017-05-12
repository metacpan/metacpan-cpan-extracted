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
	: plan( tests => 11 );

my $config = ExactTargetConfig->new();

# Create an object to communicate with Exact Target.
my $exact_target = Email::ExactTarget->new( %$config );
ok(
	defined( $exact_target ),
	'Create a new Email::ExactTarget object.',
) || diag( explain( $exact_target ) );

# Get a subscriber operations object.
my $subscriber_operations = $exact_target->subscriber_operations();

# Retrieve the subscriber objects.
my $subscribers = retrieve_subscribers( $subscriber_operations );

# Stage a few changes on our subscriber objects.
lives_ok(
	sub
	{
		$subscribers->{'john.q.public@example.com'}->set_attributes(
			{
				'First name' => 'Joe',
				'Last name'  => "Citizen",
			},
			is_live => 0,
		);
	},
	'Staged attribute changes on john.q.public@example.com.',
);

lives_ok(
	sub
	{
		$subscribers->{'john.doe@example.com'}->set_attributes(
			{
				'First Name' => 'Johnny',
			},
			is_live => 0,
		);
	},
	'Staged attribute changes on john.doe@example.com.',
);

# First set of updates to set up the testing environment.
lives_ok(
	sub
	{
		$subscriber_operations->update(
			[ values %$subscribers ]
		);
	},
	"Update the subscribers.",
);

# Check that there is no error on the subscriber objects.
while ( my ( $email, $subscriber ) = each %$subscribers )
{
	my $errors = $subscriber->errors();
	ok(
		!defined( $errors ),
		"The subscriber object for $email has no errors.",
	) || diag( "Errors on the subscriber object:\n" . Dumper( $errors ) );
}

# Retrieve the subscribers again to check their properties.
$subscribers = retrieve_subscribers( $subscriber_operations );

# Check that the attributes are matching the requested updates.
is(
	$subscribers->{'john.q.public@example.com'}->get_attribute( 'First name', is_live => 1 ),
	'Joe',
	"The attribute value for 'First name' of 'john.q.public\@example.com' matches.",
) || diag( 'Subscriber object: ' . Dumper( $subscribers->{'john.q.public@example.com'} ) );
is(
	$subscribers->{'john.q.public@example.com'}->get_attribute( 'Last name', is_live => 1 ),
	"Citizen",
	"The attribute value for 'Last name' of 'john.q.public\@example.com' matches.",
) || diag( 'Subscriber object: ' . Dumper( $subscribers->{'john.q.public@example.com'} ) );
is(
	$subscribers->{'john.doe@example.com'}->get_attribute( 'First name', is_live => 1 ),
	'Johnny',
	"The attribute value for 'First name' of 'john.doe\@example.com' matches.",
) || diag( 'Subscriber object: ' . Dumper( $subscribers->{'john.doe@example.com'} ) );


sub retrieve_subscribers
{
	my ( $subscriber_operations ) = @_;

	# Retrieve the subscriber objects.
	my $subscribers_list;
	lives_ok(
		sub
		{
			$subscribers_list = $subscriber_operations->retrieve(
				'email' =>
				[
					'john.q.public@example.com',
					'john.doe@example.com',
				],
			);
		},
		'Retrieve the Email::ExactTarget::Subscriber objects.',
	);

	# Return a hash associating emails with the corresponding subscriber objects.
	return
	{
		map
		{
			$_->get_attribute('Email Address') => $_
		}
		@$subscribers_list
	};
}
