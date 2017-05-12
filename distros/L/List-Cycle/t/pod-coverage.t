#!perl -T

use warnings;
use strict;

use Test::More;

if ( eval 'use Test::Pod::Coverage 1.04; 1;' ) { ## no critic (ProhibitStringyEval)
    all_pod_coverage_ok();
}
else {
    plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD';
}
