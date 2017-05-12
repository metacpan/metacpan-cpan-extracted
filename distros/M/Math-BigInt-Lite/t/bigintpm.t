#!perl

use strict;
use warnings;

use Test::More tests => 3913;

use Math::BigInt::Lite;

our ($CLASS, $CALC);
$CLASS = "Math::BigInt::Lite";
$CALC  = "Math::BigInt::Calc";

#############################################################################
# all the other tests

require 't/bigintpm.inc';               # all tests here for sharing
