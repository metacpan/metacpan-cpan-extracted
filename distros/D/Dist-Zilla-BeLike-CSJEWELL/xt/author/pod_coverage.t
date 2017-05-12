#!perl

# Test that modules are documented by their pod.

use strict;

sub filter {
	my $module = shift;
	
	return 0 if $module =~ m/auto::share/;
	return 1;
}

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

# If using Moose, uncomment the appropriate lines below.
my @MODULES = (
	'Pod::Coverage::TrustPod 0.092830',
	'Pod::Coverage 0.21',
	'Test::Pod::Coverage 1.08',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

my @modules = all_modules();
my @modules_to_test = sort { $a cmp $b } grep { filter($_) } @modules;
my $test_count = scalar @modules_to_test;
plan tests => $test_count;

foreach my $module (@modules_to_test) {
	pod_coverage_ok($module, { 
		coverage_class => 'Pod::Coverage::TrustPod', 
		also_private => [ qr/^[A-Z_]+$/ ],
	});
}

