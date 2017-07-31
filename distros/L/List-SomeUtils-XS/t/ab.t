use strict;
use warnings;

use lib 't/lib';

use Test::More 0.96;

BEGIN {
    eval 'use List::SomeUtils 0.56';
    if ($@) {
        plan skip_all => 'These tests require that List::SomeUtils 0.56 already be installed';
    }
}
BEGIN { $ENV{LIST_SOMEUTILS_IMPLEMENTATION} = 'XS' }

use LSU::Test::ab;
LSU::Test::ab->run_tests;

