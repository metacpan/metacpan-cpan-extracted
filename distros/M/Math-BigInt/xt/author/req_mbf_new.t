# -*- mode: perl; -*-

# check that requiring Math::BigFloat and then calling new() works

use strict;
use warnings;

use Test::More tests => 1;

require Math::BigFloat;

my $x = Math::BigFloat -> new(2);
is($x, '2', '$x is 2');
