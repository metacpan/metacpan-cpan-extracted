# Copyright 2012, 2013, 2014, 2016 Kevin Ryde

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

package Math::NumSeq::PowerFlip;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;
*_to_bigint = \&Math::NumSeq::_to_bigint;

use Math::NumSeq::PrimeFactorCount;;
*_prime_factors = \&Math::NumSeq::PrimeFactorCount::_prime_factors;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant name => Math::NumSeq::__('Prime Exponent Flip');
use constant description => Math::NumSeq::__('Flip each prime and its exponent, so for example 3^8 -> 8^3');
use constant default_i_start => 1;
use constant characteristic_increasing => 0;
use constant characteristic_non_decreasing => 0;
use constant characteristic_integer => 1;
use constant characteristic_smaller => 1;
use constant values_min => 1; # at i=1


#------------------------------------------------------------------------------
# cf A005117 squarefrees have all exponents 1 so value=1
#    A013929 non-squarefrees have some exponent>1 so value>1
#    A005361 product of exponents of prime factorization

use constant oeis_anum => 'A008477';

#------------------------------------------------------------------------------

use constant 1.02 _UV_LIMIT => 31**2; # is value=2**31

sub ith {
  my ($self, $i) = @_;
  ### PowerFlip ith(): $i

  if (_is_infinite($i)) {
    return $i;
  }
  $i = abs($i);

  my ($good, @primes) = _prime_factors($i);
  return undef unless $good;

  if (! @primes) {
    return $i;  # 0,1 unchanged
  }

  my $value = 1;
  my $log = 0;

  for (;;) {
    my $p = shift @primes || last;
    my $count = 1;
    while (@primes && $primes[0] == $p) {
      shift @primes;
      $count++;
    }
    $log += $p*log($count);
    if ($log > 31) {
      $count = _to_bigint($count);
    }
    $value *= $count ** $p;
  }
  return $value;
}

sub pred {
  my ($self, $value) = @_;
  ### PowerFlip pred(): $value

  # ! is_square_free()

  unless ($value >= 0 && $value <= 0xFFFF_FFFF) {
    return undef;
  }
  if ($value != int($value)) {
    return 0;
  }
  $value = "$value"; # numize Math::BigInt for speed

  if ($value < 2) {
    return 1;
  }

  my $limit = sqrt($value) + 1;

  for (my $p = 2; $p <= $limit; $p += 2-($p==2)) {
    next if ($value % $p);
    ### prime factor: $p
    $value /= $p;

    if (($value % $p) == 0) {
      # found a square factor
      return 1;
    }

    $limit = sqrt($value) + 1;
    ### divided out: "$p, new limit $limit"
  }

  ### final: $value
  # $value now either 1 or a prime, no square factor found

  return 0;
}

1;
__END__

=for stopwords Ryde Math-NumSeq ie

=head1 NAME

Math::NumSeq::PowerFlip -- prime exponent flip

=head1 SYNOPSIS

 use Math::NumSeq::PowerFlip;
 my $seq = Math::NumSeq::PowerFlip->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This sequence is i with primes and exponents flipped in the prime
factorization.

    i     = p^e * q^f * ...
    becomes
    value = e^p * f^q * ...

which gives

    1, 1, 1, 4, 1, 1, 1, 9, 8, 1, 1, 4, 1, 1, 1, 16, 1, 8, 1, 4, ...
    starting i=1

For example i=1000=2^3*5^3 becomes value=3^2*3^5=3^7=2187.

Any i=prime has value=1 since i=p^1 becomes value=1^p=1.  Value=1 occurs
precisely when i=p*q*r*etc with no repeated prime factor, ie. when i is
square-free.

The possible values which occur in the sequence are related to square
factors.  Since value=e^p has prime pE<gt>=2, every e,f,g etc powered up in
the value is a square or higher power.  So sequence values are a product of
squares and higher.

These calculations require factorizing C<$i> and in the current code after
small factors a hard limit of 2**32 is enforced in the interests of not
going into a near-infinite loop.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::PowerFlip-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return C<$i> with the prime powers and exponents flipped.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence.  As noted above this means
an integer C<$value> with at least one squared prime factor.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::PrimeFactorCount>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016 Kevin Ryde

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
