# -*- mode: perl; -*-

# check that requiring Math::BigFloat and then calling bzero() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigFloat;

my $x = Math::BigFloat -> bzero();
is($x, '0', '$x is 0');
