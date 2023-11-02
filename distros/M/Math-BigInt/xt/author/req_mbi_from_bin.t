# -*- mode: perl; -*-

# check that requiring Math::BigInt and then calling from_bin() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigInt;

my $x = Math::BigInt -> from_bin(1);
is($x, '1', '$x is 1');
