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
	: plan( tests => 8 );

my $config = ExactTargetConfig->new();

# Retrieve the list of addresses to use for testing.
my $emails_to_delete = [];
foreach my $line ( <DATA> )
{
	chomp( $line );
	next if !defined( $line ) || substr( $line, 0, 1 ) eq '#' || $line !~ /\w/;
	push( @$emails_to_delete, $line );
}
isnt(
	scalar( @$emails_to_delete ),
	0,
	'Find emails to delete.'
);

# Create an object to communicate with Exact Target.
my $exact_target = Email::ExactTarget->new( %$config );
ok(
	defined( $exact_target ),
	'Create a new Email::ExactTarget object.',
) || diag( explain( $exact_target ) );

# Get a subscriber operations object.
my $subscriber_operations = $exact_target->subscriber_operations();

# Retrieve the subscriber objects.
my $subscribers = retrieve_subscribers(
	$subscriber_operations,
	$emails_to_delete,
);

# Delete the subscribers.
my $all_subscribers_deleted;
lives_ok(
	sub
	{
		$all_subscribers_deleted = $subscriber_operations->delete_permanently(
			[ values %$subscribers ],
		);
	},
	"Delete the subscribers.",
);
ok(
	$all_subscribers_deleted,
	'No error is found when processing the output of the entire batch.',
);

# Check that there's errors on the subscriber objects only when the email
# did not exist in the database.
subtest(
	'The subscriber objects have no errors.',
	sub
	{
		while ( my ( $email, $subscriber ) = each %$subscribers )
		{
			my $errors = $subscriber->errors();
			my $email = $subscriber->get_attribute( 'Email Address' );
			ok(
				!defined( $errors ),
				"The subscriber object for $email has no errors.",
			) || diag( "Errors on the subscriber object:\n" . Dumper( $errors ) );
		}
	}
);

# Retrieve the subscribers again. Now that we've deleted them all, there should
# be no result.
$subscribers = retrieve_subscribers(
	$subscriber_operations,
	$emails_to_delete,
);
is(
	scalar( keys %$subscribers ),
	0,
	"The subscribers do not exist in ExactTarget's database anymore.",
);


sub retrieve_subscribers
{
	my ( $subscriber_operations, $emails_to_delete ) = @_;

	# Retrieve the subscriber objects.
	my $subscribers_list;
	lives_ok(
		sub
		{
			$subscribers_list = $subscriber_operations->retrieve(
				'email' => $emails_to_delete,
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


__DATA__
# Email to delete
john.q.public@example.com
john.doe@example.com
john.public@example.com
