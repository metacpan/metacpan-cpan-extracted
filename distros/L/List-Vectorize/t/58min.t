use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('List::Vectorize') }

is(min([1..10]), 1);
