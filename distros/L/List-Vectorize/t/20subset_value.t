use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('List::Vectorize') }

my $x = [10..20];
subset_value($x, [1, 2, 5], 0);
is_deeply($x, [10, 0, 0, 13, 14, 0, 16, 17, 18, 19, 20]);

$x = [10..20];
subset_value($x, [1, 2, 5], [1, 1, 1]);
is_deeply($x, [10, 1, 1, 13, 14, 1, 16, 17, 18, 19, 20]);

$x = [10..20];
subset_value($x, sub {$_[0] > 15}, 2);
is_deeply($x, [10, 11, 12, 13, 14, 15, 2, 2, 2, 2, 2]);

