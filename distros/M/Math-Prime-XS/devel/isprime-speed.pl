#!/usr/bin/perl -w

use 5.004;
use Devel::TimeThis;
use Math::Prime::XS ':all';

print "Math::Prime::XS version ",Math::Prime::XS->VERSION,"\n";

{ package Math::Prime::XS;
  sub is_prime_using_mod_primes {
    # sub {} due to extra stack_skip level
    sub { validate_pos(@_, 1) }->(@_);
    _validate(@_);
    return defined &xs_mod_primes(($_[0])x2) ? true : false;
  }
}
*is_prime_using_mod_primes = \&Math::Prime::XS::is_prime_using_mod_primes;

my $limit = 50000;
{
  my $t = Devel::TimeThis->new('using xs_mod_primes()');
  for (my $i = 1; $i < $limit; $i += 2) {
    is_prime_using_mod_primes($i) || 1;
  }
}
{
  my $t = Devel::TimeThis->new('using is_prime()');
  for (my $i = 1; $i < $limit; $i += 2) {
    is_prime($i) || 1;
  }
}
exit 0;
