use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('List::Vectorize') }

my $x = [10..20];

is_deeply(subset($x, [1, 2, 5]), [11, 12, 15]);
is_deeply(subset($x, [-1, -2, -5]), [12, 13, 15, 16, 17, 18, 19, 20]);
is_deeply(subset($x, sub {$_[0] > 15}), [16, 17, 18, 19, 20]);
