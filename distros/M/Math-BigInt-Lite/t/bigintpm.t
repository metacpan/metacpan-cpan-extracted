# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 4280;

use Math::BigInt::Lite;

our ($CLASS, $LIB);
$CLASS = "Math::BigInt::Lite";
$LIB   = "Math::BigInt::Calc";  # for Math::BigInt, not Math::BigInt::Lite!

#############################################################################
# all the other tests

require './t/bigintpm.inc';             # all tests here for sharing
