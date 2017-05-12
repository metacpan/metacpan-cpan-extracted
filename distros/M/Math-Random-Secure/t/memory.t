#!/usr/bin/perl

#  Tests that there are no memory leaks.
#  Taken from the Math::Random::ISAAC tests under the public domain
#  license.

use strict;
use warnings;
use Test::More;
use Math::Random::Secure;

if (exists($INC{'Devel/Cover.pm'})) {
  plan skip_all => 'This test is not compatible with Devel::Cover';
}

eval {
  require Test::LeakTrace;
};
if ($@) {
  plan skip_all => 'Test::LeakTrace required to test memory leaks';
}

plan tests => 3;

Test::LeakTrace->import;

no_leaks_ok(sub {
  for (0..10) {
    Math::Random::Secure::srand();
  }
}, 'srand does not leak memory');

no_leaks_ok(sub {
  for (0..30) {
    Math::Random::Secure::irand();
  }
}, 'irand does not leak memory');

no_leaks_ok(sub {
  for (0..30) {
    Math::Random::Secure::rand();
  }
}, 'rand does not leak memory');
