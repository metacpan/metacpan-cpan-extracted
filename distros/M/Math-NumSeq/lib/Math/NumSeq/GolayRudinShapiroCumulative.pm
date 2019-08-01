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

package Math::NumSeq::GolayRudinShapiroCumulative;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::GolayRudinShapiro;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Golay-Rudin-Shapiro Cumulative');
use constant description => Math::NumSeq::__('Cumulative Golay/Rudin/Shapiro sequence.');
use constant values_min => 1;
use constant characteristic_integer => 1;
use constant characteristic_smaller => 1;
use constant i_start => Math::NumSeq::GolayRudinShapiro->default_i_start;

#------------------------------------------------------------------------------
# cf A020990 - cumulative GRS(2n+1), flips sign at odd i
#    A051032 - GRS cumulative of 2^n
#    A212591 - index of first occurrence of k in the partial sums
#    A020991 - index of last occurrence of k in the partial sums
#    A093573 - indexes of all positions where k occurs

use constant oeis_anum => 'A020986';  # GRS +/-1 cumulative

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  $self->{'grs'} = Math::NumSeq::GolayRudinShapiro->new;
  $self->{'value'} = 0;
}
sub tell_i {
  my ($self) = @_;
  return $self->{'grs'}->tell_i;
}
sub _UNTESTED__seek_to_i {
  my ($self, $i) = @_;
  $self->{'grs'}->seek_to_i($i);
  $self->{'value'} = $self->ith($i-1) || 0;
}

sub next {
  my ($self) = @_;

  # doubling up ...
  # $self->{'grs'}->next;
  # my ($i, $value) = $self->{'grs'}->next;
  # return ($i>>1,
  #         ($self->{'value'} += $value));

  my ($i, $value) = $self->{'grs'}->next;
  return ($i,
          ($self->{'value'} += $value));
}

sub ith {
  my ($self, $i) = @_;
  ### ith(): $i

  if ($i < 0) {
    return undef;
  }
  if (_is_infinite($i)) {
    return $i;
  }

  if ($i <= 1) {
    return $i+1;
  }

  my @bits = _bits_low_to_high($i);
  my $bit = shift @bits;
  my $ret = 1;
  my $power = ($i * 0) + 1;   # inherit possible bignum 1

  ### initial bit: $bit

  for (;;) {
    my $next = shift @bits;
    if ($bit && $next) {
      ### negate A to: "ret=$ret"
      $ret = -$ret;
    }
    if ($bit) {
      $ret += $power;
      ### add A: "$power giving ret=$ret"
    }
    $power *= 2;
    last unless @bits;
    $bit = $next;

    $next = shift @bits;
    $i = int($i/2);
    if ($bit && $next) {
      $ret = -$ret;
    }
    if ($bit) {
      ### add B: "$power to ret=$ret"
      $ret += $power;
    }
    last unless @bits;
    $bit = $next;
  }

  ### final add: $power
  return ($ret + $power);
}

sub _bits_low_to_high {
  my ($n) = @_;
  if (ref $n) {
    if ($n->isa('Math::BigInt')
        && $n->can('as_bin')) {
      return reverse split //, substr($n->as_bin,2);
    }
  }
  my @bits;
  while ($n) {
    push @bits, $n % 2;
    $n = int($n/2);
  }
  return @bits;
}

sub pred {
  my ($self, $value) = @_;
  return ($value >= 1
          && $value == int($value));
}

1;
__END__

=for stopwords Ryde Math-NumSeq OEIS Ith GRS NumSeq

=head1 NAME

Math::NumSeq::GolayRudinShapiroCumulative -- cumulative Golay/RudinShapiro sequence

=head1 SYNOPSIS

 use Math::NumSeq::GolayRudinShapiroCumulative;
 my $seq = Math::NumSeq::GolayRudinShapiroCumulative->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the Golay/Rudin/Shapiro sequence values accumulated as
GRS(0)+...+GRS(i),

    starting from i=0 value=GRS(0)

    1, 2, 3, 2, 3, 4, 3, 4, 5, 6, 7, 6, 5, 4, 5, 4, ...

The total is always positive, and in fact a given cumulative total k occurs
precisely k times.  For example the three occurrences of 3 shown above are
all the places 3 occurs.

This GRS cumulative arises as in the alternate paper folding curve as the
coordinate sum X+Y.  The way k occurs k many times has a geometric
interpretation as the points on the diagonal X+Y=k of the curve visited a
total of k many times.  See L<Math::PlanePath::AlternatePaper/dSum>.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::GolayRudinShapiroCumulative-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th value from the sequence, being the total
C<GRS(0)+GRS(1)+...+GRS($i)>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence.  All positive integers
occur, so this simply means integer C<$value E<gt>= 1>.

=back

=head1 FORMULAS

=head2 Ith

The cumulative total GRS(0)+...+GRS(i-1) can be calculated from the 1-bits
of i.  Each 1-bit becomes a value 2^floor((pos+1)/2) in the total,

    bit    value
    ---    -----
     0       1
     1       2
     2       2
     3       4
     4       4
    ...     ...
     k      2^ceil(k/2)

The value is added or subtracted from the total according to the number of
11 bit pairs above that bit position, not including the bit itself,

    add value    if even count of adjacent 11 bit pairs above
    sub value    if odd count

For example i=27 is 110011 in binary so

    1      -1      bit0 low bit
    1      -2      bit1
    0              bit2
    1      +4      bit3
    1      +4      bit4 high bit
          ----
            5      cumulative value GRS(0)+...+GRS(26)

The second lowest bit is negated as value -2 because there's one "11" bit
pair above it, and -1 the same because above and not including that bit
there's just one "11" bit pair.

Or for example i=31 is 11111 in binary so

    1      -1      bit0 low bit
    1      +2      bit1 
    1      -2      bit2 
    1      +4      bit3 
    1      +4      bit4 high bit
          ----
            7      cumulative total GRS(0)+...+GRS(30)

Here at bit2 the value is -2 because there's one adjacent 11 above, not
including bit2 itself.  Then at bit1 there's two 11 pairs above so +2, and
at bit0 there's three so -1.

The total can be formed by examining the bits high to low and counting
adjacent 11 bits on the way down to add or subtract.  Or it can be formed
from low to high by negating the total so far when a 11 pair is encountered.

For an inclusive sum GRS(0)+...+GRS(i) as per this module, the extra GRS(i)
can be worked into the calculation by its GRS definition +1 or -1 according
to the total number of adjacent 11 bits.  This can be thought of as an extra
value 1 below the least significant bit.  For example i=27 inclusive

           +1      below all bits
    1      -1      bit0 low bit
    1      -2      bit1
    0              bit2
    1      +4      bit3
    1      +4      bit4 high bit
          ----
            5      cumulative value GRS(0)+...+GRS(27)

For low to high calculation this lowest +/-1 can be handled simply by
starting the total at 1.  It then becomes +1 or -1 by the negations as 11s
are encountered for the rest of the bit handling.

    total = 1   # initial value below all bits to be inclusive GRS(i)
    power = 1   # 2^ceil(bitpos/2)
    thisbit = take bit from low end of i

    loop
      nextbit = take bit from low end of i
      if thisbit&&nextbit
        then total = -total    # negate lower values added
      if thisbit
        then total += power
      thisbit = nextbit

      power *= 2
      exit loop if i==0

      nextbit = bit from low end of i
      if thisbit&&nextbit
        then total = -total    # negate lower values added
      if thisbit
        then total += power
      thisbit = nextbit
      exit loop if i==0
    endloop

    total += power     # final for highest 1-bit in i
    # total=GRS(0)+...+GRS(i)

This sort of calculation arises implicitly in the alternate paper folding
curve to calculate X,Y for a given N point on the curve.  But that
calculation does a simultaneous using the base 4 digits of N.

    X=GRStotal(ceil(N/2))
    Y=GRStotal(floor(N/2))

=cut

# ENHANCE-ME: Cross-ref to AlternatePaper formulas section when its X,Y
# calculation is described.

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::GolayRudinShapiro>

L<Math::PlanePath::AlternatePaper>

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
