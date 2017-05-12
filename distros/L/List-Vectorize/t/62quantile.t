use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok('List::Vectorize') }

my $x = [0..10];
my $q = quantile($x);

is($q->[1], 2.5);

$q = quantile($x, 0.3);

is($q, 3);

$q = quantile($x, [0.1, 0.2]);
is($q->[0], 1);

$x = quantile([1,2,46,3,2,77,4]);
is($x->[1], 2);
is($x->[2], 3);
is($x->[3], 25);

