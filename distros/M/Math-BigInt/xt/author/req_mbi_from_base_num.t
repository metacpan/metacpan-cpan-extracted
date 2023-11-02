# -*- mode: perl; -*-

# check that requiring Math::BigInt and then calling from_base_num() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigInt;

my $x = Math::BigInt -> from_base_num([1], 10);
is($x, 1, '$x is 1');
