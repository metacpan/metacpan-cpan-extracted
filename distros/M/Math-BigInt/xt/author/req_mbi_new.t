# -*- mode: perl; -*-

# check that requiring Math::BigInt and then calling new() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigInt;

my $x = Math::BigInt -> new(2);
is($x, '2', '$x is 2');
