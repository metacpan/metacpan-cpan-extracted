
use strict;
use warnings;

use Test::More tests => 4;
use Math::Goedel qw/goedel/;

is(goedel(9), 512);
is(goedel(81), 768);
is(goedel(230), 108);

eval "enc(9)";
ok($@);

