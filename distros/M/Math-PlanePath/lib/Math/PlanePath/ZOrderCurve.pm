# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


# math-image --path=ZOrderCurve,radix=3 --all --output=numbers
# math-image --path=ZOrderCurve --values=Fibbinary --text
#
# increment N+1 changes low 1111 to 10000
# X bits change 011 to 000, no carry, decreasing by number of low 1s
# Y bits change 011 to 100, plain +1
#
# cf A105186 replace odd position ternary digits with 0
#


package Math::PlanePath::ZOrderCurve;
use 5.004;
use strict;
use List::Util 'max';

use vars '$VERSION', '@ISA';
$VERSION = 127;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'parameter_info_array',
  'round_up_pow',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;
use constant class_x_negative => 0;
use constant class_y_negative => 0;
*xy_is_visited = \&Math::PlanePath::Base::Generic::xy_is_visited_quad1;

use constant dx_maximum => 1;
use constant dy_maximum => 1;
use constant absdx_minimum => 1;   # X coord always changes
use constant dsumxy_maximum => 1; # forward straight only

sub dir_maximum_dxdy {
  my ($self) = @_;
  return (1, 1 - $self->{'radix'});  # SE diagonal
}

sub turn_any_straight {
  my ($self) = @_;
  return ($self->{'radix'} != 2);  # radix=2 never straight
}
sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  return $self->{'radix'} - 1;
}
sub _UNDOCUMENTED__turn_any_right_at_n {
  my ($self) = @_;
  return $self->{'radix'};
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);

  my $radix = $self->{'radix'};
  if (! defined $radix || $radix <= 2) { $radix = 2; }
  $self->{'radix'} = $radix;

  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### ZOrderCurve n_to_xy(): $n
  if ($n < 0) {
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  my $int = int($n);
  $n -= $int;   # fraction part

  my $radix = $self->{'radix'};
  my @ndigits = digit_split_lowtohigh ($int, $radix);
  ### @ndigits
  unless ($#ndigits & 1) {
    push @ndigits, 0;  # pad @ndigits to an even number of digits
  }

  my @xdigits;
  my @ydigits;
  while (@ndigits) {
    push @xdigits, shift @ndigits;  # low to high
    push @ydigits, shift @ndigits;  # low to high
  }
  ### @xdigits
  ### @ydigits

  my $zero = ($int * 0); # inherit bigint 0
  my $x = digit_join_lowtohigh (\@xdigits, $radix, $zero);
  my $y = digit_join_lowtohigh (\@ydigits, $radix, $zero);

  if ($n) {
    # fraction part
    my $dx = 1;
    my $dy = $zero;
    my $radix_minus_1 = $radix - 1;
    foreach my $i (0 .. $#xdigits) {  # low to high
      if ($xdigits[$i] != $radix_minus_1) {
        ### lowest non-9 is an X digit, so dx=1 dy=0,-R+1,-R^2+1,etc
        last;
      }
      $dy = ($dy * $radix) - $radix_minus_1;  # 1-$radix**$i
      if ($ydigits[$i] != $radix_minus_1) {
        ### lowest non-9 is a Y digit, so dy=1, dx=-R+1,-R^2+1,etc
        $dx = $dy;
        $dy = 1;
        last;
      }
    }
    ### $dx
    ### $dy
    $x = $n*$dx + $x;
    $y = $n*$dy + $y;
  }

  return ($x, $y);
}

sub n_to_dxdy {
  my ($self, $n) = @_;
  ### ZOrderCurve n_to_xy(): $n

  if ($n < 0) {
    return;
  }

  my $int = int($n);
  $n -= $int;   # fraction part

  if (is_infinite($int)) {
    return ($int,$int);
  }

  my $radix = $self->{'radix'};
  my $digit = _divrem_mutate($int,$radix);   # lowest digit of N
  if ($digit < $radix - 2) {
    # N an integer at lowdigit<radix-2, so dx=1,dy=0
    return (1, 0);
  }

  my $radix_minus_1 = $radix - 1;
  my $scan_for_dx = ($digit == $radix_minus_1);
  unless ($scan_for_dx) {
    ### assert: $digit == $radix-2
    unless ($n) {
      # N an integer with lowdigit==radix-2, so dx=1,dy=0
      return (1, 0);
    }
    # scan digits for next_dx,next_dy
  }

  my $power = $radix + ($int*0);  # $radix**$i, inherit bigint

  for (;;) {
    if (_divrem_mutate($int,$radix) != $radix_minus_1) {
      ### lowest non-9 is a Y digit, so dy=1, dx=-R+1,-R^2+1,etc
      if ($scan_for_dx) {
        # scanned for dx=1-power,dy=1 have nextdx=1,nextdy=0
        # frac*(nextdx-dx) + dx = n*(1-(1-power))+(1-power)
        #                       = n*(1-1+power))+1-power
        #                       = n*power+1-power
        #                       = (n-1)*power+1
        # frac*(nextdy-dy) + dy = n*(0-1) + 1
        #                       = 1-n
        return (($n-1)*$power + 1,
                1-$n);

      } else {
        # scanned for nextdx=1-power,nextdy=1 have dx=1,dy=0
        # frac*(nextdx-dx) + dx = n*((1-power)-1)+1
        #                       = n*(1-power-1)+1
        #                       = n*-power+1
        #                       = 1 - n*power
        # frac*(nextdy-dy) + dy = n*(1-0) + 0
        #                       = n
        return (1 - $n*$power,
                $n);
      }
    }

    if (_divrem_mutate($int,$radix) != $radix_minus_1) {
      ### lowest non-9 is an X digit, so dx=1 dy=0,-R+1,-R^2+1,etc
      $power -= 1;
      if ($scan_for_dx) {
        # scanned for dx=1,dy=1-power have nextdx=1,nextdy=0
        # frac*(nextdx-dx) + dx = n*(1-1)+1
        #                       = 1
        # frac*(nextdy-dy) + dy = n*(0-(1-power)) + (1-power)
        #                       = n*(-1+power) + 1-power
        #                       = -n + n*power + 1 - power
        #                       = 1-n + (n-1)*power
        #                       = (n-1)*(power-1)
        return (1,
                ($n-1) * $power);
      } else {
        # scanned for nextdx=1,nextdy=1-power have dx=1,dy=0
        # frac*(nextdx-dx) + dx = n*(1-1) + 1
        #                       = 1
        # frac*(nextdy-dy) + dy = n*((1-power) - 0) + 0
        #                       = n*(1-power)
        return (1,
                -$n*$power);
      }
    }

    $power *= $radix;
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### ZOrderCurve xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($x < 0 || $y < 0) { return undef; }
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  my $radix = $self->{'radix'};
  my $zero = ($x * 0 * $y); # inherit bigint 0

  my @x = digit_split_lowtohigh($x,$radix);
  my @y = digit_split_lowtohigh($y,$radix);
  return digit_join_lowtohigh ([ _digit_interleave (\@x, \@y) ],
                               $radix,
                               $zero);
}

# return list of @$xaref interleaved with @$yaref
# ($xaref->[0], $yaref->[0], $xaref->[1], $yaref->[1], ...)
#
sub _digit_interleave {
  my ($xaref, $yaref) = @_;
  my @ret;
  foreach my $i (0 .. max($#$xaref,$#$yaref)) {
    push @ret, $xaref->[$i] || 0;
    push @ret, $yaref->[$i] || 0;
  }
  return @ret;
}

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }  # x1 smaller
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); }  # y1 smaller

  if ($y2 < 0 || $x2 < 0) {
    return (1, 0); # rect all negative, no N
  }

  if ($x1 < 0) { $x1 *= 0; }   # "*=" to preserve bigint x1 or y1
  if ($y1 < 0) { $y1 *= 0; }

  # monotonic increasing in X and Y directions, so this is exact
  return ($self->xy_to_n ($x1, $y1),
          $self->xy_to_n ($x2, $y2));
}

#------------------------------------------------------------------------------
# levels

#           arms=1
# level 1  0..0  = 1
# level 1  0..3  = 4
# level 2  0..15 = 16
#            4^k-1

# shared by Math::PlanePath::GrayCode and others
sub level_to_n_range {
  my ($self, $level) = @_;
  return (0,  $self->{'radix'}**(2*$level) - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  $n = round_nearest($n);
  my ($pow, $exp) = round_up_pow ($n+1, $self->{'radix'}*$self->{'radix'});
  return $exp;
}

#------------------------------------------------------------------------------
1;
__END__

=for stopwords Ryde Math-PlanePath Karatsuba undrawn fibbinary eg Radix radix radix-1 RxR OEIS

=head1 NAME

Math::PlanePath::ZOrderCurve -- alternate digits to X and Y

=head1 SYNOPSIS

 use Math::PlanePath::ZOrderCurve;

 my $path = Math::PlanePath::ZOrderCurve->new;
 my ($x, $y) = $path->n_to_xy (123);

 # or another radix digits ...
 my $path3 = Math::PlanePath::ZOrderCurve->new (radix => 3);

=head1 DESCRIPTION

This path puts points in a self-similar Z pattern described by G.M. Morton,

      7  |   42  43  46  47  58  59  62  63
      6  |   40  41  44  45  56  57  60  61
      5  |   34  35  38  39  50  51  54  55
      4  |   32  33  36  37  48  49  52  53
      3  |   10  11  14  15  26  27  30  31
      2  |    8   9  12  13  24  25  28  29
      1  |    2   3   6   7  18  19  22  23
     Y=0 |    0   1   4   5  16  17  20  21  64  ...
         +---------------------------------------
            X=0   1   2   3   4   5   6   7   8

The first four points make a "Z" shape if written with Y going downwards
(inverted if drawn upwards as above),

     0---1       Y=0
        /
      /
     2---3       Y=1

Then groups of those are arranged as a further Z, etc, doubling in size each
time.

     0   1      4   5       Y=0
     2   3 ---  6   7       Y=1
             /
            /
           /
     8   9 --- 12  13       Y=2
    10  11     14  15       Y=3

Within an power of 2 square 2x2, 4x4, 8x8, 16x16 etc (2^k)x(2^k), all the N
values 0 to 2^(2*k)-1 are within the square.  The top right corner 3, 15,
63, 255 etc of each is the 2^(2*k)-1 maximum.

Along the X axis N=0,1,4,5,16,17,etc is the integers with only digits 0,1 in
base 4.  Along the Y axis N=0,2,8,10,32,etc is the integers with only digits
0,2 in base 4.  And along the X=Y diagonal N=0,3,12,15,etc is digits 0,3 in
base 4.

In the base Z pattern it can be seen that transposing to Y,X means swapping
parts 1 and 2.  This applies in the sub-parts too so in general if N is at
X,Y then changing base 4 digits 1E<lt>-E<gt>2 gives the N at the transpose
Y,X.  For example N=22 at X=6,Y=1 is base-4 "112", change 1E<lt>-E<gt>2 is
"221" for N=41 at X=1,Y=6.

=head2 Power of 2 Values

Plotting N values related to powers of 2 can come out as interesting
patterns.  For example displaying the N's which have no digit 3 in their
base 4 representation gives

    *
    * *
    *   *
    * * * *
    *       *
    * *     * *
    *   *   *   *
    * * * * * * * *
    *               *
    * *             * *
    *   *           *   *
    * * * *         * * * *
    *       *       *       *
    * *     * *     * *     * *
    *   *   *   *   *   *   *   *
    * * * * * * * * * * * * * * * *

The 0,1,2 and not 3 makes a little 2x2 "L" at the bottom left, then
repeating at 4x4 with again the whole "3" position undrawn, and so on.  This
is the Sierpinski triangle (a rotated version of
L<Math::PlanePath::SierpinskiTriangle>).  The blanks are also a visual
representation of 1-in-4 cross-products saved by recursive use of the
Karatsuba multiplication algorithm.

Plotting the fibbinary numbers (eg. L<Math::NumSeq::Fibbinary>) which are N
values with no adjacent 1 bits in binary makes an attractive tree-like
pattern,

    *
    **
    *
    ****
    *
    **
    *   *
    ********
    *
    **
    *
    ****
    *       *
    **      **
    *   *   *   *
    ****************
    *                               *
    **                              **
    *                               *
    ****                            ****
    *                               *
    **                              **
    *   *                           *   *
    ********                        ********
    *               *               *               *
    **              **              **              **
    *               *               *               *
    ****            ****            ****            ****
    *       *       *       *       *       *       *       *
    **      **      **      **      **      **      **      **
    *   *   *   *   *   *   *   *   *   *   *   *   *   *   *   *
    ****************************************************************

The horizontals arise from N=...0a0b0c for bits a,b,c so Y=...000 and
X=...abc, making those N values adjacent.  Similarly N=...a0b0c0 for a
vertical.

=head2 Radix

The C<radix> parameter can do the same N E<lt>-E<gt> X/Y digit splitting in
a higher base.  For example radix 3 makes 3x3 groupings,

     radix => 3

      5  |  33  34  35  42  43  44
      4  |  30  31  32  39  40  41
      3  |  27  28  29  36  37  38  45  ...
      2  |   6   7   8  15  16  17  24  25  26
      1  |   3   4   5  12  13  14  21  22  23
     Y=0 |   0   1   2   9  10  11  18  19  20
         +--------------------------------------
           X=0   1   2   3   4   5   6   7   8

Along the X axis N=0,1,2,9,10,11,etc is integers with only digits 0,1,2 in
base 9.  Along the Y axis digits 0,3,6, and along the X=Y diagonal digits
0,4,8.  In general for a given radix it's base R*R with the R many digits of
the first RxR block.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::ZOrderCurve-E<gt>new ()>

=item C<$path = Math::PlanePath::ZOrderCurve-E<gt>new (radix =E<gt> $r)>

Create and return a new path object.  The optional C<radix> parameter gives
the base for digit splitting (the default is binary, radix 2).

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional positions give an X,Y position along a straight line between the
integer positions.  The lines don't overlap, but the lines between bit
squares soon become rather long and probably of very limited use.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return an integer point number for coordinates C<$x,$y>.  Each integer N is
considered the centre of a unit square and an C<$x,$y> within that square
returns N.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, $radix**(2*$level) - 1)>.

=back

=head1 FORMULAS

=head2 N to X,Y

The coordinate calculation is simple.  The bits of X and Y are every second
bit of N.  So if N = binary 101010 then X=000 and Y=111 in binary, which is
the N=42 shown above at X=0,Y=7.

With the C<radix> parameter the digits are treated likewise, in the given
radix rather than binary.

If N includes a fraction part then it's applied to a straight line towards
point N+1.  The +1 of N+1 changes X and Y according to how many low radix-1
digits there are in N, and thus in X and Y.  In general if the lowest non
radix-1 is in X then

    dX=1
    dY = - (R^pos - 1)           # pos=0 for lowest digit

The simplest case is when the lowest digit of N is not radix-1, so dX=1,dY=0
across.

If the lowest non radix-1 is in Y then

    dX = - (R^(pos+1) - 1)       # pos=0 for lowest digit
    dY = 1

If all digits of X and Y are radix-1 then the implicit 0 above the top of X
is considered the lowest non radix-1 and so the first case applies.  In the
radix=2 above this happens for instance at N=15 binary 1111 so X = binary 11
and Y = binary 11.  The 0 above the top of X is at pos=2 so dX=1,
dY=-(2^2-1)=-3.

=head2 Rectangle to N Range

Within each row the N values increase as X increases, and within each column
N increases with increasing Y (for all C<radix> parameters).

So for a given rectangle the smallest N is at the lower left corner
(smallest X and smallest Y), and the biggest N is at the upper right
(biggest X and biggest Y).

=head1 OEIS

This path is in Sloane's Online Encyclopedia of Integer Sequences in various
forms,

=over

L<http://oeis.org/A059905> (etc)

=back

    radix=2
      A059905    X coordinate
      A059906    Y coordinate

      A000695    N on X axis       (base 4 digits 0,1 only)
      A062880    N on Y axis       (base 4 digits 0,2 only)
      A001196    N on X=Y diagonal (base 4 digits 0,3 only)

      A057300    permutation N at transpose Y,X (swap bit pairs)

    radix=3
      A163325    X coordinate
      A163326    Y coordinate
      A037314    N on X axis, base 9 digits 0,1,2
      A208665    N on X=Y diagonal, base 9 digits 0,3,6
      A163327    permutation N at transpose Y,X (swap trit pairs)

    radix=4
      A126006    permutation N at transpose Y,X (swap digit pairs)

    radix=10
      A080463    X+Y of radix=10 (from N=1 onwards)
      A080464    X*Y of radix=10 (from N=10 onwards)
      A080465    abs(X-Y), from N=10 onwards
      A051022    N on X axis (base 100 digits 0 to 9)

    radix=16
      A217558    permutation N at transpose Y,X (swap digit pairs)

And taking X,Y points in the Diagonals sequence then the value of the
following sequences is the N of the C<ZOrderCurve> at those positions.

    radix=2
      A054238    numbering by diagonals, from same axis as first step
      A054239      inverse permutation

    radix=3
      A163328    numbering by diagonals, same axis as first step
      A163329      inverse permutation
      A163330    numbering by diagonals, opp axis as first step
      A163331      inverse permutation

C<Math::PlanePath::Diagonals> numbers points from the Y axis down, which is
the opposite axis to the C<ZOrderCurve> first step along the X axis, so a
transpose is needed to give A054238.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::PeanoCurve>,
L<Math::PlanePath::HilbertCurve>,
L<Math::PlanePath::ImaginaryBase>,
L<Math::PlanePath::CornerReplicate>,
L<Math::PlanePath::DigitGroups>

X<Arndt, Jorg>X<fxtbook>C<http://www.jjj.de/fxt/#fxtbook> (section 1.31.2)

L<Algorithm::QuadTree>, L<DBIx::SpatialKey>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

This file is part of Math-PlanePath.

Math-PlanePath is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-PlanePath is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

=cut
