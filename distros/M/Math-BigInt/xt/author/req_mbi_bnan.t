# -*- mode: perl; -*-

# check that requiring Math::BigInt and then calling bnan() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigInt;

my $x = Math::BigInt -> bnan();
is($x, 'NaN', '$x is NaN');
