use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok('List::Vectorize') }

is(is_empty([1..10]), 0);
is(is_empty([]), 1);
is(is_empty({a => 1, b => 2}), 0);
is(is_empty({}), 1);
is(is_empty(1), 0);
is(is_empty(undef), 1);
