use strict;
use warnings;
use utf8;

use Test::More;

if ( not $ENV{AUTHOR_TESTING} ) {
    my $msg = 'Set $ENV{AUTHOR_TESTING} to run author tests.';
    plan( skip_all => $msg );
}

if ( !eval { require Test::Pod::Coverage; 1 } ) {
    plan skip_all => q{Test::Pod::Coverage required for testing POD coverage};
}
Test::Pod::Coverage::all_pod_coverage_ok();
