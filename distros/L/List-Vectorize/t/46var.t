use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('List::Vectorize') }

is(var([2, 4, 6]), 4);
is(var([2, 4, 6], 4), 4);
