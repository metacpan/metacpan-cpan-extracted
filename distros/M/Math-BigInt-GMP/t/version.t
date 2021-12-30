# -*- mode: perl; -*-

use strict;
use warnings;
use Test::More tests => 1;

use Math::BigInt::GMP;

ok( Math::BigInt::GMP::gmp_version() );

note Math::BigInt::GMP::gmp_version();

done_testing;
