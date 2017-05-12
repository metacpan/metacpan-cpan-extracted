use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok('List::Vectorize') }

is(len([1..10]), 10);
is(len({a => 1, b => 2}), 2);
is(len(1), 1);
is(len(undef), 0);
