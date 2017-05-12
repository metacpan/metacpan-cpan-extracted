#!/usr/bin/perl -T

# Tests use of the Pure Perl interface

use strict;
use warnings;

use Test::More;

# Cannot 'use' because we might skip tests
require Test::NoWarnings;

eval {
  require Test::Without::Module;
  require Math::Random::ISAAC::XS;
};
if ($@) {
  plan skip_all => 'Test::Without::Module and Math::Random::ISAAC::XS ' .
    'required to test fallback ability';
}

plan tests => 7;

# Delay loading of test hooks
Test::NoWarnings->import();

# Hide the XS version
Test::Without::Module->import('Math::Random::ISAAC::XS');

# Try to load Math::Random::ISAAC
eval {
  require Math::Random::ISAAC;
  Math::Random::ISAAC->import();
};
ok(!$@, 'Math::Random::ISAAC interface compiled and loaded');

my $rng = Math::Random::ISAAC->new();
isa_ok($rng, 'Math::Random::ISAAC');

ok(defined $Math::Random::ISAAC::DRIVER, 'The DRIVER is defined');
is($Math::Random::ISAAC::DRIVER, 'PP', 'Pure Perl port is loaded');
ok($rng->irand() > 0, 'Generate first integer in sequence');
ok($rng->rand()  > 0, 'Generate second number in sequence');
