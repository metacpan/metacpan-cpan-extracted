# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


# math-image --path=QuintetReplicate --lines --scale=10
# math-image --path=QuintetReplicate --output=numbers --all
# math-image --path=QuintetReplicate,numbering_type=rotate --output=numbers --all
# math-image --path=QuintetReplicate --expression='5**i'

package Math::PlanePath::QuintetReplicate;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 125;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_up_pow',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant parameter_info_array =>
  [ { name            => 'numbering_type',
      display         => 'Numbering',
      share_key       => 'numbering_type_rotate',
      type            => 'enum',
      default         => 'fixed',
      choices         => ['fixed','rotate'],
      choices_display => ['Fixed','Rotate'],
      description     => 'Fixed or rotating sub-part numbering.',
    },
  ];

use constant n_start => 0;
use constant xy_is_visited => 1;
use constant x_negative_at_n => 3;
use constant y_negative_at_n => 4;

#------------------------------------------------------------------------------
sub new {
  my $self = shift->SUPER::new (@_);
  $self->{'numbering_type'} ||= 'fixed';  # default
  return $self;
}

#     10        7
#         2  8  5  6
#      3  0  1  9
#         4

# my @digit_to_xbx = (0,1,0,-1,0);
# my @digit_to_xby = (0,0,-1,0,1);
# my @digit_to_y = (0,0,1,0,-1);
# my @digit_to_yby = (0,0,1,0,-1);
#     $x += $bx * $digit_to_xbx[$digit] + $by * $digit_to_xby[$digit];
#     $y += $bx * $digit_to_ybx[$digit] + $by * $digit_to_yby[$digit];

sub _digits_rotate_lowtohigh {
  my ($aref) = @_;
  my $rot = 0;
  foreach my $digit (reverse @$aref) {  # high to low
    if ($digit) {
      $rot += $digit-1;
      $digit = ($rot % 4) + 1;  # mutate $aref
    }
  }
}
sub _digits_unrotate_lowtohigh {
  my ($aref) = @_;
  my $rot = 0;
  foreach my $digit (reverse @$aref) {   # high to low
    if ($digit) {
      $digit = ($digit-1-$rot) % 4;  # mutate $aref
      $rot += $digit;
      $digit++;
    }
  }
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### QuintetReplicate n_to_xy(): $n

  if ($n < 0) {
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  # any value in long frac lines like this?
  {
    my $int = int($n);
    if ($n != $int) {
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $frac = $n - $int;  # inherit possible BigFloat
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int; # BigFloat int() gives BigInt, use that
  }

  my $x = my $y = my $by = ($n * 0); # inherit bignum 0
  my $bx = $x+1; # inherit bignum 1

  my @digits = digit_split_lowtohigh($n,5);
  if ($self->{'numbering_type'} eq 'rotate') {
    _digits_rotate_lowtohigh(\@digits);
  }
  foreach my $digit (@digits) {
    ### $digit
    ### $bx
    ### $by

    if ($digit == 1) {
      $x += $bx;
      $y += $by;
    } elsif ($digit == 2) {
      $x -= $by;  # i*(bx+i*by) = rotate +90
      $y += $bx;
    } elsif ($digit == 3) {
      $x -= $bx;  # -1*(bx+i*by) = rotate 180
      $y -= $by;
    } elsif ($digit == 4) {
      $x += $by;  # -i*(bx+i*by) = rotate -90
      $y -= $bx;
    }

    # power (bx,by) = (bx + i*by)*(i+2)
    #
    ($bx,$by) = (2*$bx-$by, 2*$by+$bx);
  }

  return ($x, $y);
}

# digit   modulus 2Y+X mod 5
#   2        2
# 3 0 1    1 0 4
#   4        3
#
my @modulus_to_x = (0,-1,0,0,1);
my @modulus_to_y = (0,0,1,-1,0);
my @modulus_to_digit = (0,3,2,4,1);

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### QuintetReplicate xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  foreach my $overflow (2*$x + 2*$y, 2*$x - 2*$y) {
    if (is_infinite($overflow)) { return $overflow; }
  }

  my $zero = ($x * 0 * $y);  # inherit bignum 0
  my @n; # digits low to high

  while ($x || $y) {
    ### at: "$x,$y"

    my $m = (2*$y - $x) % 5;
    ### $m
    ### digit: $modulus_to_digit[$m]

    push @n, $modulus_to_digit[$m];

    $x -= $modulus_to_x[$m];
    $y -= $modulus_to_y[$m];
    ### modulus shift to: "$x,$y"

    # div i+2,
    # = (i*y + x) * (i-2)/-5
    # = (-y -2*y*i + x*i -2*x) / -5
    # = (y + 2*y*i - x*i + 2*x) / 5
    # = (2x+y + (2*y-x)i) / 5
    #
    # ### assert: ((2*$x + $y) % 5) == 0
    # ### assert: ((2*$y - $x) % 5) == 0

    ($x,$y) = ((2*$x + $y) / 5,
               (2*$y - $x) / 5);
  }
  if ($self->{'numbering_type'} eq 'rotate') {
    _digits_unrotate_lowtohigh(\@n);
  }
  return digit_join_lowtohigh (\@n, 5, $zero);
}

# level   min x^2+y^2 for N >= 5^k
#   0      1   at 1,0
#   1      2   at 1,1  factor 2
#   2      5   at 1,2  factor 2.5
#   3     16   at 0,4  factor 3.2
#   4     65   at -4,7  factor 4.0625
#   5    296   at -14,10  factor 4.55384615384615
#   6   1405   at -37,6  factor 4.74662162162162
#   7   6866   at -79,-25  factor 4.88683274021352
#
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  $x1 = abs($x1);
  $x2 = abs($x2);
  $y1 = abs($y1);
  $y2 = abs($y2);
  if ($x1 < $x2) { $x1 = $x2; }
  if ($y1 < $y2) { $y1 = $y2; }
  my $rsquared = $x1*$x1 + $y1*$y1;
  if (is_infinite($rsquared)) {
    return (0, $rsquared);
  }

  my $x = 1;
  my $y = 0;
  for (my $level = 1; ; $level++) {
    # (x+iy)*(2+i)
    ($x,$y) = (2*$x - $y, $x + 2*$y);
    if (abs($x) >= abs($y)) {
      $x -= ($x<=>0);
    } else {
      $y -= ($y<=>0);
    }

    unless ($x*$x + $y*$y <= $rsquared) {
      return (0, 5**$level - 1);
    }
  }
}

#------------------------------------------------------------------------------
# levels

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0, 5**$level - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  my ($pow, $exp) = round_up_pow ($n+1, 5);
  return $exp;
}


#------------------------------------------------------------------------------

# Return true if $n is on the boundary of $level.
#
sub _UNDOCUMENTED__n_is_boundary_level {
  my ($self, $n, $level) = @_;

  ### _UNDOCUMENTED__n_is_boundary_level(): "n=$n"

  my @digits = digit_split_lowtohigh($n,5);
  ### @digits
  if ($self->{'numbering_type'} eq 'fixed') {
    _digits_unrotate_lowtohigh(\@digits);
    ### @digits
  }

  # no high 0 digit (and nothing too big)
  if (@digits != $level) {
    return 0;
  }

  # no 0 digit anywhere else
  if (grep {$_==0} @digits) {
    return 0;
  }

  # skip high digit and all 1 digits
  pop @digits;
  @digits = grep {$_ != 1} @digits;

  for (my $i = 0; $i < $#digits; $i++) {  # low to high
    if (($digits[$i+1] == 3 && $digits[$i] <= 3)        # 33, 32
        || ($digits[$i+1] == 4 && $digits[$i] == 4)) {  # 44
      ### no, pair at: $i
      return 0;
    }
  }
  return 1;
}


#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Math-PlanePath

=head1 NAME

Math::PlanePath::QuintetReplicate -- self-similar "+" tiling

=head1 SYNOPSIS

 use Math::PlanePath::QuintetReplicate;
 my $path = Math::PlanePath::QuintetReplicate->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is a self-similar tiling of the plane with "+" shapes.  It's the same
kind of tiling as the C<QuintetCurve> (and C<QuintetCentres>), but with the
middle square of the "+" shape centred on the origin.

            12                         3

        13  10  11       7             2

            14   2   8   5   6         1

        17   3   0   1   9         <- Y=0

    18  15  16   4  22                -1

        19      23  20  21            -2

                    24                -3

                 ^
    -4 -3 -2 -1 X=0  1  2  3  4

The base pattern is a "+" shape

        +---+
        | 2 |
    +---+---+---+
    | 3 | 0 | 1 |
    +---+---+---+
        | 4 |
        +---+      

which is then replicated

         +--+
         |  |
      +--+  +--+  +--+
      |   10   |  |  |
      +--+  +--+--+  +--+
         |  |  |   5    |
      +--+--+  +--+  +--+
      |  |   0    |  |
   +--+  +--+  +--+--+
   |   15   |  |  |
   +--+  +--+--+  +--+
      |  |  |   20   |
      +--+  +--+  +--+
               |  |
               +--+

The effect is to tile the whole plane.  Notice the centres 0,5,10,15,20 are
the same "+" shape but positioned around at angle atan(1/2)=26.565 degrees.
The relative positioning in each of those parts is the same, so at 5 the
successive 6,7,8,9 are E,N,W,S like the base shape.

=cut

# not in OEIS: 26.565051177077989351
# not A242723 which starts 116.565

=pod

=head2 Complex Base

This tiling corresponds to expressing a complex integer X+i*Y as

    base b=2+i
    X+Yi = a[n]*b^n + ... + a[2]*b^2 + a[1]*b + a[0]

where each digit position factor a[i] corresponds to N digits

    N digit     a[i]
    -------    ------
       0          0
       1          1
       2          i
       3         -1
       4         -i

=cut

# GP-DEFINE  b = 2+I;
# GP-DEFINE  QuintetDigit(d) = [0,1,I,-1,-I][d+1];
# GP-DEFINE  QuintetPoint(n) = \
# GP-DEFINE    subst(Pol(apply(QuintetDigit,digits(n,5))),'x,b);
# GP-Test  QuintetPoint(0) == 0
# GP-Test  QuintetPoint(1) == 1
# GP-Test  QuintetPoint(2) == I
# GP-Test  QuintetPoint(5) == 2+I

=pod

The base b is at an angle arg(b) = atan(1/2) = 26.56 degrees as seen at N=5
above.  Successive powers b^2, b^3, b^4 etc at N=5^level rotate around by
that much each time.

    Npow = 5^level  at b^level
    angle(Npow) = level*26.56 degrees
    radius(Npow) = sqrt(5) ^ level

=cut

# GP-DEFINE  nearly_equal_epsilon = 1e-15;
# GP-DEFINE  nearly_equal(x,y, epsilon=nearly_equal_epsilon) = \
# GP-DEFINE    abs(x-y) < epsilon;
# GP-DEFINE  to_base5(n) = fromdigits(digits(n,5));
# GP-DEFINE  from_base5(n) = fromdigits(digits(n),5);

# GP-DEFINE  b_angle = arg(b);
# GP-DEFINE  b_angle_degrees = b_angle * 180/Pi;
# GP-Test  nearly_equal( b_angle, atan(1/2) )

# GP-Test  b_angle_degrees > 26.56
# GP-Test  b_angle_degrees < 26.56+1/10^2

# cf
# A242723  decimal degrees 180*(1 - arctan(2)/Pi) = 116.56...
# GP-Test  nearly_equal( 180*(1-atan(2)/Pi), b_angle_degrees+90 )

# A073000  atan(1/2) radians = 0.463...

=pod

The path can be reckoned bottom-up as a new low digit of N expanding each
unit square to the base "+" shape.

                             +---C      
    D-------C                | 2 |      
    |       |            D---+---+---+  
    |       |     =>     | 3 | 0 | 1 |  
    |       |            +---+---+---B  
    A-------B                | 4 |      
                             A---+      

Side A-B becomes a 3-segment S.  Such an expansion is the same as the
TerdragonCurve or GosperSide, but here turns of 90 degrees.  Like GosperSide
there is no touching or overlap of the sides expansions, so boundary length
4*3^level.

=head2 Rotate Numbering

Parameter C<numbering_type =E<gt> 'rotate'> applies a rotation to the
numbering in each sub-part according to its location around the preceding
level.

The effect can be illustrated by writing N in base-5.  Part 10-14 is the
same as the middle 0-4.  Part 20-24 has a rotation by +90 degrees.  Part
30-34 has rotation by +180 degrees, and part 40-44 by +270 degrees.

            21
          /  |                   
        22  20  24      12           numbering_type => 'rotate' 
          \    /      /    \             N shown in base-5
            23   2  13  10--11
               /   \   \
        34   3   0-- 1  14
           \   \  
    31--30  33   4  41
      \    /       /   \
        32      43  40  42
                     | /
                    41

=cut

# cf
# math-image --path=QuintetReplicate,numbering_type=rotate --output=numbers --all

=pod

Notice this means in each part the 11, 21, 31, etc, points are directed
away from the middle in the same way, relative to the sub-part locations.

Working through the expansions gives the following rule for when an N is
on the boundary of level k,

    write N in base-5 digits  (empty string if k=0)
    if length < k then non-boundary
    ignore high digit and all 1 digits
    if any pair 32, 33, 44 then non-boundary

A 0 digit is the middle of a block, so always non-boundary.  After that the
4,1,2,3 parts variously expand with rotations so that a 44 is enclosed on
the clockwise side and 32 and 33 on the anti-clockwise side.

=cut

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::QuintetReplicate-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 5**$level - 1)>.

=back

=head1 FORMULAS

=head2 Axis Rotations

The digits positions 1,2,3,4 go around +90deg each, so the N for rotation by
+90 is each digit +1, cycling around.

    rot+90(N) = 0, 2, 3, 4, 1, 10, 12, 13, 14, 11, 15, ... decimal
              = 0, 2, 3, 4, 1, 20, 22, 23, 24, 21, 30, ... base5

    rot-90(N) = 0, 4, 1, 2, 3, 20, 24, 21, 22, 23,  5, ... decimal
              = 0, 4, 1, 2, 3, 40, 44, 41, 42, 43, 10, ... base5

    rot180(N) = 0, 3, 4, 1, 2, 15, 18, 19, 16, 17, 20, ... decimal
              = 0, 3, 4, 1, 2, 30, 33, 34, 31, 32, 40, ... base5

=cut

# GP-DEFINE  digit_plus1(d)  = [0,2,3,4,1][d+1];
# GP-DEFINE  digit_plus2(d)  = [0,3,4,1,2][d+1];
# GP-DEFINE  digit_minus1(d) = [0,4,1,2,3][d+1];
# GP-DEFINE  N_rotate_plus90(n) = fromdigits(apply(digit_plus1, digits(n,5)),5);
# GP-DEFINE  N_rotate_180(n)    = fromdigits(apply(digit_plus2, digits(n,5)),5);
# GP-DEFINE  N_rotate_minus90(n)= fromdigits(apply(digit_minus1,digits(n,5)),5);

# GP-Test  my(v=[0,2,3,4,1,10,12,13,14,11,15,17]); /* samples shown */ \
# GP-Test    vector(#v,n,n--; N_rotate_plus90(n)) == v
# GP-Test  my(v=[0,2,3,4,1,20,22,23,24,21,30,32]); /* samples shown */ \
# GP-Test    vector(#v,n,n--; to_base5(N_rotate_plus90(n))) == v

# GP-Test  my(v=[0,4,1,2,3,20,24,21,22,23,5,9]); /* samples shown */ \
# GP-Test    vector(#v,n,n--; N_rotate_minus90(n)) == v
# GP-Test  my(v=[0,4,1,2,3,40,44,41,42,43,10,14]); /* samples shown */ \
# GP-Test    vector(#v,n,n--; to_base5(N_rotate_minus90(n))) == v

# GP-Test  my(v=[0,3,4,1,2,15,18,19,16,17,20,23]); /* samples shown */ \
# GP-Test    vector(#v,n,n--; N_rotate_180(n)) == v
# GP-Test  my(v=[0,3,4,1,2,30,33,34,31,32,40,43]); /* samples shown */ \
# GP-Test    vector(#v,n,n--; to_base5(N_rotate_180(n))) == v

# GP-Test  vector(500,n,n--; QuintetPoint(N_rotate_plus90(n))) == \
# GP-Test  vector(500,n,n--; I*QuintetPoint(n))

# GP-Test  vector(500,n,n--; QuintetPoint(N_rotate_minus90(n))) == \
# GP-Test  vector(500,n,n--; -I*QuintetPoint(n))

# GP-Test  vector(500,n,n--; QuintetPoint(N_rotate_180(n))) == \
# GP-Test  vector(500,n,n--; -QuintetPoint(n))

# not in OEIS: 2, 3, 4, 1, 10, 12, 13, 14, 11, 15  \\ plus90
# not in OEIS: 2, 3, 4, 1, 20, 22, 23, 24, 21, 30
# not in OEIS: 4, 1, 2, 3, 20, 24, 21, 22, 23,  5  \\ minus90
# not in OEIS: 4, 1, 2, 3, 40, 44, 41, 42, 43, 10
# not in OEIS: 3, 4, 1, 2, 15, 18, 19, 16, 17, 20  \\ 180
# not in OEIS: 3, 4, 1, 2, 30, 33, 34, 31, 32, 40

=pod

=head2 X,Y Extents

The maximum X in a given level N=0 to 5^k-1 can be calculated from the
replications.  A given high digit 1 to 4 has sub-parts located at
b^k*i^(d-1).  Those sub-parts are all the same, so the one with maximum
real(b^k*i^(d-1)) contains the maximum X.

    N_xmax_digit(j) = d=1,2,3,4 where real(i^(d-1) * b^j) is maximum
                    = 1,1,4,4,4,4,3,3,3,2,2,2,1,1, ...

                 k-1
    N_xmax(k) = digits N_xmax_digit(j)    low digit j=0
                 j=0
              = 0, 1, 6, 106, 606, 3106, 15606, ...    decimal
              = 0, 1, 11, 411, 4411, 44411, 444411, ...  base5

                k-1
    z_xmax(k) = sum  i^d[j] * b^j
                j=0      each d[j] with real(i^d[j] * b^j) maximum
              = 0, 1, 3+i, 7-2*i, 18-4*i, 42+3*i, 83+41*i, ...

    xmax(k) = real(z_xmax(k))
            = 0, 1, 3, 7, 18, 42, 83, 200, 478, 1005, ...

=cut

# GP-DEFINE  N_xmax_digit(j) = \
# GP-DEFINE    my(p=b^j,d); vecmax(vector(4,d,real(I^(d-1)*p)),&d); d;
# GP-Test  my(v=[1,1,4,4,4,4,3,3,3,2,2,2,1,1]); /* samples shown */ \
# GP-Test    vector(#v,j,j--; N_xmax_digit(j)) == v

# GP-DEFINE  N_xmax(k) = fromdigits(Vecrev(vector(k,j,j--; N_xmax_digit(j))),5);
# GP-Test  my(v=[0, 1, 6, 106, 606, 3106, 15606]); /* samples shown */ \
# GP-Test    vector(#v,j,j--; N_xmax(j)) == v
# GP-Test  my(v=[0, 1, 11, 411, 4411, 44411, 444411]); /* samples shown */ \
# GP-Test    vector(#v,j,j--; to_base5(N_xmax(j))) == v
# GP-Test  to_base5(N_xmax(51)) \
# GP-Test    == 233334441111222333444411122233334441111222333444411

# GP-DEFINE  z_xmax(k) = {
# GP-DEFINE    sum(j=0,k-1,
# GP-DEFINE        my(p=b^j, v=vector(4,d,(I^(d-1)*p)), i);
# GP-DEFINE        vecmax(real(v),&i);
# GP-DEFINE        v[i]);
# GP-DEFINE  }
# GP-Test  my(v=[0, 1, 3+I, 7-2*I, 18-4*I, 42+3*I, 83+41*I]); \
# GP-Test    vector(#v,k,k--; z_xmax(k)) == v

# GP-DEFINE  xmax(k) = real(z_xmax(k));
# GP-Test  my(v=[0, 1, 3, 7, 18, 42, 83, 200, 478, 1005]); \
# GP-Test    vector(#v,k,k--; xmax(k)) == v
# GP-Test  xmax(51) == 478296859096758296

# vector(15,k,k--; N_xmax_digit(k))
# vector(10,k,k--; N_xmax(k))
# vector(10,k,k--; to_base5(N_xmax(k)))
# not in OEIS: 6, 106, 606, 3106, 15606, 62481, 296856, 1468731, 5374981
# not in OEIS: 11, 411, 4411, 44411, 444411, 3444411, 33444411, 333444411

# vector(6,k,k--; z_xmax(k))
# vector(8,k, norm(z_xmax(k)))
# vector(10,k, real(z_xmax(k)))
# vector(10,k, imag(z_xmax(k)))
# not in OEIS: 1, 10, 53, 340, 1773, 8570, 40009, 229160   \\ norm
# not in OEIS: 1, 3, 7, 18, 42, 83, 200, 478, 1005, 2204   \\ real
# not in OEIS: 0, 1, -2, -4, 3, 41, -3, 26, 362, -356      \\ imag

=pod

For computer calculation these maximums can be calculated by the powers.
The digit parts can also be written in terms of the angle arg(b) =
atan(1/2).  For successive k, if adding atan(1/2) pushes the b^k angle past
+45deg then the preceding digit goes past -45deg and becomes the new
maximum X.  Write the angle as a fraction of 90deg (pi/2),

    F = atan(1/2) / (pi/2)  = 0.295167 ...

=cut

# GP-DEFINE  quintet_F = atan(1/2) / (Pi/2);
# GP-Test  quintet_F > 0.295167
# GP-Test  quintet_F < 0.295167 + 1/10^6
# not in OEIS: 0.295167235300866548350802

=pod

This is irrational since b^k is never on the X or Y axes.  That can be seen
since imag(b^k) mod 5 == 1 if k odd and == 4 if k even >= 2.  Similarly
real(b^k) mod 5 == 2,3 so not on the Y axis, or also anything on the Y axis
would have 3*k fall on the X axis.

=cut

# GP-Test  vector(100,k,k--; imag(b^k)%5) == \
# GP-Test  vector(100,k,k--; if(k==0,0, k%2==1,1,4))
# GP-Test  vector(100,k,k--; real(b^k)%5) == \
# GP-Test  vector(100,k,k--; if(k==0,1, k%2==1,2,3))

=pod

Digits low to high successively step back in a cycle 4,3,2,1 so that (with
mod giving 0 to 3),

    N_xmax_digit(j) = (-floor(F*j+1/2) mod 4) + 1

=cut

# GP-DEFINE  N_xmax_digit_by_floor(j) = (-floor(quintet_F*j+1/2) % 4) + 1;
# GP-Test  vector(1000,j,j--; N_xmax_digit_by_floor(j)) == \
# GP-Test  vector(1000,j,j--; N_xmax_digit(j))

# vector(35,j,j+=5; floor(quintet_F*j+1/2))
# vector(25,j,j+=3; floor(quintet_F*j))
# not in OEIS: 2,2,2,3,3,3,4,4,4,4,5,5,5,6,6,6,6,7,7,7,8,8,8,9,9,9,9,10,10,10
# not in OEIS: 2,2,2,3,3,3,4,4,4,5,5,5,5,6,6,6,7,7,7,7,8

=pod

The +1/2 is since initial direction b^0=1 is angle 0 which is half way
between -45 and +45 deg.

Similarly the X,Y location, using -i for rotation back

    z_xmax_exp(j) = floor(F*j+1/2)
                  = 0,0,1,1,1,1,2,2,2,3,3,3,4,4,4,4,5,5, ...
    z_xmax(k) = sum(j=0,k-1, (-i)^z_xmax_exp(j) * b^j)

=cut

# GP-DEFINE  z_xmax_exp(j) = floor(quintet_F*j+1/2);
# GP-Test  my(v=[0,0,1,1,1,1,2,2,2,3,3,3,4,4,4,4,5,5]); /* samples shown */ \
# GP-Test    vector(#v,j,j--; z_xmax_exp(j)) == v

# GP-DEFINE  z_xmax_by_floor(k) = sum(j=0,k-1, (-I)^z_xmax_exp(j) * b^j);
# GP-Test  vector(500,j,j--; z_xmax_by_floor(j)) == \
# GP-Test  vector(500,j,j--; z_xmax(j))
#
# vector(20,k,k--; z_xmax_exp(k))
# not in OEIS: 0, 0, 1, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 6

=pod

By symmetry the maximum extent is the same for Y vertically and for X or Y
negative, suitably rotated.  The N in those cases has the digits 1,2,3,4
cycled around as per L</Rotations> above.

If the +1/2 in the floor is omitted then the effect is to find the maximum
point in direction +45deg, so the point(s) with maximum sum S = X+Y.

    N_smax_digit(j) = (-floor(F*j) mod 4) + 1
                    = 1,1,1,1,4,4,4,3,3,3,3,2,2,2,1, ...

                 k-1
    N_smax(k) = digits N_smax_digit(j)    low digit j=0
                 j=0
              = 0, 1, 6, 31, 156, 2656, 15156, ...     decimal
              = 0, 1, 11, 111, 1111, 41111, 441111, ...  base5
    and also N_smax() + 1

    z_smax_exp(j) = floor(F*j)
                  = 0,0,0,0,1,1,1,2,2,2,2,3,3,3,4,4,4,5,5,5, ...
    z_smax(k) = sum(j=0,k-1, (-i)^z_smax_exp(j) * b^j)
              = 0, 1, 3+i, 6+5*i, 8+16*i, 32+23*i, 73+61*i, ...
    and also z_smax() + 1+i

    smax(k) = real(z_smax(k)) + imag(z_smax(k))
            = 0, 1, 4, 11, 24, 55, 134, 295, 602, 1465, ...

In the base figure points 1 and 2 are both on the same 45deg line and this
remains so in subsequent levels, so that for kE<gt>=1 N_smax(k) and
N_smax(k)+1 are equal maximums.

=cut

# GP-DEFINE  N_smax_digit(j) = (-floor(quintet_F*j) % 4) + 1;
# GP-Test  my(v=[1,1,1,1,4,4,4,3,3,3,3,2,2,2,1]); /* samples shown */ \
# GP-Test    vector(#v,j,j--; N_smax_digit(j)) == v

# GP-DEFINE  N_smax(k) = fromdigits(Vecrev(vector(k,j,j--; N_smax_digit(j))),5);
# GP-Test  N_smax(0) == 0
# GP-Test  N_smax(1) == 1
# GP-Test  N_smax(10) == 7343281
# GP-Test  to_base5(N_smax(10)) == 3334441111
# GP-Test  my(v=[0, 1, 6, 31, 156, 2656, 15156]); /* samples shown */ \
# GP-Test    vector(#v,j,j--; N_smax(j)) == v
# GP-Test  my(v=[0, 1, 11, 111, 1111, 41111, 441111]); /* samples shown */ \
# GP-Test    vector(#v,j,j--; to_base5(N_smax(j))) == v

# vector(25,k,k--; N_smax_digit(k))
# vector(8,k, N_smax(k))
# vector(8,k, to_base5(N_smax(k)))
# not in OEIS: 1,1,1,1,4,4,4,3,3,3,3,2,2,2,1,1,1,4,4,4,4,3,3,3,2  \\ digits
# not in OEIS: 1, 6, 31, 156, 2656, 15156, 77656, 312031          \\ decimal
# not in OEIS: 1, 11, 111, 1111, 41111, 441111, 4441111, 34441111 \\ base5
# vector(8,k, N_smax(k)+1)
# vector(8,k, to_base5(N_smax(k))+1)
# not in OEIS: 2, 7, 32, 157, 2657, 15157, 77657, 312032          \\ decimal
# not in OEIS: 2, 12, 112, 1112, 41112, 441112, 4441112, 34441112 \\ base5

# GP-DEFINE  z_smax_exp(j) = floor(quintet_F*j);
# GP-Test  my(v=[0,0,0,0,1,1,1,2,2,2,2,3,3,3,4,4,4,5,5,5]); /*samples shown*/ \
# GP-Test    vector(#v,j,j--; z_smax_exp(j)) == v

# GP-DEFINE  z_smax(k) = sum(j=0,k-1, (-I)^z_smax_exp(j) * b^j);
# GP-Test  my(v=[0,1,3+I,6+5*I,8+16*I,32+23*I,73+61*I]); /*samples shown*/ \
# GP-Test    vector(#v,j,j--; z_smax(j)) == v

# GP-DEFINE  smax(k) = my(z=z_smax(k)); real(z)+imag(z);
# GP-Test  my(v=[0, 1, 4, 11, 24, 55, 134, 295, 602, 1465]); /*samples shown*/ \
# GP-Test    vector(#v,j,j--; smax(j)) == v

# vector(16,k,k++; z_smax(k))
# vector(20,k,k++; z_smax_exp(k))
# not in OEIS: 1, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 6
# vector(8,k,k++; norm(z_smax(k)))
# vector(10,k,k++; real(z_smax(k)))
# vector(10,k,k++; imag(z_smax(k)))
# not in OEIS: 10, 61, 320, 1553, 9050, 45373, 198874, 1144933 \\ norm
# not in OEIS: 3, 6, 8, 32, 73, 117, 395, 922       \\ real
# not in OEIS: 1, 5, 16, 23, 61, 178, 207, 543      \\ imag
# vector(10,k,k++; smax(k))
# not in OEIS: 4, 11, 24, 55, 134, 295, 602, 1465   \\ real+imag

=pod

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::QuintetCurve>,
L<Math::PlanePath::ComplexMinus>,
L<Math::PlanePath::GosperReplicate>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
