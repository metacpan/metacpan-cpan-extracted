# Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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


# http://mathworld.wolfram.com/ElementaryCellularAutomaton.html
#
# Loeschian numbers strips on the right ...


package Math::PlanePath::CellularRule190;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
*_sqrtint = \&Math::PlanePath::_sqrtint;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest';

use Math::PlanePath::CellularRule54;
*_rect_for_V = \&Math::PlanePath::CellularRule54::_rect_for_V;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;

use constant parameter_info_array =>
  [ { name        => 'mirror',
      display     => 'Mirror',
      type        => 'boolean',
      default     => 0,
      description => 'Mirror to "rule 246" instead.',
    },
    Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];

sub x_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 1;
}
use constant sumxy_minimum => 0;  # triangular X>=-Y so X+Y>=0
use constant diffxy_maximum => 0; # triangular X<=Y so X-Y<=0
use constant dx_maximum => 2; # across gap
use constant dy_minimum => 0;
use constant dy_maximum => 1;
use constant absdx_minimum => 1;
use constant dsumxy_maximum => 2; # straight East dX=+2
use constant ddiffxy_maximum => 2; # straight East dX=+2
use constant dir_maximum_dxdy => (-1,0); # supremum, West except dY=+1


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

# 31 32 33   34 35 36    37 38 39    40
#    22 23 24   25 26 27    28 29 30
#       15 6 17    18 19 20    21
#          9 10 11    12 13 14
#             5  6  7     8
#                2  3  4
#                   1
#
# even  y = [ 0, 2, 4, 6 ]
#       N = [ 1, 5, 15, 31 ]
# Neven = (3/4 y^2 + 1/2 y + 1)
#       = (3y + 2)*y/4 + 1
#       = ((3y + 2)*y + 4) /4
#       = (3 (y/2)^2 + (y/2) + 1)
#       = (3*(y/2) + 1)*(y/2) + 1
#
# odd  y = [ 1, 3, 5,7 ]
#      N = [ 2,9,22,41 ]
# Nodd = (3/4 y^2 + 1/2 y + 3/4)
#      = ((3y+2)*y+ 3) / 4
#
# pair even d = [0,1,2,3]
#           N = [ 1, 5, 15, 31 ]
# Npair = (3 d^2 + d + 1)
# d = -1/6 + sqrt(1/3 * $n + -11/36)
#   = [ -1 + sqrt(1/3 * $n + -11/36)*6 ] / 6
#   = [ -1 + sqrt(1/3 * $n*36 + -11/36*36) ] / 6
#   = [ -1 + sqrt(12n-11) ] / 6
#
sub n_to_xy {
  my ($self, $n) = @_;
  ### CellularRule190 n_to_xy(): $n

  $n = $n - $self->{'n_start'} + 1; # to N=1 basis, and warn if $n undef
  my $frac;
  {
    my $int = int($n);
    $frac = $n - $int;
    $n = $int;       # BigFloat int() gives BigInt, use that
    if (2*$frac >= 1) {
      $frac -= 1;
      $n += 1;
    }
    # now -0.5 <= $frac < 0.5
    ### assert: 2*$frac >= -1   || $n!=$n || $n+1==$n
    ### assert: 2*$frac < 1     || $n!=$n || $n+1==$n
  }

  if ($n < 1) {
    return;
  }

  # d is the two-row number, ie. d=2*y, where n belongs
  # start of the two-row group is nbase = 3 d^2 + d + 1
  #
  my $d = int ((_sqrtint(12*$n-11) - 1) / 6);
  $n -= ((3*$d + 1)*$d + 1);   # remainder within two-row
  ### $d
  ### remainder: $n
  if ($n <= 3*$d) {
    # 3d+1 many points in the Y=0,2,4,6 etc even row
    $d *= 2;    # y=2*d
    return ($frac + $n + int(($n + ($self->{'mirror'} ? 2 : 0))/3) - $d,
            $d);
  } else {
    # 3*d many points in the Y=1,3,5,7 etc odd row, using 3 in 4 cells
    $n -= 3*$d+1;    # remainder 0 upwards into odd row
    $d = 2*$d+1;   # y=2*d+1
    return ($frac + $n + int($n/3) - $d,
            $d);
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### CellularRule190 xy_to_n(): "$x,$y"

  if ($y < 0 || $x > $y) {
    return undef;
  }

  $x += $y;  # move to have x=0 the start of the row
  if ($x < 0) {
    return undef;
  }

  ### x centred: $x
  if ($y % 2) {
    ### odd row, 3s from the start ...
    if (($x % 4) == 3) {
      return undef;
    }
    # 3y^2+2y-1 = (3y-1)*(y+1)
    return ($x
            - int($x/4)
            + ((3*$y+2)*$y-1)/4
            + $self->{'n_start'});
  } else {
    ### even row, 3s then 1 sep, or mirror 1 sep start ...
    my $mirror = $self->{'mirror'};
    if (($x % 4) == ($mirror ? 1 : 3)) {
      return undef;
    }
    return ($x
            - int(($x+($mirror ? 2 : 1))/4)
            + (3*$y+2)*$y/4
            + $self->{'n_start'});
  }
}

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### CellularRule190 rect_to_n_range(): "$x1,$y1, $x2,$y2"

  ($x1,$y1, $x2,$y2) = _rect_for_V ($x1,$y1, $x2,$y2)
    or return (1,0); # rect outside pyramid

  # # inherit bignum (before collapsing some y1 to x1 etc)
  # my $zero = ($x1 * 0 * $y1 * $x2 * $y2);

  my $mirror = $self->{'mirror'};
  my $unincremented_x1 = $x1;

  #    \+------+
  #     |      |     /
  #     |\     |    /
  #     | \    |   /
  #     |  \   |  /
  #  y1 +------+ /
  #    x1    \  /
  #           \/
  #
  if ($x1 < (my $neg_y1 = -$y1)) {
    ### bottom-left outside, move across to: "$neg_y1,$y1"
    $x1 = $neg_y1;

    # For the following blank checks a blank doesn't occur at the ends of a
    # row, so when on a blank it's always possible to increment or decrement
    # X to go to a non-blank -- as long as that adjacent space is within the
    # rectangle.
    #
  } elsif ((($mirror ? $y1-$x1 : $x1+$y1) % 4) == 3) {
    ### x1,y1 bottom left is on a blank: "x1+y1=".($x1+$y1)
    if ($x1 < $x2) {
      ### rect width >= 2, so increase x1 ...
      $x1 += 1;
    } else {
      ### rect is a single column width==1, increase y1 ...
      if (($y1 += 1) > $y2) {
        ### rect was a single blank square, contains no N ...
        return (1,0);
      }
    }
  }

  if ((($mirror ? $y2-$x2 : $x2+$y2) % 4) == 3) {
    ### x2,y2 top right is on a blank, decrement ...
    if ($x2 > $unincremented_x1) {
      ### rect width >= 2, so decrease x2 ...
      $x2 -= 1;
    } else {
      ### rect is a single column width==1, decrease y2 ...
      $y2 -= 1;

      # Can decrement without checking whether the rect is a single square.
      # If the rect was a single blank square then the x1+y1 bottom left
      # above detects and returns.  And the bottom left blank check
      # incremented y1 to leave a single square then that's a non-blank
      # because there's no vertical blank pairs (they go on the diagonal).
      ### assert $y2 >= $y1
    }
  }

  # At this point $x1,$y1 is a non-blank bottom left corner, and $x2,$y2
  # is a non-blank top right corner, being the N lo to hi range.

  ### range: "bottom-right $x1,$y1  top-left $x2,$y2"
  return ($self->xy_to_n ($x1,$y1),
          $self->xy_to_n ($x2,$y2));
}


# old rect_to_n_range() of row endpoints
#
# # even right  y = [ 0, 2, 4, 6 ]
# #             N = [ 1,8,21,40 ]
# # Nright = (3/4 y^2 + 2 y + 1)
# #        = (3 y^2 + 8 y + 4) / 4
# #        = ((3y + 8)y + 4) / 4
# #
# # odd right  y = [ 1, 3, 5, 7 ]
# #            N = [ 4,14,30, 52 ]
# # Nright = (3/4 y^2 + 2 y + 5/4)
# #        = (3 y^2 + 8 y + 5) / 4
# #        = ((3y + 8)y + 5) / 4
# #
# # Nleft y even ((3y+2)*y + 4)/4
# # Nleft y odd  ((3y+2)*y + 3)/4
# # Nright even ((3(y+1)+2)*(y+1) + 3)/4 - 1
# #          = ((3y+3+2)*(y+1) + 3 - 4)/4
# #          = ((3y+5)*(y+1) - 1)/4
# #          = ((3y^2 + 8y + 5 - 1)/4
# #          = ((3y^2 + 8y + 4)/4
# #          = ((3y+8)y + 4)/4
# #          = ((3y+2)(y+2)/4
# #
# ### $y1
# ### $y2
# $y2 += $zero;
# $y1 += $zero;
# return (((3*$y1 + 2)*$y1 + 4 - ($y1%2)) / 4,    # even/odd Nleft
#         ((3*$y2 + 8)*$y2 + 4 + ($y2%2)) / 4);   # even/odd Nright

1;
__END__

=for stopwords straight-ish Ryde Math-PlanePath ie hexagonals 18-gonal Xmax-Xmin Nleft Nright Klaner-Rado unplotted OEIS

=head1 NAME

Math::PlanePath::CellularRule190 -- cellular automaton 190 and 246 points

=head1 SYNOPSIS

 use Math::PlanePath::CellularRule190;
 my $path = Math::PlanePath::CellularRule190->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Wolfram, Stephen>This is the pattern of Stephen Wolfram's "rule 190"
cellular automaton

=over

L<http://mathworld.wolfram.com/Rule190.html>

=back

arranged as rows,

    66 67 68    69 70 71    72 73 74    75 76 77    78 79 80      9
       53 54 55    56 57 58    59 60 61    62 63 64    65         8
          41 42 43    44 45 46    47 48 49    50 51 52            7
             31 32 33    34 35 36    37 38 39    40               6
                22 23 24    25 26 27    28 29 30                  5
                   15 16 17    18 19 20    21                     4
                       9 10 11    12 13 14                        3
                          5  6  7     8                           2
                             2  3  4                              1
                                1                             <- Y=0

    -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8  9

Each row is 3 out of 4 cells.  Even numbered rows have one point on its own
at the end.  Each two-row group has a step of 6 more points than the
previous two-row.

The of rightmost N=1,4,8,14,21,etc are triangular plus quarter
square, ie.

    Nright = triangular(Y+1) + quartersquare(Y+1)
      triangular(t)    = t*(t+1)/2
      quartersquare(t) = floor(t^2/4)

The rightmost N=1,8,21,40,65,etc on even rows Y=0,2,4,6,etc are the
octagonal numbers k*(3k-2).  The octagonal numbers of the "second kind"
N=5,16,33,56,85, etc, k*(3k+2) are a straight-ish line upwards to the left.

=head2 Mirror

The C<mirror =E<gt> 1> option gives the mirror image pattern which is "rule
246".  It differs only in the placement of the gaps on the even rows.  The
point on its own is at the left instead of the right.  The numbering is
still left to right.

    66 67 68    69 70 71    72 73 74    75 76 77    78 79 80      9
       53    54 55 56    57 58 59    60 61 62    63 64 65         8
          41 42 43    44 45 46    47 48 49    50 51 52            7
             31    32 33 34    35 36 37    38 39 40               6
                22 23 24    25 26 27    28 29 30                  5
                   15    16 17 18    19 20 21                     4
                       9 10 11    12 13 14                        3
                          5     6  7  8                           2
                             2  3  4                              1
                                1                             <- Y=0

    -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8  9

Sometimes this small change to the pattern helps things line up better.  For
example plotting the Klaner-Rado sequence gives some unplotted lines up
towards the right in the mirror 246 which are not visible in the plain 190.

=head2 Row Ranges

The left end of each row, both ordinary and mirrored, is

    Nleft = ((3Y+2)*Y + 4)/4     if Y even
            ((3Y+2)*Y + 3)/4     if Y odd

The right end is

    Nright = ((3Y+8)*Y + 4)/4    if Y even
             ((3Y+8)*Y + 5)/4    if Y odd

           = Nleft(Y+1) - 1   ie. 1 before next Nleft

The row width Xmax-Xmin = 2*Y but with the gaps the number of visited points
in a row is less than that,

    rowpoints = 3*Y/2 + 1        if Y even
                3*(Y+1)/2        if Y odd

For any Y of course the Nleft to Nright difference is the number of points
in the row too

    rowpoints = Nright - Nleft + 1

=cut

# even Nright - Nleft + 1
#      = ((3Y+8)Y + 4)/4 - ((3Y+2)*Y + 4)/4 + 1
#      = [ (3Y+8)Y + 4 - (3Y+2)*Y - 4 ]/4 + 1
#      = [ (3Y+8)Y - (3Y+2)*Y ] / 4 + 1
#      = (3Y+8-3Y-2)Y/4 + 1
#      = 6Y/4 + 1
#      = 3Y/2 + 1
# odd Nright - Nleft + 1
#     = ((3Y+8)Y + 5)/4 - ((3Y+2)*Y + 3)/4 + 1
#     = [ (3Y+8)Y + 5 - (3Y+2)*Y - 3 ]/4 + 1
#     = [ (3Y+8)Y - (3Y+2)*Y + 2 ]/4 + 1
#     = [ 6Y + 2 ]/4 + 1
#     = [ 6Y + 2 + 4]/4
#     = [ 6Y + 6]/4
#     = 3(Y+1)/2

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, in the same pattern.  For example to
start at 0,

=cut

# math-image --path=CellularRule190,n_start=0 --all --output=numbers --size=75x6

=pod

    n_start => 0

    21 22 23    24 25 26    27 28 29          5 
       14 15 16    17 18 19    20             4 
           8  9 10    11 12 13                3 
              4  5  6     7                   2 
                 1  2  3                      1 
                    0                     <- Y=0

    -5 -4 -3 -2 -1 X=0 1  2  3  4  5

The effect is to push each N rightwards by 1, and wrapping around.  So the
N=0,1,4,8,14,etc on the left were on the right of the default n_start=1.
This also has the effect of removing the +1 in the Nright formula given
above, so

    Nleft = triangular(Y) + quartersquare(Y)

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::CellularRule190-E<gt>new ()>

=item C<$path = Math::PlanePath::CellularRule190-E<gt>new (mirror =E<gt> 1, n_start =E<gt> $n)>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are each
rounded to the nearest integer, which has the effect of treating each cell
as a square of side 1.  If C<$x,$y> is outside the pyramid or on a skipped
cell the return is C<undef>.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=back

=head1 OEIS

This pattern is in Sloane's Online Encyclopedia of Integer Sequences in a
couple of forms,

=over

L<http://oeis.org/A037576> (etc)

=back

    A037576     whole-row used cells as bits of a bignum
    A071039     \ 1/0 used and unused cells across rows
    A118111     /
    A071041     1/0 used and unused of mirrored rule 246 

    n_start=0
      A006578   N at left of each row (X=-Y),
                  and at right of each row when mirrored,
                  being triangular+quartersquare

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::CellularRule>,
L<Math::PlanePath::CellularRule54>,
L<Math::PlanePath::CellularRule57>,
L<Math::PlanePath::PyramidRows>

L<Cellular::Automata::Wolfram>

L<http://mathworld.wolfram.com/Rule190.html>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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

# Local variables:
# compile-command: "math-image --path=CellularRule190 --all"
# End:
#
# math-image --path=CellularRule190 --all --output=numbers --size=132x50
#
