# Copyright 2010, 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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

package Math::NumSeq::Fibonacci;
use 5.004;
use strict;

use vars '$VERSION','@ISA';
$VERSION = 73;
use Math::NumSeq::Base::Sparse;  # FIXME: implement pred() directly ...
@ISA = ('Math::NumSeq::Base::Sparse');

use Math::NumSeq;
*_is_infinite = \&Math::NumSeq::_is_infinite;
*_to_bigint = \&Math::NumSeq::_to_bigint;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('Fibonacci Numbers');
use constant description => Math::NumSeq::__('The Fibonacci numbers 1,1,2,3,5,8,13,21, etc, each F(i) = F(i-1) + F(i-2), starting from 1,1.');

use constant values_min => 0;
use constant i_start => 0;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

#------------------------------------------------------------------------------
# cf A105527 - index when n-nacci exceeds Fibonacci
#    A020695 - Pisot 2,3,5,8,etc starting OFFSET=0
#    A212804 - starting 1,0 OFFSET=0

use constant oeis_anum => 'A000045'; # fibonacci starting at i=0 0,1,1,2,3

#------------------------------------------------------------------------------

# $uv_limit is the biggest Fibonacci number f0 for which both f0 and f1 fit
# into a UV.  Upon reaching $uv_limit the next step will require BigInt.
# $uv_i_limit is the i index of $uv_limit.
#
my $uv_limit;
my $uv_i_limit = 0;
{
  # Float integers too in 32 bits ?
  # my $max = 1;
  # for (1 .. 256) {
  #   my $try = $max*2 + 1;
  #   ### $try
  #   if ($try == 2*$max || $try == 2*$max+2) {
  #     last;
  #   }
  #   $max = $try;
  # }
  my $max = ~0;

  # f1+f0 > i
  # f0 > i-f1
  # check i-f1 as the stopping point, so that if i=UV_MAX then won't
  # overflow a UV trying to get to f1>=i
  #
  my $f0 = 1;
  my $f1 = 1;
  my $prev_f0;
  while ($f0 <= $max - $f1) {
    $prev_f0 = $f0;
    ($f1,$f0) = ($f1+$f0,$f1);
    $uv_i_limit++;
  }

  ### Fibonacci UV limit ...
  ### $prev_f0
  ### $f0
  ### $f1
  ### ~0 : ~0

  $uv_limit = $prev_f0;

  ### $uv_limit
  ### $uv_i_limit

  __PACKAGE__->ith($uv_i_limit) == $uv_limit
    or warn "Oops, wrong uv_i_limit";
}

sub rewind {
  my ($self) = @_;
  ### Fibonacci rewind()
  $self->{'f0'} = 0;
  $self->{'f1'} = 1;
  $self->{'i'} = $self->i_start;
}
sub seek_to_i {
  my ($self, $i) = @_;
  ($self->{'f0'}, $self->{'f1'}) = $self->ith_pair($i);
  $self->{'i'} = $i;
}
sub next {
  my ($self) = @_;
  ### Fibonacci next(): "f0=$self->{'f0'}, f1=$self->{'f1'}"
  (my $ret,
   $self->{'f0'},
   $self->{'f1'})
    = ($self->{'f0'},
       $self->{'f1'},
       $self->{'f0'} + $self->{'f1'});
  ### $ret

  if ($ret == $uv_limit) {
    ### go to bigint f1 ...
    $self->{'f1'} = _to_bigint($self->{'f1'});
  }

  return ($self->{'i'}++, $ret);
}

# F[k-1] + F[k] = F[k+1]
# F[k-1] = F[k+1] - F[k]
# F[2k+1] = (2F[k]+F[k-1])*(2F[k]-F[k-1]) + 2*(-1)^k
#         = (2F[k] + F[k+1] - F[k])*(2F[k] - (F[k+1] - F[k])) + 2*(-1)^k
#         = (F[k] + F[k+1])*(2F[k] - F[k+1] + F[k]) + 2*(-1)^k
#         = (F[k] + F[k+1])*(3F[k] - F[k+1]) + 2*(-1)^k
# F[2k] = F[k]*(F[k]+2F[k-1])
#       = F[k]*(F[k]+2(F[k+1] - F[k]))
#       = F[k]*(F[k]+2F[k+1] - 2F[k])
#       = F[k]*(2F[k+1] - F[k])

sub ith {
  my ($self, $i) = @_;
  ### Fibonacci ith(): $i

  my $lowbit = ($i % 2);
  my $pair_i = ($i - $lowbit) / 2;
  my ($F0, $F1) = $self->ith_pair($pair_i);

  if ($i > $uv_i_limit && ! ref $F0) {
    ### automatic BigInt as not another bignum class ...
    $F0 = _to_bigint($F0);
    $F1 = _to_bigint($F1);
  }

  # last step needing just one of F[2k] or F[2k+1] done by one multiply
  # instead of two squares in the ith_pair() loop
  #
  if ($lowbit) {
    $F0 = ($F0 + $F1) * (3*$F0 - $F1) + ($pair_i % 2 ? -2 : 2);
  } else {
    $F0 *= (2*$F1 - $F0);
  }
  return $F0;
}

sub ith_pair {
  my ($self, $i) = @_;
  ### Fibonacci ith_pair(): $i

  if (_is_infinite($i)) {
    return ($i,$i);
  }

  my $neg = ($i < 0);
  if ($neg) {
    $i = -1-$i;
  }

  my @bits = _bit_split_hightolow($i+1);
  ### @bits
  shift @bits; # drop high 1-bit

  # k=1 which is the high bit of @bits
  # $Fk1 = F[k-1] = 0
  # $Fk  = F[k]   = 1
  #
  my $Fk1 = ($i * 0);  # inherit bignum 0
  if ($i >= $uv_i_limit && ! ref $Fk1) {
    # automatic BigInt if not another number class
    $Fk1 = _to_bigint(0);
  }
  my $Fk = $Fk1 + 1;  # inherit bignum 1

  my $add = -2;  # (-1)^k
  while (@bits) {
    ### remaining bits: @bits
    ### Fk1: "$Fk1"
    ### Fk: "$Fk"

    # two squares and some adds
    # F[2k+1] = 4*F[k]^2 - F[k-1]^2 + 2*(-1)^k
    # F[2k-1] =   F[k]^2 + F[k-1]^2
    # F[2k] = F[2k+1] - F[2k-1]
    #
    $Fk *= $Fk;
    $Fk1 *= $Fk1;
    my $F2kplus1 = 4*$Fk - $Fk1 + $add;
    $Fk1 += $Fk; # F[2k-1]
    my $F2k = $F2kplus1 - $Fk1;

    if (shift @bits) {  # high to low
      $Fk1 = $F2k;     # F[2k]
      $Fk = $F2kplus1; # F[2k+1]
      $add = -2;
    } else {
      # $Fk1 is F[2k-1] already
      $Fk = $F2k;  # F[2k]
      $add = 2;
    }
  }

  if ($neg) {
    ($Fk1,$Fk) = ($Fk, $Fk1);
    if ($i % 2) {
      $Fk1 = -$Fk1;
    } else {
      $Fk = -$Fk;
    }
  }

  ### final ...
  ### Fk1: "$Fk1"
  ### Fk: "$Fk"
  return ($Fk1, $Fk);
}

sub _bit_split_hightolow {
  my ($n) = @_;
  ### _bit_split_hightolow(): "$n"

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

use constant 1.02 _PHI  => (1 + sqrt(5)) / 2;
use constant 1.02 _BETA => -1/_PHI;

sub value_to_i_estimate {
  my ($self, $value) = @_;
  if (_is_infinite($value)) {
    return $value;
  }
  if ($value <= 0) {
    return 0;
  }

  if (defined (my $blog2 = _blog2_estimate($value))) {
    # i ~= (log2(F(i)) + log2(phi)) / log2(phi-beta)
    # with log2(x) = log(x)/log(2)
    return int( ($blog2 + (log(_PHI - _BETA)/log(2)))
                / (log(_PHI)/log(2)) );
  }

  # i ~= (log(F(i)) + log(phi)) / log(phi-beta)
  return int( (log($value) + log(_PHI - _BETA))
              / log(_PHI) );
}

sub _UNTESTED__value_to_i {
  my ($self, $value) = @_;
  if ($value < 0) { return undef; }
  my $i = $self->value_to_i_estimate($value) - 3;
  if (_is_infinite($i)) { return $i; }

  if ($i < 0) { $i = 0; }
  my ($f0,$f1) = $self->ith_pair($i);
  foreach (1 .. 10) {
    if ($f0 == $value) {
      return $i;
    }
    last if $f0 > $value;
    if ($i == $uv_i_limit && ! ref $f0) {
      # automatic BigInt if not another number class
      $f1 = _to_bigint($f1);
    }
    ($f0, $f1) = ($f1, $f0+$f1);
    $i += 1;
  }
  return undef;
}

#------------------------------------------------------------------------------
# generic, shared

# if $n is a BigInt, BigRat or BigFloat then return an estimate of log base 2
# otherwise return undef.
#
# For Math::BigInt 
#
# For BigRat the calculation is just a bit count of the numerator less the
# denominator so may be off by +/-1 or +/-2 or some such.  For 
#
sub _blog2_estimate {
  my ($n) = @_;

  if (ref $n) {
    ### _blog2_estimate(): "$n"

    if ($n->isa('Math::BigRat')) {
      return ($n->numerator->copy->blog(2) - $n->denominator->copy->blog(2))->numify;
    }
    if ($n->isa('Math::BigFloat')) {
      return $n->as_int->blog(2)->numify;
    }
    if ($n->isa('Math::BigInt')) {
      return $n->copy->blog(2)->numify;
    }
  }
  return undef;
}

1;
__END__

=for stopwords Ryde Math-NumSeq Ith bignum

=head1 NAME

Math::NumSeq::Fibonacci -- Fibonacci numbers

=head1 SYNOPSIS

 use Math::NumSeq::Fibonacci;
 my $seq = Math::NumSeq::Fibonacci->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The Fibonacci numbers F(i) = F(i-1) + F(i-2) starting from 0,1,

    0, 1, 1, 2, 3, 5, 8, 13, 21, 34, ...
    starting i=0

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Fibonacci-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Iterating

=over

=item C<($i, $value) = $seq-E<gt>next()>

Return the next index and value in the sequence.

When C<$value> exceeds the range of a Perl unsigned integer the return is a
C<Math::BigInt> to preserve precision.

=item C<$seq-E<gt>seek_to_i($i)>

Move the current sequence position to C<$i>.  The next call to C<next()>
will return C<$i> and corresponding value.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th Fibonacci number.

For negative <$i> the sequence is extended backwards as F[i]=F[i+2]-F[i+1].
The effect is the same Fibonacci numbers but negative at negative even i.

     i     F[i]
    ---    ----
     0       0
    -1       1
    -2      -1       <----+ negative at even i
    -3       2            |
    -4      -3       <----+

When C<$value> exceeds the range of a Perl unsigned integer the return is a
C<Math::BigInt> to preserve precision.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence, so is a positive Fibonacci
number.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.  See L</Value to i
Estimate> below.

=back

=head1 FORMULAS

=head2 Ith

Fibonacci F[i] can be calculated by a powering procedure with two squares
per step.  A pair of values F[k] and F[k-1] are maintained and advanced
according to bits of i from high to low

    start k=1, F[k]=1, F[k-1]=0
    add = -2       # 2*(-1)^k
    
    loop
      F[2k+1] = 4*F[k]^2 - F[k-1]^2 + add
      F[2k-1] =   F[k]^2 + F[k-1]^2

      F[2k] = F[2k+1] - F[2k-1]

      bit = next bit of i, high to low, skip high 1 bit
      if bit == 1
         take F[2k+1], F[2k] as new F[k],F[k-1]
         add = -2 (for next loop)
      else bit == 0
         take F[2k], F[2k-1] as new F[k],F[k-1]
         add = 2 (for next loop)

For the last (least significant) bit of i an optimization can be made with a
single multiple for that last step, instead of two squares.

    bit = least significant bit of i
    if bit == 1
       F[2k+1] = (2F[k]+F[k-1])*(2F[k]-F[k-1]) + add
    else
       F[2k]   = F[k]*(F[k]+2F[k-1])

The "add" amount is 2*(-1)^k which means +2 or -2 according to k odd or
even, which means whether the previous bit taken from i was 1 or 0.  That
can be easily noted from each bit, to be used in the following loop
iteration or the final step F[2k+1] formula.

For small i it's usually faster to just successively add F[k+1]=F[k]+F[k-1],
but when in bignums the doubling k-E<gt>2k by two squares is faster than
doing k many individual additions for the same thing.

=head2 Value to i Estimate

F[i] increases as a power of phi, the golden ratio.  The exact value is

    F[i] = (phi^i - beta^i) / (phi - beta)    # exactly

    phi = (1+sqrt(5))/2 = 1.618
    beta = -1/phi = -0.618

Since abs(beta)E<lt>1 the beta^i term quickly becomes small.  So taking a
log (natural logarithm) to get i,

    log(F[i]) ~= i*log(phi) - log(phi-beta)
    i ~= (log(F[i]) + log(phi-beta)) / log(phi)

Or the same using log base 2 which can be estimated from the highest bit
position of a bignum,

    log2(F[i]) ~= i*log2(phi) - log2(phi-beta)
    i ~= (log2(F[i]) + log2(phi-beta)) / log2(phi)

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::LucasNumbers>,
L<Math::NumSeq::Fibbinary>,
L<Math::NumSeq::FibonacciWord>,
L<Math::NumSeq::Pell>,
L<Math::NumSeq::Tribonacci>

L<Math::Fibonacci>,
L<Math::Fibonacci::Phi>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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
