# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2019 Kevin Ryde

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


# ZOrderCurve, ImaginaryBase tree shape
# DragonCurve repeating runs
#
# cf fxtbook ch38 p756
#
# cf visualizing
# http://cs-people.bu.edu/ilir/zecko/


package Math::NumSeq::Fibbinary;
use 5.004;
use strict;
use Carp;

use vars '$VERSION', '@ISA';
$VERSION = 74;
use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;
*_to_bigint = \&Math::NumSeq::_to_bigint;

use Math::NumSeq::Fibonacci;
*_bit_split_hightolow = \&Math::NumSeq::Fibonacci::_bit_split_hightolow;
*_blog2_estimate = \&Math::NumSeq::Fibonacci::_blog2_estimate;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('Fibbinary Numbers');
use constant description => Math::NumSeq::__('Fibbinary numbers 0,1,2,4,5,8,9,etc, integers without adjacent 1-bits.');
use constant default_i_start => 0;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

sub values_min {
  my ($self) = @_;
  return $self->ith($self->i_start);
}

#------------------------------------------------------------------------------
# cf A000119 - number of fibonacci sums forms
#    A003622 - n with odd Zeckendorf,  cf golden seq
#    A037011 - baum-sweet cubic, might be 1 iff i is in the fibbinary seq
#    A014417 - n in fibonacci base, the fibbinaries written out in binary
#    A139764 - smallest Zeckendorf term
#    A054204 - using only even Fibs
#
use constant oeis_anum => 'A003714';  # Fibbinary, OFFSET=0 start value=0

#------------------------------------------------------------------------------
# $self->{'i'}, $self->{'value'} are the next $i,$value to return.
# next() increments 'i' and steps 'value'.
# So the next value is calculated ahead of its actually being needed,
# but doing so 

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'value'} = 0;
}
sub seek_to_i {
  my ($self, $i) = @_;
  if ($i < 0) {
    croak "Cannot seek to ",$i,", sequence begins at i=0";
  }
  $self->{'i'} = $i;
  $self->{'value'} = $self->ith($i);
}
sub seek_to_value {
  my ($self, $value) = @_;
  $self->seek_to_i($self->value_to_i_ceil($value));
}

sub next {
  my ($self) = @_;
  ### Fibbinary next() ...

  my $v = $self->{'value'};
  $self->{'value'} = _value_next($self,$v);
  return ($self->{'i'}++, $v);
}

sub _value_next {
  my ($self, $value) = @_;
  my $filled = ($value >> 1) | $value;
  my $mask = (($filled+1) ^ $filled) >> 1;

  ### value : sprintf('0b %6b',$value)
  ### filled: sprintf('0b %6b',$filled)
  ### mask  : sprintf('0b %6b',$mask)
  ### bit   : sprintf('0b %6b',$mask+1)
  ### newv  : sprintf('0b %6b',($value | $mask))

  return ($value | $mask) + 1;
}

sub ith {
  my ($self, $i) = @_;
  ### Fibbinary ith(): $i

  if (_is_infinite($i)) {
    return $i;
  }

  # f1+f0 > i
  # f0 > i-f1
  # check i-f1 as the stopping point, so that if i=UV_MAX then won't
  # overflow a UV trying to get to f1>=i
  #
  my @fibs;
  {
    my $f0 = ($i * 0);  # inherit bignum 0
    my $f1 = $f0 + 1;   # inherit bignum 1
    @fibs = ($f0);
    while ($f0 <= $i-$f1) {
      ($f1,$f0) = ($f1+$f0,$f1);
      push @fibs, $f1;
    }
  }
  ### @fibs

  my $value = 0;
  while (my $f = pop @fibs) {
    ### at: "$f i=$i  value=$value"
    $value *= 2;
    if ($i >= $f) {
      $value += 1;
      $i -= $f;
      ### sub: "$f to i=$i value=$value"

      # never consecutive fibs, so pop without comparing to i
      pop @fibs || last;
      $value *= 2;
    }
  }
  return $value;
}

sub pred {
  my ($self, $value) = @_;
  ### Fibbinary pred(): $value

  my $int;
  unless ($value >= 0
          && $value == ($int = int($value))) {
    return 0;
  }

  # go to BigInt if NV floating point integer bigger than UV, since "&"
  # operator will cast to a UV and lose bits
  if ($int > ~0 && ! ref $int) {
    $int = _to_bigint(sprintf('%.0f',$int));
    ### use BigInt: $int
    ### str: sprintf('%.0f',$int)
  }

  ### and: ($int & ($int >> 1)).''
  return ! ($int & ($int >> 1));
}

#------------------------------------------------------------------------------

sub value_to_i_floor {
  my ($self, $value) = @_;
  ### Fibbinary value_to_i_floor(): $value
  if ($value < 0) { return 0; }
  my ($i) = _value_to_i_and_floor($value);
  return $i;
}
sub value_to_i_ceil {
  my ($self, $value) = @_;
  ### Fibbinary value_to_i_ceil(): $value
  if ($value < 0) { return 0; }
  my ($i,$floor) = _value_to_i_and_floor($value);
  return $i + $floor;
}
sub value_to_i {
  my ($self, $value) = @_;
  ### Fibbinary value_to_i(): $value
  if ($value < 0) { return undef; }
  my ($i,$floor) = _value_to_i_and_floor($value);
  return ($floor ? undef : $i);
}

# return ($i, $floor)
sub _value_to_i_and_floor {
  my ($value) = @_;

  if (_is_infinite($value)) {
    return ($value,
            0); # reckon infinite as not rounded
  }

  my $floor;
  {
    my $int = int($value);
    $floor = ($value == $int ? 0 : 1);
    $value = $int
      || return (0, $floor);  # i=0 not handled below
  }

  my @bits = _bit_split_hightolow($value);
  my @fibs;
  {
    my $f0 = ($value * 0);  # inherit bignum 0
    my $f1 = $f0 + 1;       # inherit bignum 1
    foreach (@bits) {
      ($f1,$f0) = ($f1+$f0,$f1);
      push @fibs, $f1;
    }
  }
  ### @fibs

  my $prev_bit = shift @bits; # high 1-bit
  my $i = pop @fibs;

  ### initial i: $i

  foreach my $bit (@bits) {  # high to low
    my $fib = pop @fibs;
    ### $bit
    ### $fib

    if ($bit) {
      if ($prev_bit) {
        ### consecutive bits 11xxx, round down to 10xxx with xxx=1010 ...
        while (@fibs) {
          $i += pop @fibs;
          pop @fibs;
        }
        return ($i,
                1);  # rounded down
      }
      $i += $fib;
      ### add i to: $i
    }
    $prev_bit = $bit;
  }
  ### exact i: "$i"
  return ($i,
          $floor);  # not rounded, unless $value was fractional
}

#------------------------------------------------------------------------------
# value_to_i_estimate()

use constant 1.02 _PHI => (1 + sqrt(5)) / 2;

# (phi-beta) = phi+1/phi = 2phi-1
#
# value=2^k
# log(value) = k*log(2)
# k = log(value)/log(2)
# i = F(k)
#   = phi^(k+1) / (phi-beta)
#   = phi^k * C where C=phi/(phi-beta) ~= 0.72
# log(i/C) = k*log(phi)
# k = log(i/C)/log(phi)
#
# log(i/C)/log(phi) = log(value)/log(2)
# log(i/C) = log(value) * log(phi)/log(2)
# i/C = e^ (log(value) * log(phi)/log(2))
# i/C = (e^log(value)) ^ (log(phi)/log(2)))
# i = C * value ^ (log(phi)/log(2)))
#
# log(phi)/log(2) ~= 0.694
# 

sub value_to_i_estimate {
  my ($self, $value) = @_;

  if ($value <= 0) {
    return 0;
  }

  $value = int($value);
  if (my $blog2 = Math::NumSeq::Fibonacci::_blog2_estimate($value)) {
    my $shift = int ((1 - log(_PHI)/log(2))
                     * Math::NumSeq::Fibonacci::_blog2_estimate($value));
    return $value >> $shift;
  }

  return int ((((_PHI + 1/_PHI)/_PHI))
              * $value ** (log(_PHI)/log(2)));
}

# Can get close taking bits low to high and tweaking for consecutive 1s.
# But the high to low of the full value_to_i_floor() is only a little extra
# work.
#
# sub value_to_i_estimate {
#   my ($self, $value) = @_;
#   ### Fibbinary value_to_i_estimate(): $value
# 
#   if (_is_infinite($value)) {
#     return $value;
#   }
# 
#   my $f0 = my $f1 = ($value * 0)+1;  # inherit bignum 1
#   my $i = 0;
# 
#   my $prev_bit = 0;
#   while ($value) {
#     my $bit = $value % 2;
#     if ($bit) {
#       if ($prev_bit) {
#         $i += $f0;
#       } else {
#         $i += $f1;
#       }
#     }
#     $prev_bit = $bit;
#     ($f1,$f0) = ($f1+$f0,$f1);
#     $value = int($value/2);
#   }
#   return $i;
# }

1;
__END__


# old next():
#   @{$self->{'pos'}} = (-2);
#   @{$self->{'values'}} = (1);
# sub Xnext {
#   my ($self) = @_;
#   ### Fibbinary next() ...
# 
#   my $ret;
#   my $pa = $self->{'pos'};
#   my $va = $self->{'values'};
#   ### $pa
#   ### $va
# 
#   my $pos = $pa->[-1];
#   if ($pos <= -1) {
#     if ($pos < -1) {
#       $pa->[-1] = -1;
#       $ret = 0;
#     } else {
#       $pa->[-1] = 0;
#       $ret = 1;
#     }
#   } elsif ($pos >= 2) {
#     ### introduce low bit ...
#     push @$pa, 0;
#     push @$va, ($ret = $va->[-1] + 1);
#   } else {
#     # move bit up
#     while ($#$pa && $pos+2 >= $pa->[-2]) {
#       pop @$pa;
#       pop @$va;
#       $pos = $pa->[-1];
#     }
#     $ret = ($va->[-1] += 2**$pos);
#     (++$pa->[-1]);
#     ### move up to
#     ### added power: 2**$pos
#     ### $pa
#     ### $va
#     ### $pos
#   }
#   ### $ret
#   return ($self->{'i'}++, $ret);
# }




=for stopwords Ryde Math-NumSeq fibbinary Zeckendorf k's Ith i'th OR-ing incrementing Fibonaccis BigInt bigint BigFloat BigRat eg ie

=head1 NAME

Math::NumSeq::Fibbinary -- without consecutive 1-bits

=head1 SYNOPSIS

 use Math::NumSeq::Fibbinary;
 my $seq = Math::NumSeq::Fibbinary->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This sequence is the fibbinary numbers

     0, 1, 2, 4, 5, 8, 9, 10, 16, 17, 18, 20, 21, 32, 33, 34, ...
     starting i=0

being integers which have no adjacent 1-bits when written in binary, taken
in ascending order.

    i     fibbinary    fibbinary
          (decimal)    (binary)
   ---    ---------    --------
    0         0             0
    1         1             1
    2         2            10
    3         4           100
    4         5           101
    5         8          1000
    6         9          1001
    7        10          1010
    8        16         10000
    9        17         10001

For example at i=4 fibbinary is 5.  The next fibbinary is not 6 or 7 because
they have adjacent 1-bits (110 and 111), the next without adjacent 1s is 8
(100).

The two highest bits must be "10...", they cannot be "11...".  So there's
effectively a block of 2^k values (not all used) followed by a gap of 2^k
values, etc.

The least significant bit of each fibbinary is the Fibonacci word sequence,
per L<Math::NumSeq::FibonacciWord>.

All numbers without adjacent 1-bits can also be generated simply by taking
the binary expansion and changing each "1" to "01", but that doesn't given
them in ascending order the way the fibbinary here does.

=head2 Zeckendorf Base

The bits of the fibbinary values encode Fibonacci numbers used to represent
i in Zeckendorf style Fibonacci base.  In the Zeckendorf base system an
integer i is a sum of Fibonacci numbers,

    i = F[k1] + F[k2] + ... F[kn]         k1 > k2 > ... > kn

Each k is chosen as the highest Fibonacci less than the remainder at that
point.  For example, reckoning the Fibonaccis as F[0]=1, F[2]=2, etc

    19 = 13+5+1 = F[5]+F[3]+F[0]

=for GP-Test  fibonacci(2) == 1

=for GP-Test  fibonacci(4) == 3

=for GP-Test  fibonacci(7) + fibonacci(5) + fibonacci(2) == 19

The k's are then assembled as 1-bits in binary to encode this sum in an
integer,

    fibbinary(19) = 2^5 + 2^3 + 2^0 = 41

=for GP-Test  2^5 + 2^3 + 2^0 == 41

The gaps between Fibonacci numbers means that after subtracting F(k) the
next cannot be F(k-1), it must be F(k-2) or less.  For that reason there's
no adjacent 1-bits in the fibbinary numbers.

The connection between no adjacent 1s and the Fibonacci sequence can be seen
by considering values with high bit 2^k.  The further bits in it cannot have
2^(k-1) but only 2^(k-2), so effectively the number of new values are not
from the previous k-1 but the second previous k-2, the same way as the
Fibonacci sequence adds not the previous term (which would by double) but
the one before instead.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Fibbinary-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Iterating

=over

=item C<$seq-E<gt>seek_to_i($i)>

=item C<$seq-E<gt>seek_to_value($value)>

Move the current i so C<next()> will return C<$i> or C<$value> on the next
call.  If C<$value> is not in the sequence then move so as to return the
next higher value which is.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th fibbinary number.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a fibbinary number, which means that in binary
it doesn't have any consecutive 1-bits.

=item C<$i = $seq-E<gt>value_to_i($value)>

=item C<$i = $seq-E<gt>value_to_i_ceil($value)>

=item C<$i = $seq-E<gt>value_to_i_floor($value)>

Return the index i of C<$value>.  If C<$value> is not in the sequence then
C<value_to_i()> returns C<undef>, or C<value_to_i_ceil()> returns the i of
the next higher value which is, or C<value_to_i_floor()> the i of the next
lower value.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.

=back

=head1 FORMULAS

=head2 Next Value

For a given fibbinary number, the next fibbinary is +1 if the lowest bit is
2^2=4 or more.  If however the low bit is 2^1=2 or 2^0=1 then the run of low
alternating ...101 or ...1010 must be cleared and the bit above set.  For
example 1001010 becomes 1010000.  All cases can be handled by some bit
twiddling

    # value=fibbinary
    filled = (value >> 1) | value
    mask = ((filled+1) ^ filled) >> 1
    next value = (value | mask) + 1

For example

    value  = 1001010
    filled = 1101111
    mask   =    1111
    next   = 1010000

"filled" means trailing ...01010 has the zeros filled in to ...01111.  Then
those low ones can be extracted with +1 and XOR (the usual trick for getting
low ones).  +1 means the bit above the filled part is included so 11111, but
a shift drops back to "mask" just 01111.  OR-ing and incrementing then
clears those low bits and sets the next higher bit to make ...10000.

This works for any fibbinary input, both odd "...10101" and even "...1010"
endings and also zeros "...0000".  In the zeros case the result is just a +1
for "...0001", and that includes input value=0 giving next=1.

=head2 Ith Value

The i'th fibbinary number can be calculated as per L</Zeckendorf Base>
above.  Reckoning the Fibonacci numbers as F(0)=1, F(1)=2, F(2)=3, F(3)=5,
etc,

    find the biggest F(k) <= i
    subtract i -= F(k)
    fibbinary result += 2^k
    repeat until i=0

To find each F(k)E<lt>=i either just work downwards through the Fibonacci
numbers, or the Fibonaccis grow as (phi^k)/sqrt(5) with phi=(sqrt(5)+1)/2
the golden ratio, so an F(k) could be found by a log base phi of i.  Or
taking log2 of i (the bit length of i) might give 2 or 3 candidates for k.
Calculating log base phi is unlikely to be faster, but log 2 high bit might
quickly go to a nearly-correct place in a table.

=head2 Predicate

Testing for a fibbinary value can be done by a shift and AND,

    is_fibbinary = ((value & (value >> 1)) == 0)

Any adjacent 1-bits overlap in the shift+AND and come through as non-zero.

Perl C<&> operator converts NV float to UV integer.  If an NV value is an
integer but bigger than a UV then bits will be lost to the C<&>.  Conversion
to C<Math::BigInt> or similar is necessary to preserve the full value.

Floats which are integers but bigger than an UV might be of interest, or it
might be thought any float means rounded-off and therefore inaccurate and
not of interest.  The current code has some experimental automatic BigInt
conversion which works for floats and for BigFloat or BigRat integers too,
but don't rely on this quite yet.  (A BigInt input directly is fine of
course.)

=head2 Value to i Floor

In a fibbinary value each bit becomes a Fibonacci F[i] to add to make i, as
per L</Zeckendorf Base> above.

If a number is not a fibbinary then the next lower fibbinary can be had by
finding the highest 11 pair and changing it and all the bits below to
101010...etc.  For example 10011001 is not a fibbinary and must change down
to 10010101, ie. the 11001 reduces to 10101, that being the biggest
fibbinary no-adjacent-1s which is 10xxx.

    bits 2^k from high to low
      if bit set
        if prev bit set too
        then treat remainder as 010101...
        else i += F[k]

If working downwards adding F[k] values then it's easy enough to notice an
adjacent 11 pair.  An alternative would be to find all 11 pairs by
bit-twiddling per L</Predicate> above and the highest 1-bit (if any) of
those is the place to mangle.

=head2 Value to i Estimate

In general i grows as a power of phi=1.618 and the values grow as a power
of 2.  So an estimate can be had from

    value = 2^k
    i = F[k+1]
      ~= phi^(k+1) / (phi + 1/phi)
      ~= C * phi^k
    where C=phi/(phi + 1/phi)

    log(i/C)/log(phi) ~= log(value)/log(2)

    i_estimate = C * value^(log(phi)/log(2))

The power log(phi)/log(2)=0.694 reduces the value to give an i
approximation.  That power can also be approximated by shifting off the
least significant 1-0.694=0.306 of the bits of the value.  This is fast and
may be enough accuracy for a bigint.

    highbitpos of value
    i_estimate = value >> floor(highbitpos * 0.306)

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Fibonacci>,
L<Math::NumSeq::FibonacciWord>,
L<Math::NumSeq::GolayRudinShapiro>,
L<Math::NumSeq::BaumSweet>

L<Math::Fibonacci> C<decompose()>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2019 Kevin Ryde

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
