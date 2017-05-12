use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('List::Vectorize') }

is(sd([2, 4, 6]), 2);
is(sd([2, 4, 6], 4), 2);
