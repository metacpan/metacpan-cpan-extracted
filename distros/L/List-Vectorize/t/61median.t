use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('List::Vectorize') }

is(median([0..10]), 5);
is(median([1..10]), 5.5);