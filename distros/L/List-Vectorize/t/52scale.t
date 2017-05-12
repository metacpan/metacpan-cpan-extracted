use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok('List::Vectorize') }

my $x = [1..10];
my $y = scale($x);
is(($y->[0] + 1.48630108 > 0.0001)+0, 0);

$y = scale($x, "zvalue");
is(($y->[0] + 1.48630108 > 0.0001)+0, 0);

$y = scale($x, "percentage");
is(($y->[1] - 0.11111111 > 0.0001)+0, 0);

$y = scale($x, "sphere");
is(($y->[0] - 0.0509647 > 0.0001)+0, 0);
