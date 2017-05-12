#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;


unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;

{ 
    ## no critic
    eval "use Test::Pod::Coverage $min_tpc";
}
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
{ 
    ## no critic
    eval "use Pod::Coverage $min_pc";
}

plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

pod_coverage_ok(
    'Logging::Simple',
    { also_private => [ qr/(?:crit|emerg|err|warn)/ ], },
    "short level method names private",
);

done_testing();
