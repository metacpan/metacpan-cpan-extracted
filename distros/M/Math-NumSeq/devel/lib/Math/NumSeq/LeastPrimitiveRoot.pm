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

package Math::NumSeq::LeastPrimitiveRoot;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::PrimeFactorCount;;
*_prime_factors = \&Math::NumSeq::PrimeFactorCount::_prime_factors;

use Math::NumSeq::DuffinianNumbers;
*_coprime = \&Math::NumSeq::DuffinianNumbers::_coprime;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('The first primitive root modulo i.');
use constant default_i_start => 1;
use constant characteristic_smaller => 1;
use constant characteristic_integer => 1;

use constant parameter_info_array =>
  [ { name        => 'root_type',
      type        => 'enum',
      display     => Math::NumSeq::__('Negative'),
      default     => 'positive',
      choices     => ['positive',
                      'negative',
                     ],
      choices_display => [Math::NumSeq::__('Positive'),
                          Math::NumSeq::__('Negative'),
                         ],
      description => Math::NumSeq::__('Which primitive root to return, the least positive or the least negative.'),
    },
  ];


sub values_min {
  my ($self) = @_;
  if ($self->{'root_type'} eq 'negative') {
    return undef;  # negative values, no minimum
  }
  my $i_start = $self->i_start;
  if ($i_start <= 2) {
    return ($i_start == 2 ? 1 : 0);
  }
  return 2;
}
sub values_max {
  my ($self) = @_;
  if ($self->{'root_type'} eq 'positive') {
    return undef;  # positive values, no maximum
  }
  my $i_start = $self->i_start;
  if ($i_start <= 2) {
    return ($i_start == 2 ? -1 : 0);
  }
  return -2;
}

#------------------------------------------------------------------------------
# cf A001918 - least primitive root of prime
#    A002199 - least negative primitive root of a prime, as a positive
#    A071894 - largest primitive root of prime
#
#    A002230 - primes with new record least primitive root
#    A114885 - prime index of those primes
#    A002231 - the record root
#
#    A002233 - least primitive root of prime which is also a prime
#    A122028 - similar
#
#    A001122 - primes with 2 as primitive root
#    A001913 - primes with 10 as primitive root
#    A019374 - primes with 50 as primitive root
#    A060749 - list of primitive roots of each prime
#
#    A002371 - period of repeating part of 1/prime(n), 0 for 2,5
#    A048595 - period of repeating part of 1/prime(n), 1 for 2,5
#    A060283 - repeating part of 1/prime(n)
#    A060251 - repeating part of n/prime(n)
#    A006559 - primes 1/p has 0 < period < p-1, so not max length
#    A001914 - cyclic 10 is a quad residue mod p and mantissa class 2

use constant oeis_anum => 'A111076';


#------------------------------------------------------------------------------

sub ith {
  my ($self, $i) = @_;
  ### LeastPrimitiveRoot ith(): $i

  if (_is_infinite($i)) {
    return undef;
  }
  if ($i < 0) {
    return undef;
  }

  if ($self->{'root_type'} eq 'positive') {
    if ($i < 2) {
      return 0; # nothing ==1 modulo 0 or 1
    }
    for (my $root = 2; $root < $i; $root++) {
      my $bool = _is_primitive_root ($root, $i);
      if (! defined $bool) { return undef; }
      if ($bool) { return $root; }
    }
    return 1;
  } else {
    if ($i < 2) {
      return 0; # nothing ==1 modulo 0 or 1
    }
    for (my $root = -2; $root > -$i; $root--) {
      ### try root: $root
      my $bool = _is_primitive_root ($root, $i);
      if (! defined $bool) { return undef; }
      if ($bool) { return $root; }
    }
    return -1;
  }
}

# sub pred {
#   my ($self, $value) = @_;
#   ### LeastPrimitiveRoot pred(): "$value"
#   return (Math::NumSeq::Primes->pred($value)
#           && _is_primitive_root ($self->{'radix'}, $value));
# }

sub _is_primitive_root {
  my ($base, $modulus) = @_;

  if (_is_infinite($modulus)) {
    return undef;
  }
  if ($modulus < 2 || ! _coprime(abs($base),$modulus)) {
    ### not coprime ...
    return 0;
  }

  my $exponent = _lambda($modulus);
  if (! defined $exponent) {
    return undef;  # too big to factorize
  }
  my ($good, @primes) = _prime_factors($exponent);
  return undef unless $good;

  my $prev_p = 0;
  while (defined (my $p = shift @primes)) {
    next if $p == $prev_p;
    $prev_p = $p;

    ### $p
    ### div: $exponent/$p
    ### powmod: _powmod($base, $exponent/$p, $modulus)

    if (_powmod($base, $exponent/$p, $modulus) <= 1) {
      return 0;
    }
  }

  # my $power = $base;
  # foreach (1 .. $value-2) {
  #   $power %= $value;
  #   if ($power == 1) {
  #     ### no, at: $_
  #     return 0;
  #   }
  #   $power *= $base;
  # }

  return 1;
}

# lambda(2^n * p1^n1 * p2^n2 * ...) = LCM lambda(2^n), lambda(p1^n1), ...
# lambda(2^n) = totient(2^n)    if n=0,1,2
#             = totient(2^n)/2  if n>2
# lambda(p^n) = totient(p^n) = (p-1)*p^(n-1)
#
# lambda(18=2*3*3) = lcm 2-1=1, 2*3=6 = 6
#
sub _lambda {
  my ($n) = @_;
  ### _lambda(): $n

  my ($good, @primes) = _prime_factors($n);
  return undef unless $good;
  ### @primes

  if (@primes >= 3 && $primes[2] == 2) {
    # 2^n with n>2, drop one factor of 2 to give totient(2^n)/2
    shift @primes;
  }
  my $prev = shift @primes || return 1;
  my $totient = $prev-1;
  my $ret = 1;
  ### initial ...
  ### $prev
  ### $totient

  foreach my $p (@primes) {
    ### $p
    if ($p == $prev) {
      $totient *= $p;
    } else {
      $ret = _lcm($ret, $totient);
      $totient = $p-1;
      $prev = $p;
    }
  }

  ### final ...
  ### $ret
  ### $totient
  return _lcm($ret, $totient);
}

sub _lcm {
  my $ret = shift;
  while (@_) {
    my $value = shift;
    $ret *= $value / _gcd($ret, $value);
  }
  return $ret;
}

sub _gcd {
  my ($x, $y) = @_;
  #### _gcd(): "$x,$y"

  # bgcd() available in even the earliest Math::BigInt
  if ((ref $x && $x->isa('Math::BigInt'))
      || (ref $y && $y->isa('Math::BigInt'))) {
    return Math::BigInt::bgcd($x,$y);
  }

  $x = abs(int($x));
  $y = abs(int($y));
  unless ($x > 0) {
    return $y;
  }
  if ($y > $x) {
    $y %= $x;
  }
  for (;;) {
    if ($y <= 1) {
      return ($y == 0 ? $x : 1);
    }
    ($x,$y) = ($y, $x % $y);
  }
}

sub _powmod {
  my ($base, $exponent, $modulus) = @_;

  my @exponent = _bit_split_hightolow($exponent)
    or return 1;

  my $power = $base % $modulus;
  shift @exponent; # high 1 bit

  while (defined (my $bit = shift @exponent)) {  # high to low
    $power *= $power;
    $power %= $modulus;
    if ($bit) {
      $power *= $base;
      $power %= $modulus;
    }
  }
  return $power;
}

sub _bit_split_hightolow {
  my ($n) = @_;
  # ### _bit_split_hightolow(): "$n"

  if (ref $n) {
    if ($n->isa('Math::BigInt')
        && $n->can('as_bin')) {
      ### BigInt: $n->as_bin
      return split //, substr($n->as_bin,2);
    }
  }
  my @bits;
  while ($n) {
    push @bits, $n % 2;
    $n = int($n/2);
  }
  return reverse @bits;
}

1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::LeastPrimitiveRoot -- smallest primitive root

=head1 SYNOPSIS

 use Math::NumSeq::LeastPrimitiveRoot;
 my $seq = Math::NumSeq::LeastPrimitiveRoot->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

I<In progress ...>

This is the least primitive root modulo i,

    3, 3, 5, 4, 4, 3, 5, 5, 4, 3, 6, 6, 8, 8, 7, 7, 9, 8, 8, ...
    starting i=1

A primitive root is a base b for which

    b^totient(i) == 1 modulo i
    and all smaller exponents b^e != 1 modulo i

The powers of a base b taken modulo i are a multiplicative group

     b^0, b^1, b^2, b^3, etc  modulo i

Eventually a power b^k == 1 modulo i is reached.  The k where that happens
is called the multiplicative order.  The multiplicative order can be at most
totient(i).  For some bases b it's smaller.  A base b for which the
multiplicative order is the full totient(i) is a primitive root.  The
sequence here gives the first base b with that maximum multiplicative order.

For i prime totient(i)=i-1 and the set of powers of a primitive root gives
all the integers 1 to i-1.  For i composite totient(i) is smaller and the
powers aren't consecutive integers.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::LeastPrimitiveRoot-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the first primitive root to modulus C<$i>.

=item C<$i = $seq-E<gt>i_start ()>

Return 1, the first term in the sequence being at i=1.

=back

=head1 SEE ALSO

L<Math::NumSeq>

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
