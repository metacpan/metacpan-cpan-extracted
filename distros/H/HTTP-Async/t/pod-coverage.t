use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage 1.00;";
plan skip_all => "Test::Pod::Coverage > 1.00 required" if $@;

if ( $] >= 5.009 ) {
    eval "use Pod::Coverage 0.19;";
    plan skip_all => "Pod::Coverage >= 0.19 required for perls >= 5.9" if $@;
}

all_pod_coverage_ok();
