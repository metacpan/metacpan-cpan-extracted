use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('List::Vectorize') }

is(mean([2, 4, 6, 8]), 5);
