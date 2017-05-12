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
	: plan( tests => 5 );

my $config = ExactTargetConfig->new();

# Create an object to communicate with Exact Target
my $exact_target = Email::ExactTarget->new( %$config );
ok(
	defined( $exact_target ),
	'Create a new Email::ExactTarget object.',
) || diag( explain( $exact_target ) );

my $response_data;
lives_ok(
	sub
	{
		$response_data = $exact_target->get_system_status();
	},
	'Retrieve system status.',
);

ok(
	defined( $response_data ),
	'The response is not empty.',
) || diag( explain( $response_data ) );

ok(
	defined( $response_data->{'StatusCode'} )
	&& defined( $response_data->{'SystemStatus'} )
	&& defined( $response_data->{'StatusMessage'} ),
	"The response is correctly formatted.",
) || diag( explain( $response_data ) );

like(
	$response_data->{'SystemStatus'} || '',
	qr/^(OK|InMaintenance|UnplannedOutage)$/,
	'The System Status value is one of the expected values.',
) || diag( explain( $response_data ) );

my $system_status = defined( $response_data->{'SystemStatus'} )
	? $response_data->{'SystemStatus'}
	: '(undef)';

diag( "System status is $system_status." );

