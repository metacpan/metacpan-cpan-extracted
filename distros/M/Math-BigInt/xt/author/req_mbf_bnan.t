# -*- mode: perl; -*-

# check that requiring Math::BigFloat and then calling bnan() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigFloat;

my $x = Math::BigFloat -> bnan();
is($x, 'NaN', '$x is NaN');
