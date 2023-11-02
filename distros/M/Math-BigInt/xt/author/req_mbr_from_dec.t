# -*- mode: perl; -*-

# check that requiring Math::BigRat and then calling from_dec() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigRat;

my $x = Math::BigRat -> from_dec(1);
is($x, '1', '$x is 1');
