# -*- mode: perl; -*-

# check that requiring Math::BigRat and then calling from_ieee754() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigRat;

my $x = Math::BigRat -> from_ieee754("\x3f\x40\x00\x00", "binary32");
is($x, "3/4", '$x is "3/4"');
