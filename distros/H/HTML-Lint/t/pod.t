#!perl -Tw

use strict;
use warnings;

use Test::More;

if ( !eval 'use Test::Pod 1.14; 1;' ) { ## no critic ( BuiltinFunctions::ProhibitStringyEval )
    plan skip_all => 'Test::Pod 1.14 required for testing POD';
}

all_pod_files_ok();
