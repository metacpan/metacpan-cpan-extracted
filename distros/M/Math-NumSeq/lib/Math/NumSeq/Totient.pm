# Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.


package Math::NumSeq::Totient;
use 5.004;
use strict;
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099
use Math::Factor::XS 'factors';

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::PrimeFactorCount;;
*_prime_factors = \&Math::NumSeq::PrimeFactorCount::_prime_factors;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Totient');
use constant description => Math::NumSeq::__('Euler totient function, the count of how many numbers coprime to N.');
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;
use constant values_min => 1;
use constant default_i_start => 1;

#------------------------------------------------------------------------------
# cf A007617 non-totients, all odds, plus evens per A005277
#    A005277 even non-totients, n s.t. n==phi(something) no solution
#    A058980 non-totients 0mod4
#    A056595 - sum non-square divisors
#    A007614 totients ascending, with multiplicity

# Dressler (1970) N(x) = num phi(n)<=x, then N(x)/x -> A
# A = zeta(2)*zeta(3)/zeta(6) = product primes 1+1/(p*(p-1))
#
# 2p is a non-totient if 2p+1 composite (p not an S-G prime)
# 4p is a non-totient iff 2p+1 and 4p+1 both composite
# if n non-totient and 2n+1 composite then 2n also non-totient
#
use constant oeis_anum => 'A000010';

sub ith {
  my ($self, $i) = @_;
  return _totient($i);
}
sub _totient {
  my ($n) = @_;
  ### _totient(): $n

  if (_is_infinite($n)) {
    return $n;
  }
  if ($n == 0) {
    return 0;
  }
  my ($good, @primes) = _prime_factors($n);
  return undef unless $good;

  my $prev = 0;
  my $ret = 1;
  foreach my $p (@primes) {
    if ($p == $prev) {
      $ret *= $p;
    } else {
      $ret *= $p - 1;
      $prev = $p;
    }
  }
  return $ret;
}

# totient(x)=p^a.q^b.r^c=n
# seek a prime w for x with w-1 dividing in n
# combinations of the primes of n to make w-1
#
# factor 2*f of n, arising from prime 2*f+1
#
# 8 arises from totient(15=3*5) = (3-1)*(5-1)=2*4
# 484=2*2*11*11   2*11=23 prime
#
sub pred {
  my ($self, $value) = @_;
  ### Totient pred(): $value

  if ($value <= 1) {
    return ($value == 1); # $value==0 no, $value==1 yes
  }
  if ($value % 2) {
    ### no because odd ...
    return 0;
  }
  unless ($value <= 0xFFFF_FFFF) {
    return undef;
  }
  $value = "$value"; # numize any Math::BigInt for factors()
  if (_pred_f($value,$value)) {
    return 1;
  }
  return 0;
}
sub _pred_f {
  my ($n, $prev_factor) = @_;
  ### _pred_f(): "n=$n  prev=$prev_factor"

  if ($n & 1) {
    ### no odd ...
    return 0;
  }

  $n >>= 1;
  ### halved: $n
  if ($n == 1) {
    return 1;  # totient(3)=2 occurs
  }

  foreach my $f (1, factors($n)) {
    ### at: "n=$n f=$f"
    if ($f >= $prev_factor) {
      ### f too big, chop search ...
      return 0;
    }
    my $p = 2*$f+1;
    ### $p

    my $r = $n / $f;
    ### divide out: "f=$f to r=$r"

    unless (is_prime($p)) {
      ### no, not prime ...
      next;
    }

    for (;;) {
      if (_pred_f ($r, $f)) {  # recurse
        return 1;
      }
      if ($r % $p) {
        last;
      }
      if ($r == $p) {
        return 1;
      }
      $r /= $p;
      ### divide out prime: "p=$p to r=$r"
    }
  }

  ### whole: "n=$n  p=".(2*$n+1)
  if ($n >= $prev_factor) {
    ### f too big, chop search ...
    return 0;
  }
  return is_prime(2*$n+1);
}


# sub _totient {
#   my ($x) = @_;
#   my $count = (($x >= 1)                    # y=1 always
#                + ($x > 2 && ($x&1))         # y=2 if $x odd
#                + ($x > 3 && ($x % 3) != 0)  # y=3
#                + ($x > 4 && ($x&1))         # y=4 if $x odd
#               );
#   for (my $y = 5; $y < $x; $y++) {
#     $count += _coprime($x,$y);
#   }
#   return $count;
# }
# sub _coprime {        # for x<y
#   my ($x, $y) = @_;
#   #### _coprime(): "$x,$y"
#   if ($y > $x) {
#     return 0;
#   }
#   for (;;) {
#     if ($y <= 1) {
#       return ($y == 1);
#     }
#     ($x,$y) = ($y, $x % $y);
#   }
# }


1;
__END__

=for stopwords Ryde Math-NumSeq Euler's totient totients coprime coprimes ie recursing maxdivisor

=head1 NAME

Math::NumSeq::Totient -- Euler's totient function, count of coprimes

=head1 SYNOPSIS

 use Math::NumSeq::Totient;
 my $seq = Math::NumSeq::Totient->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

Euler's totient function, being the count of integers coprime to i,

    1, 1, 2, 2, 4, 2, 6, 4, etc
    starting i=1

For example i=6 has no common factor with 1 or 5, so the totient is 2.

The totient can be calculated from the prime factorization by changing one
copy of each distinct prime p to p-1.

    totient(n) =        product          (p-1) * p^(e-1)
                  prime factors p^e in n

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Totient-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return totient(i).

This calculation requires factorizing C<$i> and in the current code after
small factors a hard limit of 2**32 is enforced in the interests of not
going into a near-infinite loop.  Above that the return is C<undef>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence, ie. C<$value> is the
totient of something.

=back

=head1 FORMULAS

=head2 Predicate

Totient(n) E<gt> 1 is always even because the factors factor p-1 for odd
prime p is even, or if no odd primes in n then totient(2^k)=2^(k-1) is even.
So odd numbers E<gt> 1 don't occur as totients.

The strategy is to look at the divisors of the given value to find the p-1,
q-1 etc parts arising as totient(n=p*q) etc.

    initial maxdivisor unlimited
    try divisors of value, with divisor < maxdivisor
      if p=divisor+1 is prime then
        remainder = value/divisor
        loop
          if recurse pred(remainder, maxdivisor=divisor) then yes
          if remainder divisible by p then remainder/=p
          else next divisor of value

The divisors tried include 1 and the value itself.  1 becomes p=2 casting
out possible factors of 2.  For value itself if p=value+1 prime then simply
totient(value+1)=value means it is a totient.

Care must be taken not to repeat a prime p, since value=(p-1)*(p-1) is not a
totient form.  One way to do this is to demand only smaller divisors when
recursing, hence the "maxdivisor".

Any divisors E<gt> 1 will have to be even to give p=divisor+1 odd to be a
prime.  Effectively each p-1, q-1, etc part of the target takes at least one
factor of 2 out of the value.  It might be possible to handle the 2^k part
of the target value specially, for instance noting that on reaching the last
factor of 2 there can be no further recursion, only value=p^a*(p-1) can be a
totient.

This search implicitly produces an n=p^a*q^b*etc with totient(n)=value but
for the C<pred()> method that n is not required, only the fact it exists.

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::TotientCumulative>,
L<Math::NumSeq::TotientPerfect>,
L<Math::NumSeq::TotientSteps>

L<Math::Prime::Util/euler_phi>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

Math-NumSeq is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-NumSeq is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

=cut
