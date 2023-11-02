# -*- mode: perl; -*-

# check that requiring Math::BigRat and then calling bone() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigRat;

my $x = Math::BigRat -> bone();
is($x, '1', '$x is 1');
