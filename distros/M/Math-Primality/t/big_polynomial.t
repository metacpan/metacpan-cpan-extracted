#!/usr/bin/evn perl

use strict;
use warnings;
use Test::More;
#use Carp::Always;

use Math::GMPz qw/:mpz/;

BEGIN {
  use_ok ('Math::Primality::BigPolynomial' );
}


my $b = Math::Primality::BigPolynomial->new([1,3,7]);
isa_ok($b, 'Math::Primality::BigPolynomial');

is($b->getCoef(0), 1, 'coef(0) is 1');
is($b->getCoef(1), 3, 'coef(1) is 3');
is($b->getCoef(2), 7, 'coef(2) is 7');
# this is a bit wonky
cmp_ok($b->getCoef(3),'==', Math::GMPz->new(0), 'coef(3) is 0');
is($b->getCoef(-1), undef, 'coef(-1) is undef');
is($b->getCoef(-10), undef, 'coef(-10) is undef');

done_testing;
