use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('List::Vectorize') }

is(sign(2), 1);
is(sign(0), 0);
is(sign(-2), -1);
