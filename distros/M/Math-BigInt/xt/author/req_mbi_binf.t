# -*- mode: perl; -*-

# check that requiring Math::BigInt and then calling binf() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigInt;

my $x = Math::BigInt -> binf();
is($x, 'inf', '$x is inf');
