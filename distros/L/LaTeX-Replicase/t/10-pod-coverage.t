use 5.010;
use strict;
use warnings;

use utf8;

use Test::More;
use Test::More::UTF8;

unless ( $ENV{RELEASE_TESTING} ) {
	plan skip_all => "Author tests not required for installation. Test only run when called with RELEASE_TESTING=1";
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc not installed and required for testing POD coverage"
	if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc not installed and required for testing POD coverage"
	if $@;

all_pod_coverage_ok();
