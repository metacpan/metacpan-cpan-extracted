# -*- mode: perl; -*-

# check that requiring Math::BigInt and then calling bpi() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigInt;

my $x = Math::BigInt -> bpi();
is($x, 3, '$x is 3');
