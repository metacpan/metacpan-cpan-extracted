use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('List::Vectorize') }

is(iqr([1..10]), 4.5);
is(iqr([1,2,2,2,3,3,3,4,5,6,6,7,8]), 4);
