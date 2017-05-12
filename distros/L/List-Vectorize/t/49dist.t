use strict;
use warnings;
use Test::More tests => 6;

BEGIN { use_ok('List::Vectorize') }

my $x = [1, 4, 2, 5, 3, 7, 2];
my $y = [4, 2, 4, 1, 9, 3, 0];

is((dist($x, $y) - 19.51922 > 0.0001)+0, 0);
is((dist($x, $y, "euclidean") - 19.51922 > 0.0001)+0, 0);
is((dist($x, $y, "pearson") - 1.16106 > 0.0001)+0, 0);
is((dist($x, $y, "spearman") - 1.263636 > 0.0001)+0, 0);

$x = [1, 0, 0, 1, 1, 0, 1];
$y = [0, 0, 1, 1, 1, 1, 0];
is((dist($x, $y, "logical") - 0.3333333 > 0.0001)+0, 0);
