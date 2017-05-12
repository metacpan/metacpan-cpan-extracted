use strict;
use warnings;
use Test::More;

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@; 

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";

if ( $@ ) { 
        plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
}
else {
        plan tests => 1 
}

pod_coverage_ok( 'IBM::SONAS',				{ also_private => [ 'export', 'get_export',
									    'health', 'get_health', 
									    'quota', 'get_quota',
									    'snapshot', 'get_snapshot' ] } );
done_testing;
