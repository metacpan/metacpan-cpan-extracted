# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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


package Math::PlanePath::SierpinskiArrowhead;
use 5.004;
use strict;
use Carp 'croak';

#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 127;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'round_up_pow',
  'digit_split_lowtohigh';

# uncomment this to run the ### lines
#use Smart::Comments;


# Note: shared by SierpinskiArrowheadCentres
use constant parameter_info_array =>
  [ { name      => 'align',
      share_key => 'align_trld',
      display   => 'Align',
      type      => 'enum',
      default   => 'triangular',
      choices   => ['triangular','right','left','diagonal'],
      choices_display => ['Triangular','Right','Left','Diagonal'],
    },
  ];

use constant n_start => 0;
use constant class_y_negative => 0;

my %x_negative = (triangular => 1,
                  left       => 1,
                  right      => 0,
                  diagonal   => 0);
# Note: shared by SierpinskiArrowheadCentres
sub x_negative {
  my ($self) = @_;
  return $x_negative{$self->{'align'}};
}
{
  my %x_negative_at_n = (triangular => 3,
                         # right      => undef,
                         left       => 2,
                         # diagonal   => undef,
                        );
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n{$self->{'align'}};
  }
}

use constant sumxy_minimum => 0;  # triangular X>=-Y
use Math::PlanePath::SierpinskiTriangle;
*x_maximum      = \&Math::PlanePath::SierpinskiTriangle::x_maximum;
*diffxy_maximum = \&Math::PlanePath::SierpinskiTriangle::diffxy_maximum;

sub dx_minimum {
  my ($self) = @_;
  return ($self->{'align'} eq 'triangular' ? -2 : -1);
}
sub dx_maximum {
  my ($self) = @_;
  return ($self->{'align'} eq 'triangular' ? 2 : 1);
}
use constant dy_minimum => -1;
use constant dy_maximum => 1;

{
  my %_UNDOCUMENTED__dxdy_list
    = (triangular  => [ 2,0,   # E   N=4   six directions
                        1,1,   # NE  N=0
                        -1,1,  # NW  N=2
                        -2,0,  # W   N=1
                        -1,-1, # SW  N=15
                        1,-1,  # SE  N=6
                      ],
       right     => [ 1,0,   # E   N=4
                      1,1,   # NE  N=0
                      0,1,   # N   N=2
                      -1,0,  # W   N=1
                      -1,-1, # SW  N=15
                      0,-1,  # S   N=6
                    ],
       left      => [ 1,0,    # E   N=4
                      0,1,    # N   N=0
                      -1,1,   # NW  N=2
                      -1,0,   # W   N=1
                      0,-1,   # S   N=15
                      1,-1,   # SE  N=6
                    ],
       diagonal  => [ 1,0,   # E  N=0
                      0,1,   # N  N=2
                      -1,1,  # NW  N=1
                      -1,0,  # W  N=15
                      0,-1,  # S  N=6
                      1,-1,  # SE  N=4
                    ],
      );
  sub _UNDOCUMENTED__dxdy_list {
    my ($self) = @_;
    return @{$_UNDOCUMENTED__dxdy_list{$self->{'align'}}};
  }
}
use constant _UNDOCUMENTED__dxdy_list_at_n => 15;

sub absdx_minimum {
  my ($self) = @_;
  return ($self->{'align'} eq 'triangular' ? 1 : 0);
}
sub absdx_maximum {
  my ($self) = @_;
  return ($self->{'align'} eq 'triangular' ? 2 : 1);
}

{
  my %dsumxy_minimum = (triangular => -2,
                        left       => -1,
                        right      => -2,
                        diagonal   => -1,
                       );
  sub dsumxy_minimum {
    my ($self) = @_;
    return $dsumxy_minimum{$self->{'align'}};
  }
}
{
  my %dsumxy_maximum = (triangular => 2,
                        left       => 1,
                        right      => 2,
                        diagonal   => 1,
                       );
  sub dsumxy_maximum {
    my ($self) = @_;
    return $dsumxy_maximum{$self->{'align'}};
  }
}

{
  my %ddiffxy_minimum = (triangular => -2,
                         left       => -2,
                         right      => -1,
                         diagonal   => -2,
                        );
  sub ddiffxy_minimum {
    my ($self) = @_;
    return $ddiffxy_minimum{$self->{'align'}};
  }
}
{
  my %ddiffxy_maximum = (triangular => 2,
                        left       => 2,
                        right      => 1,
                        diagonal   => 2,
                       );
  sub ddiffxy_maximum {
    my ($self) = @_;
    return $ddiffxy_maximum{$self->{'align'}};
  }
}

sub dir_maximum_dxdy {
  my ($self) = @_;
  return ($self->{'align'} eq 'right'
          ? (0,-1)   # South
          : (1,-1)); # South-East
}

use constant turn_any_straight => 0; # never straight


#------------------------------------------------------------------------------

# Note: shared by SierpinskiArrowheadCentres
sub new {
  my $self = shift->SUPER::new(@_);
  my $align = ($self->{'align'} ||= 'triangular');
  if (! exists $x_negative{$align}) {
    croak "Unrecognised align option: ", $align;
  }
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### SierpinskiArrowhead n_to_xy(): $n
  if ($n < 0) {
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  my $x = int($n);
  my $y = $n - $x;  # fraction part
  $n = $x;
  $x = $y;

  if (my @digits = digit_split_lowtohigh($n,3)) {
    my $len = 1;
    for (;;) {
      my $digit = shift @digits;  # low to high

      ### odd right: "$x,$y  len=$len"
      ### $digit
      if ($digit == 0) {

      } elsif ($digit == 1) {
        $x = $len - $x;  # mirror and offset
        $y += $len;

      } else {
        ($x,$y) = (($x+3*$y)/-2,             # rotate +120
                   ($x-$y)/2    + 2*$len);
      }

      @digits || last;
      $len *= 2;
      $digit = shift @digits;  # low to high

      ### odd left: "$x,$y  len=$len"
      ### $digit
      if ($digit == 0) {

      } elsif ($digit == 1) {
        $x = - $x - $len;  # mirror and offset
        $y += $len;

      } else {
        ($x,$y) = ((3*$y-$x)/2,              # rotate -120
                   ($x+$y)/-2  + 2*$len)
      }

      @digits || last;
      $len *= 2;
    }
  }

  ### final: "$x,$y"
  if ($self->{'align'} eq 'right') {
    return (($x+$y)/2, $y);
  } elsif ($self->{'align'} eq 'left') {
    return (($x-$y)/2, $y);
  } elsif ($self->{'align'} eq 'diagonal') {
    return (($x+$y)/2, ($y-$x)/2);
  } else { # triangular
    return ($x,$y);
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### SierpinskiArrowhead xy_to_n(): "$x, $y"

  if ($y < 0) {
    return undef;
  }

  if ($self->{'align'} eq 'left') {
    if ($x > 0) {
      return undef;
    }
    $x = 2*$x + $y; # adjust to triangular style

  } elsif ($self->{'align'} eq 'triangular') {
    if (($x%2) != ($y%2)) {
      return undef;
    }

  } else {
    # right or diagonal
    if ($x < 0) {
      return undef;
    }
    if ($self->{'align'} eq 'right') {
      $x = 2*$x - $y;
    } else { # diagonal
      ($x,$y) = ($x-$y, $x+$y);
      }
  }
  ### adjusted xy: "$x,$y"

  # On row Y=2^k the points belong to belong in the level below except for
  # the endmost X=Y or X=-Y.  For example Y=4 has N=6 which is in the level
  # below, but at the end has N=9 belongs to the level above.  So $y-1 puts
  # Y=2^k into the level below and +($y==abs($x)) pushes the end back up to
  # the next.
  #
  my ($len, $level) = round_down_pow ($y-1 + ($y==abs($x)),
                                      2);
  ### pow2 round down: $y-1+($y==abs($x))
  ### $len
  ### $level

  if (is_infinite($level)) {
    return $level;
  }

  my $n = 0;
  while ($level-- >= 0) {
    ### at: "$x,$y  level=$level  len=$len"
    $n *= 3;

    if ($y < 0 || $x < -$y || $x > $y) {
      ### out of range
      return undef;
    }
    if ($y < $len + !($x==$y||$x==-$y)) {
      ### digit 0, first triangle, no change

    } else {
      if ($level & 1) {
        ### odd level
        if ($x > 0) {
          ### digit 1, right triangle
          $n += 1;
          $y -= $len;
          $x = - ($x-$len);
          ### shift right and mirror to: "$x,$y"
        } else {
          ### digit 2, left triangle
          $n += 2;
          $y -= 2*$len;
          ### shift down to: "$x,$y"
          ($x,$y) = ((3*$y-$x)/2,   # rotate -120
                     ($x+$y)/-2);
          ### rotate to: "$x,$y"
        }
      } else {
        ### even level
        if ($x < 0) {
          ### digit 1, left triangle
          $n += 1;
          $y -= $len;
          $x = - ($x+$len);
          ### shift right and mirror to: "$x,$y"
        } else {
          ### digit 2, right triangle
          $n += 2;
          $y -= 2*$len;
          ### shift down to: "$x,$y"
          ($x,$y) = (($x+3*$y)/-2,             # rotate +120
                     ($x-$y)/2);
          ### now: "$x,$y"
        }
      }
    }

    $len /= 2;
  }

  if ($x == 0 && $y == 0) {
    return $n;
  } else {
    return undef;
  }
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### SierpinskiArrowhead rect_to_n_range() ...

  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); } # swap to y1<=y2

  if ($self->{'align'} eq 'diagonal') {
    $y2 += max (round_nearest ($x1),
                round_nearest ($x2));
  }

  unless ($y2 >= 0) {
    ### rect all negative, no N ...
    return (1, 0);
  }

  my ($pow,$exp) = round_down_pow ($y2-1, 2);
  ### $y2
  ### $level
  return (0, 3**($exp+1));
}

#-----------------------------------------------------------------------------
# level_to_n_range()

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0, 3**$level);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  my ($pow, $exp) = round_up_pow ($n, 3);
  return $exp;
}

#-----------------------------------------------------------------------------
1;
__END__

# sideways ...
#
#                         27 ...                           8
#                           \
#                       .    26                            7
#                           /
#                   24----25     .                         6
#                  /
#                23     .    20----19                      5
#                  \        /        \
#              .    22----21    .     18                   4
#                                    /
#           4---- 5     .     .    17    .                 3
#         /        \                 \
#        3     .     6     .     .    16----15             2
#         \         /                         \
#     .     2     7     .    10----11     .    14          1
#         /        \        /        \        /
#  0---- 1     .     8---- 9     .    12----13    .    <- Y=0
#
# X=0 1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 ...


# rows
#          *           1 \
#         * *          2 |
#        *   *         2 |
#       * * * *        4 /
#      *       *       2 \
#     * *     * *      4 | 2x prev 4
#    *   *   *   *     4 |
#   * * * * * * * *    8 /
#  *               *   2 \
# * *             * *  4 | 2x prev 8
#
# cumulative
#
# 1
# 3
# 5
# 9
# 11 \
# 15 | *2+9
# 19 |
# 27 /
# 29 \
# 33 | *2+27
# 37
# 45
# 49
# 57
# 65
# 81


=for stopwords eg Ryde Sierpinski Nlevel ie bitwise-AND Math-PlanePath OEIS mirrorings

=head1 NAME

Math::PlanePath::SierpinskiArrowhead -- self-similar triangular path traversal

=head1 SYNOPSIS

 use Math::PlanePath::SierpinskiArrowhead;
 my $path = Math::PlanePath::SierpinskiArrowhead->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Sierpinski, Waclaw>This path is an integer version of Sierpinski's curve
from

=over

Waclaw Sierpinski, "Sur une Courbe Dont Tout Point est un Point de
Ramification", Comptes Rendus Hebdomadaires des SE<233>ances de
l'AcadE<233>mie des Sciences, volume 160, January-June 1915, pages 302-305.
L<http://gallica.bnf.fr/ark:/12148/bpt6k31131/f302.image.langEN>

=back

=cut

# PDF download pages 304 to 307 inclusive

=pod

The path is self-similar triangular parts leaving middle triangle gaps
giving the Sierpinski triangle shape.

    \
     27----26          19----18          15----14             8
             \        /        \        /        \
              25    20          17----16          13          7
             /        \                          /
           24          21                11----12             6
             \        /                 /
              23----22                10                      5
                                        \
                        5---- 6           9                   4
                      /        \        /
                     4           7---- 8                      3
                      \
                        3---- 2                               2
                               \
                                 1                            1
                               /
                              0                           <- Y=0

     -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8

The base figure is the N=0 to N=3 shape.  It's repeated up in mirror image
as N=3 to N=6 then across as N=6 to N=9.  At the next level the same is done
with the N=0 to N=9 shape, up as N=9 to N=18 and across as N=18 to N=27,
etc.

The X,Y coordinates are on a triangular lattice done in integers by using
every second X, per L<Math::PlanePath/Triangular Lattice>.

The base pattern is a triangle like

    3---------2 - - - - .
     \         \
         C  /   \  B  /
       \      D  \
          /       \ /
         . - - - - 1
          \       /
              A  /
            \   /
               /
              0

Higher levels go into the triangles A,B,C but the middle triangle D is not
traversed.  It's hard to see that omitted middle in the initial N=0 to N=27
above.  The following is more of the visited points, making it clearer

=cut

# generated by devel/sierpinski-arrowhead-stars.pl

=pod

        *   * *   * *   *                 * *   * *   * *
         * *   * *   * *                 *   * *   * *
            * *   * *                     * *     *   *
           *         *                       *     * *
            * *   * *                       *   * *
               * *                           * *   *
              *   *                             * *
               * *                             *
                  * *   * *   * *   * *   * *   *
                 *   * *   * *   * *   * *   * *
                  * *     *   *     * *   * *
                     *     * *     *         *
                    *   * *         * *   * *
                     * *   *           * *
                        * *           *   *
                       *               * *
                        * *   * *   * *
                           * *   * *   *
                          *   *     * *
                           * *     *
                              * *   *
                             *   * *
                              * *
                                 *
                                *

=head2 Sierpinski Triangle

The path is related to the Sierpinski triangle or "gasket" by treating each
line segment as the side of a little triangle.  The N=0 to N=1 segment has a
triangle on the left, N=1 to N=2 on the right, and N=2 to N=3 underneath,
which are per the A,B,C parts shown above.  Notice there's no middle little
triangle "D" in the triplets of line segments.  In general a segment N to
N+1 has its little triangle to the left if N even or to the right if N odd.

This pattern of little triangles is why the N=4 to N=5 looks like it hasn't
visited the vertex of the triangular N=0 to N=9 -- the 4 to 5 segment is
standing in for a little triangle to the left of that segment.  Similarly
N=13 to N=14 and each alternate side midway through replication levels.

There's easier ways to generate the Sierpinski triangle though.  One of the
simplest is to take X,Y coordinates which have no 1 bit on common, ie. a
bitwise-AND,

    ($x & $y) == 0

which gives the shape in the first quadrant XE<gt>=0,YE<gt>=0.  The same can
be had with the C<ZOrderCurve> path by plotting all numbers N which have no
digit 3 in their base-4 representation (see
L<Math::PlanePath::ZOrderCurve/Power of 2 Values>), since digit 3s in that
case are X,Y points with a 1 bit in common.

The attraction of this Arrowhead path is that it makes a connected traversal
through the Sierpinski triangle pattern.

=head2 Level Sizes

Counting the N=0,1,2,3 part as level 1, each level goes from

    Nstart = 0
    Nlevel = 3^level

inclusive of the final triangle corner position.  For example level 2 is
from N=0 to N=3^2=9.  Each level doubles in size,

           0  <= Y <= 2^level
    - 2^level <= X <= 2^level

The final Nlevel position is alternately on the right or left,

    Xlevel = /  2^level      if level even
             \  - 2^level    if level odd

The Y axis is crossed, ie. X=0, at N=2,6,18,etc which is is 2/3 through the
level, ie. after two replications of the previous level,

    Ncross = 2/3 * 3^level
           = 2 * 3^(level-1)

=head2 Align Parameter

An optional C<align> parameter controls how the points are arranged relative
to the Y axis.  The default shown above is "triangular".  The choices are
the same as for the C<SierpinskiTriangle> path.

"right" means points to the right of the axis, packed next to each other and
so using an eighth of the plane.

=cut

# math-image --path=SierpinskiArrowhead,align=right --all --output=numbers_dash --size=78x22

=pod

    align => "right"

        |   |
     8  |  27-26    19-18    15-14
        |      |   /    |   /    |
     7  |     25 20    17-16    13
        |    /    |            /
     6  |  24    21       11-12
        |   |   /        /
     5  |  23-22       10
        |               |
     4  |      5--6     9
        |    /    |   /
     3  |   4     7--8
        |   |
     2  |   3--2
        |      |
     1  |      1
        |    /
    Y=0 |   0
        +--------------------------
           X=0 1  2  3  4  5  6  7

"left" is similar but skewed to the left of the Y axis, ie. into negative X.

=cut

# math-image --path=SierpinskiArrowhead,align=left --all --output=numbers_dash --size=78x22

=pod

    align => "left"

    \
     27-26    19-18    15-14     |  8
          \    |   \    |   \    |
           25 20    17-16    13  |  7
            |   \             |  |
           24    21       11-12  |  6
             \    |        |     |
              23-22       10     |  5
                            \    |
                     5--6     9  |  4
                     |   \    |  |
                     4     7--8  |  3
                      \          |
                        3--2     |  2
                            \    |
                              1  |  1
                              |  |
                              0  | Y=0
    -----------------------------+

     -8 -7 -6 -5 -4 -3 -2 -1 X=0

"diagonal" put rows on diagonals down from the Y axis to the X axis.  This
uses the whole of the first quadrant (with gaps).

=cut

# math-image --expression='i<=27?i:0' --path=SierpinskiArrowhead,align=diagonal --output=numbers_dash --size=78x22

=pod

    align => "diagonal"

        |   |
     8  |  27
        |    \
     7  |     26
        |      |
     6  |  24-25
        |   |
     5  |  23    20-19
        |    \    |   \
     4  |     22-21    18
        |               |
     3  |   4--5       17
        |   |   \        \
     2  |   3     6       16-15
        |    \    |            \
     1  |      2  7    10-11    14
        |      |   \    |   \    |
    Y=0 |   0--1     8--9    12-13
        +--------------------------
           X=0 1  2  3  4  5  6  7

=head2 Sideways

Sierpinski presents the curve with a base along the X axis.  That can be had
here with a -60 degree rotation (see L<Math::PlanePath/Triangular Lattice>),

    (3Y+X)/2, (Y-X)/2       rotate -60

The first point N=1 is then along the X axis at X=2,Y=0.  Or to have it
diagonally upwards first then apply a mirroring -X before rotating

    (3Y-X)/2, (Y+X)/2       mirror X and rotate -60

The plain -60 rotate puts the Nlevel=3^level point on the X axis for even
number level, and at the top peak for odd level.  With the extra mirroring
it's the other way around.  If drawing successive levels then the two ways
can be alternated to have the endpoint on the X axis each time.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::SierpinskiArrowhead-E<gt>new ()>

=item C<$path = Math::PlanePath::SierpinskiArrowhead-E<gt>new (align =E<gt> $str)>

Create and return a new arrowhead path object.  C<align> is a string, one of
the following as described above.

    "triangular"       the default
    "right"
    "left"
    "diagonal"

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

If C<$n> is not an integer then the return is on a straight line between the
integer points.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 3**$level)>.

=back

=head1 FORMULAS

=head2 Turn

The turn at N is given by ternary

    turn(N)    N + LowestNonZero(N) + CountLowZeros(N)
    -------    ---------------------------------------
     left                      even
     right                     odd

In the replications, turns N=1 and N=2 are both left.  A low 0 digit
expansion is mirror image to maintain initial segment direction.  Parts "B"
digit=1 above are each mirror images too so turns flip.

    [flip for each 1 digit]  [1 or 2]  [flip for each low 0 digit]

N is odd or even according as the number of ternary 1 digits is odd or even
(all 2 digits being even of course), so N parity accounts for the "B"
mirrorings.  On a binary computer this is just the low bit rather than
examining the high digits of N.  In any case if the ternary lowest non-0 is
a 1 then it is not such a mirror so adding LowestNonZero cancels that.

This turn rule is noted by Alexis Monnerot-Dumaine in OEIS A156595.  That
sequence is LowestNonZero(N) + CountLowZeros(N) mod 2 and flipping according
as N odd or even is the arrowhead turns.

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include,

=over

L<http://oeis.org/A156595> (etc)

=back

    A156595   turn 0=left,1=right at even N=2,4,6,etc
    A189706   turn 0=left,1=right at odd N=1,3,5,etc
    A189707     (N+1)/2 of the odd N positions of left turns
    A189708     (N+1)/2 of the odd N positions of right turns

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::SierpinskiArrowheadCentres>,
L<Math::PlanePath::SierpinskiTriangle>,
L<Math::PlanePath::KochCurve>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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
