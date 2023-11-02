# -*- mode: perl; -*-

# check that requiring Math::BigRat and then calling bnan() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigRat;

my $x = Math::BigRat -> bnan();
is($x, 'NaN', '$x is NaN');
