# -*- mode: perl; -*-

# check that requiring Math::BigInt and then calling bzero() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigInt;

my $x = Math::BigInt -> bzero();
is($x, '0', '$x is 0');
