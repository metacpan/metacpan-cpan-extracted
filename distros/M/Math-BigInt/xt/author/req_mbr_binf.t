# -*- mode: perl; -*-

# check that requiring Math::BigRat and then calling binf() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigRat;

my $x = Math::BigRat -> binf();
is($x, 'inf', '$x is inf');
