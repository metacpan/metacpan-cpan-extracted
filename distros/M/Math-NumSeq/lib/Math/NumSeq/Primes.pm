# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

package Math::NumSeq::Primes;
use 5.004;
use strict;
use POSIX ();
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099

use vars '$VERSION', '@ISA';
$VERSION = 75;
use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('Prime Numbers');
use constant description => Math::NumSeq::__('The prime numbers 2, 3, 5, 7, 11, 13, 17, etc.');
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant values_min => 2;
use constant i_start => 1;

#------------------------------------------------------------------------------
# cf A010051 - characteristic boolean 0 or 1 according as N is prime
#      A051006 characteristic as binary fraction, in decimal
#      A051007 characteristic as binary fraction, continued fraction
#    A000720 - pi(n) num primes <= n
#    A018252 - the non-primes
#    A002476 - primes 3k+1, which is also 6k+1
#
use constant oeis_anum => 'A000040'; # primes

#------------------------------------------------------------------------------

use constant 1.02;  # for leading underscore
use constant _MAX_PRIME_XS => do {
  my $umax = POSIX::UINT_MAX() / 2;
  # if ($umax > 0x8000_0000) {
  #   $umax = 0x8000_0000;
  # }
  $umax;
};

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'array_lo'} = 1;
  $self->{'array_hi'} = 1;
  @{$self->{'array'}} = ();
}
# needs a prime_count() for arbitrary seek
#
# sub _UNTESTED__seek_to_value {
#   my ($self, $value) = @_;
#   my $array = $self->{'array'};
#   if (@array) {
#     if ($value >= $array->[0] && $value <= $array->[-1]) {
#       # seek forward within $array
#       while ($value > $array->[0]) {
#         shift @$array;
#         $self->{'i'}++;
#       }
#       return;
#     }
#   }
#   $value = int($value);
#   if ($value > _MAX_PRIME_XS) {
#     # past limit
#     $self->{'array'} = undef;
#     return;
#   }
#   $self->{'i'} = _primes_count(0,$value);
#   $self->{'array_lo'} = 0;
#   $self->{'array_hi'} = $value-1;
#   @{$self->{'array'}} = ();
# }

sub next {
  my ($self) = @_;

  while (! @{$self->{'array'}}) {
    # fill array
    my $lo = $self->{'array_lo'};
    my $hi = $self->{'array_hi'};

    $lo = $self->{'array_lo'} = $hi+1;
    if ($lo > _MAX_PRIME_XS) {
      return;
    }

    my $len = int ($lo / 2);
    if ($len > 100_000) {
      $len = 100_000;
    }

    $hi = $lo + $len;
    if ($hi < 500) {
      $hi = 500;
    }
    if ($hi > _MAX_PRIME_XS) {
      $hi = _MAX_PRIME_XS;
    }
    $self->{'array_hi'} = $hi;

    @{$self->{'array'}} = _primes_list ($lo, $hi);
  }
  return ($self->{'i'}++, shift @{$self->{'array'}});
}



sub _primes_list {
  my ($lo, $hi) = @_;
  ### _my_primes_list: "$lo to $hi"
  if ($lo < 0) {
    $lo = 0;
  }
  if ($hi > _MAX_PRIME_XS) {
    $hi = _MAX_PRIME_XS;
  }

  if ($hi < $lo) {
    # Math::Prime::XS errors out if hi<lo
    return;
  }
  return Math::Prime::XS::sieve_primes ($lo, $hi);
}

sub pred {
  my ($self, $value) = @_;
  ### pred(): "$value"

  if (_is_infinite($value) || $value > 0xFFFF_FFFF) {
    return undef;
  }
  if ($value != int($value) || $value < 0) {
    return 0;
  }
  return is_prime($value);
}

# sub ith {
#   my ($self, $i) = @_;
#   my $array = $self->{'array'};
#   if ($i > $#$array) {
#     my $hi = int ($i/log($i) * 2 + 5);
#     do {
#       $array = $self->{'array'} = [ undef, _my_primes_list (0, $hi) ];
#       $hi *= 2;
#     } while ($i > $#$array);
#   }
#   return $array->[$i];
# }

use Math::NumSeq::Fibonacci;
*_blog2_estimate = \&Math::NumSeq::Fibonacci::_blog2_estimate;

sub value_to_i_estimate {
  my ($self, $value) = @_;
  ### value_to_i_estimate(): "$value"

  if ($value < 2) { return 0; }

  $value = int($value);
  if (defined (my $blog2 = _blog2_estimate($value))) {
    # est = v/log(v)
    # log2(v) = log(v)/log(2)
    # est = v/((log2(v)*log(2)))
    #     = v/log2(v) * 1/log(2)
    #    ~= v/log2(v) * 13/9
    #    ~= (13*v) / (9*log2(v))
    # using 13/9 as an approximation to 1/log(2) to stay in BigInt
    #
    ### $blog2
    ### num: $value*13
    ### den: 9 * $blog2
    return ($value * 13) / (9 * $blog2);
  }

  ### log: log($value)
  ### div: $value/log($value)
  return int($value/log($value));
}

1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::Primes -- prime numbers

=head1 SYNOPSIS

 use Math::NumSeq::Primes;
 my $seq = Math::NumSeq::Primes->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The prime numbers, not divisible by anything except themselves and 1.

    2, 3, 5, 7, 11, 13, 17, 19, ...         (A000040)
    starting i=1

Currently this is implemented with C<Math::Prime::XS> generating blocks of
primes with a sieve of Eratosthenes.  The result is reasonably progressive.
On a 32-bit system there's a hard limit at 2^31 (though even approaching
that takes a long time to calculate).

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Primes-E<gt>new ()>

Create and return a new sequence object.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a prime.

In the current code a hard limit of 2**32 is placed on the C<$value> to be
checked, in the interests of not going into a near-infinite loop.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.  C<$value> can be
any size, it's not limited as in C<pred()>.  See L</Value to i Estimate>
below.

=back

=head1 FORMULAS

=head2 Value to i Estimate

In the current code the number of count of primes up to value is estimated
by the well-known asymptotic

    i ~= value/log(value)

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::TwinPrimes>,
L<Math::NumSeq::SophieGermainPrimes>,
L<Math::NumSeq::Emirps>

L<Math::Prime::XS>,
L<Math::Prime::TiedArray>,
L<Math::Prime::FastSieve>,
L<Math::Prime::Util>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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
