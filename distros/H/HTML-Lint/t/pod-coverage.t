#!perl -Tw

use warnings;
use strict;

use Test::More;
if ( !eval 'use Test::Pod::Coverage 1.04; 1;' ) {   ## no critic ( BuiltinFunctions::ProhibitStringyEval )
    plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage';
}

all_pod_coverage_ok();
