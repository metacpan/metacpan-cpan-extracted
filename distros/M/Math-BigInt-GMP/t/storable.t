#!perl

use strict;
use warnings;
use Test::More tests => 1;

use Math::BigInt::GMP;

use Storable qw(freeze thaw);

my $num = Math::BigInt::GMP->_new(42);

my $serialised = freeze $num;
my $cloned = thaw $serialised;

ok(!Math::BigInt::GMP->_acmp($cloned, $num));
