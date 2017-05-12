use strict;
use warnings;

use Benchmark qw/cmpthese/;
use ExtUtils::testlib;
use Math::Random::ISAAC;
use Math::Random::MT;
use Math::Random::Xorshift;

my $time = time;
srand($time);

my $isaac = Math::Random::ISAAC->new($time);
my $mt = Math::Random::MT->new($time);

Math::Random::Xorshift::srand($time);
my $xor = Math::Random::Xorshift->new($time);

cmpthese(-1, {
  'CORE::rand' => sub { rand },
  # M::R::MT and M::R::ISAAC's functional interface just calls private object's
  # method in Perl level, so there's no performance advantage.
  'M::R::ISAAC#irand' => sub { $isaac->irand },
  'M::R::ISAAC#rand' => sub { $isaac->rand },
  'M::R::MT#rand' => sub { $mt->rand }, # M::R::MT doesn't provide irand() method
  'M::R::Xorshift#irand' => sub { $xor->irand },
  'M::R::Xorshift#rand' => sub { $xor->rand },
  'M::R::Xorshift::irand' => sub { Math::Random::Xorshift::irand },
  'M::R::Xorshift::rand' => sub { Math::Random::Xorshift::rand }
});
