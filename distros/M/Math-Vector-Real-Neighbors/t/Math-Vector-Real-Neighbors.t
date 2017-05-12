#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Test::More;

eval { require Math::Vector::Real::Random };
if ($@) {
    plan skip_all => "Math::Vector::Real::Random failed to load: $@";
}
else {
    plan tests => 1;
}

use Math::Vector::Real;
use Math::Vector::Real::Neighbors;

my @p = map { Math::Vector::Real->random_normal(5) } 1..300;

my @n = Math::Vector::Real::Neighbors->neighbors(@p);
my @nbf = Math::Vector::Real::Neighbors->neighbors_bruteforce(@p);

is("@n", "@nbf");
