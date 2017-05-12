use strict;
use warnings;

use lib 't/lib';

use Test::More 0.96;

BEGIN {
    eval 'require List::SomeUtils';
    if ($@) {
        plan skip_all => 'These tests require that List::SomeUtils already be installed';
    }
}
BEGIN { $ENV{LIST_SOMEUTILS_IMPLEMENTATION} = 'XS' }

use LSU::Test::Functions;
LSU::Test::Functions->run_tests;

