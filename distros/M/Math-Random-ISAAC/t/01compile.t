#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings; # 1 test

# Check that we can load the module
BEGIN {
  use_ok('Math::Random::ISAAC::PP');
  use_ok('Math::Random::ISAAC');
}
