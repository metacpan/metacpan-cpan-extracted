use strict;
use warnings;
use Test::More tests => 8;

BEGIN { use_ok('List::Vectorize') }

my $w = which([0, 0, 1, 1, 0, 1]);

is_deeply($w, [2, 3, 5]);

is(all([1, 1, 1, 1, 1]), 1);
is(all([1, 0, 1, 0, 1]), 0);
is(all([]), 0);
is(any([0, 0, 0, 0, 0]), 0);
is(any([1, 0, 1, 0, 1]), 1);
is(any([]), 0);

