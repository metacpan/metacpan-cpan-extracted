# -*- mode: perl; -*-

# check that requiring Math::BigInt and then calling bone() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigInt;

my $x = Math::BigInt -> bone();
is($x, '1', '$x is 1');
