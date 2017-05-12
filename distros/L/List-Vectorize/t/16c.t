use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('List::Vectorize') }

my $a = c(1, 2, 3);
my $b = c([1..5], [6..8]);
my $c = c(4, [3..7], 7);

is_deeply($a, [1, 2, 3]);
is_deeply($b, [1..8]);
is_deeply($c, [4, 3, 4, 5, 6, 7, 7]);
