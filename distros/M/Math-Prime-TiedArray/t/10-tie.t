#!perl -T

use Test::More tests => 1;
use Math::Prime::TiedArray;
use strict;

ok( tie my @a, "Math::Prime::TiedArray" );
