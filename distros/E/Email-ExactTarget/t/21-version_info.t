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

my $response_data;
lives_ok(
	sub
	{
		$response_data = $exact_target->version_info();
	},
	'Retrieve version info.',
);

isnt(
	$response_data,
	undef,
	'Response is not empty.',
) || diag( explain( $response_data ) );

my $version = $response_data;
ok(
	defined( $version ) && ( $version ne '' ),
	'The version is defined.',
) || diag( explain( $response_data ) );
diag( "ExactTarget's webservice reports version $version." );
