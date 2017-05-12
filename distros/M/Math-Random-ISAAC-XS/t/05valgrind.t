#!/usr/bin/perl

# Checks for memory leaks using valgrind

use strict;
use warnings;

use Test::More;

unless ($ENV{TEST_VALGRIND}) {
  plan skip_all => 'Set TEST_VALGRIND to enable memory leak tests';
}

eval {
  require Test::Valgrind; # 5 tests
};
if ($@) {
  plan skip_all => 'Test::Valgrind required to test memory leaks';
}

use Math::Random::ISAAC::XS ();

Test::Valgrind->import(diag => 1);

my $rng = Math::Random::ISAAC::XS->new(time);
$rng->irand() for (0..10);
$rng->rand() for (0..10);
