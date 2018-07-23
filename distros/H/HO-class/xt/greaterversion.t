#!/usr/bin/perl

# Test if version increments
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

my @MODULES = (
	'Test::GreaterVersion 0.01',
	'CPAN::Meta' => 0
);

# Don't run tests during end-user installs
use Test::More;
plan( skip_all => 'Author tests not required for installation' )
	unless ( $ENV{RELEASE_TESTING} or $ENV{AUTOMATED_TESTING} );

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		$ENV{RELEASE_TESTING}
		? die( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}



has_greater_version('HO::class');
 
has_greater_version_than_cpan('HO::class');

my $meta = CPAN::Meta->load_file('META.yml');

use HO::class;

is($HO::class::VERSION, $meta->version,'Version updated');

done_testing();

1;
