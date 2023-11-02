# -*- mode: perl; -*-

# check that requiring Math::BigFloat and then calling bpi() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigFloat;

my $x = Math::BigFloat -> bpi();
is($x, "3.141592653589793238462643383279502884197",
   '$x is "3.141592653589793238462643383279502884197"');
