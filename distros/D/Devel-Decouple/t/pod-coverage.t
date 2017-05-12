use strict;
use warnings;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Pod::Coverage; };

if ( $@ ) {
    my $msg = 'Test::Pod::Coverage is required to test POD coverage.';
    plan( skip_all => $msg );
}

Test::Pod::Coverage::all_pod_coverage_ok();
