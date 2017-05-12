use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('List::Vectorize') }

my $m = [[1,2,3],
         [4,5,6]];
my @dim = dim($m);
is($dim[0], 2);
is($dim[1], 3);

is(dim([[1,2], [3, 4, 5]]), undef);

