# -*- mode: perl; -*-

# check that requiring Math::BigRat and then calling bzero() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigRat;

my $x = Math::BigRat -> bzero();
is($x, '0', '$x is 0');
