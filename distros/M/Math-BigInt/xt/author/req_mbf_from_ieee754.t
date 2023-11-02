# -*- mode: perl; -*-

# check that requiring Math::BigFloat and then calling from_ieee754() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigFloat;

my $x = Math::BigFloat -> from_ieee754("\x3f\x40\x00\x00", "binary32");
is($x, "0.75", '$x is "0.75"');
