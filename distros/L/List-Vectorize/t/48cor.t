use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('List::Vectorize') }

my $x = [1, 4, 2, 5, 3, 7, 2];
my $y = [4, 2, 4, 1, 9, 3, 0];

is( (cor($x, $y) + 0.1610632 > 0.0001) + 0, 0);
is( (cor($x, $y, "spearman") + 0.263636 > 0.0001) + 0, 0);


