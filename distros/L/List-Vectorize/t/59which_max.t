use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('List::Vectorize') }

is(which_max([1..10]), 9);
