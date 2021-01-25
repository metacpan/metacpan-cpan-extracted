# Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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


# math-image --path=CretanLabyrinth --output=numbers_dash
# http://labyrinthlocator.com/labyrinth-typology/4341-classical-labyrinths



package Math::PlanePath::CretanLabyrinth;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 129;
use Math::PlanePath;
use Math::PlanePath::Base::NSEW;
@ISA = ('Math::PlanePath::Base::NSEW',
        'Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
*_sqrtint = \&Math::PlanePath::_sqrtint;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant xy_is_visited => 1;
use constant x_negative_at_n => 7;
use constant y_negative_at_n => 13;


#------------------------------------------------------------------------------

#      81-80-79 78 77 76 75 74 73 72 71 70 69
#       |
#      82  x--x--                     x--x 68
#       |  |                             |
#          x  x--x-                x--x  x 67
#          |  |                       |  |
#             x 49-50-51-52-53-54-55  x    66
#             |  |                 |
#               48  9--8--7--6--5 56       65
#                   |           |  |
#               47 10 25-26-27  4 57       64
#                   |  |     |  |  |  |  |        |  |  |
#               46 11 24 29-28  3 58  x--x 63  x  x--x  x
#                   |  |  |     |  |        |  |        |
#               45 12 23 30  1--2 59-60-61-62  x--x--x--x
#                   |  |  |
#               44 13 22 31-32-33  x--x--x--x  x--x--x--x
#                   |  |        |  |        |  |        |
#               43 14 21-20-19 34  x  x--x  x
#                   |        |  |  |  |  |  |
#               42 15-16-17-18 35
#                               |
#               41 40 39 38-37-36
#
my @initial_n  = (1,2, 5, 9,15,18,19,21,25,27,28,29,31,33,36,41,49,55,59);
my @initial_dx = (1,0,-1, 0, 1, 0,-1, 0, 1, 0,-1, 0, 1, 0,-1, 0, 1, 0, 1);
my @initial_dy = (0,1, 0,-1, 0, 1, 0, 1, 0,-1, 0,-1, 0,-1, 0, 1, 0,-1, 0);
my @initial_x = (0);
my @initial_y = (0);
{
  my $x = 0;
  my $y = 0;
  foreach my $i (1 .. $#initial_n) {
    my $len = $initial_n[$i] - $initial_n[$i-1];
    $x += $initial_dx[$i-1] * $len;
    $y += $initial_dy[$i-1] * $len;
    $initial_x[$i] = $x;
    $initial_y[$i] = $y;
  }
}
### @initial_x
### @initial_y

my @len  = ( 4,3,7,12,14,11,5, 1, 4, 9,12,10, 5, 1,4, 8,10,7,4,3, 7,13,16,14, 8);
my @dlen = ( 1,0,1, 2, 2, 2,1, 0, 1, 2, 2, 2, 1, 0,1, 2, 2,2,1,0, 1, 2, 2, 2, 1);
my @dx   = ( 0,1,0,-1, 0, 1,0,-1, 0,-1, 0, 1, 0,-1,0,-1, 0,1,0,1, 0,-1, 0, 1, 0);
my @dy   = (-1,0,1, 0,-1, 0,1, 0,-1, 0, 1, 0,-1, 0,1, 0,-1,0,1,0,-1, 0, 1, 0,-1);

# [0,1,2],[59, 247, 563,]
# N = (64 d^2 + 124 d + 59)
#   = ((64*$d + 124)*$d + 59)
# d = -31/32 + sqrt(1/64 * $n + 17/1024)
#   = (-31 + 32*sqrt(1/64 * $n + 17/1024)) / 32
#   = (-31 + sqrt(32*32/64 * $n + 32*32*17/1024)) / 32
#   = (-31 + sqrt(16*$n + 17)) / 32

# [0,1,2],[55, 239, 551,]
# N = (64 d^2 + 120 d + 55)
#   = ((64*$d + 120)*$d + 55)
# d = -15/16 + sqrt(1/64 * $n + 5/256)
#   = (-15 + sqrt(16*16/64 * $n + 16*16*5/256))/16
#   = ((-15 + sqrt(4*$n + 5))/16)


sub n_to_xy {
  my ($self, $n) = @_;
  ### CretanLabyrinth n_to_xy(): $n

  if ($n < 1) { return; }
  if (is_infinite($n)) { return ($n, $n); }

  if ($n < 55) {
    foreach my $i (0 .. $#initial_n-1) {
      if ($initial_n[$i+1] > $n) {
        $n -= $initial_n[$i];
        ### $n
        return ($initial_x[$i] + $initial_dx[$i] * $n,
                $initial_y[$i] + $initial_dy[$i] * $n);
      }
    }
  }

  my $d = int( (-15 + _sqrtint(4*$n+5))/16 );
  $n -= ((64*$d + 120)*$d + 55);

  my $x = 4*$d + 2;
  my $y = 4*$d + 4;

  ### $d
  ### $n
  ### $x
  ### $y

  foreach my $i (0 .. $#len) {
    my $len = $len[$i] + 4*$d*$dlen[$i];
    if ($n <= $len) {
      ### $i
      return ($n*$dx[$i] + $x,   # $n first to inherit BigRat
              $n*$dy[$i] + $y);
    }
    $n -= $len;
    $x += $dx[$i]*$len;
    $y += $dy[$i]*$len;
  }
  die "oops, end of lengths table reached";
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### CretanLabyrinth xy_to_n(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);
  my $d = _xy_to_d($x,$y);
  ### $d

  if ($d < 1) {
    foreach my $i (0 .. $#initial_n-1) {
      my $len = $initial_n[$i+1] - $initial_n[$i];
      my $rx = $x - $initial_x[$i];
      my $ry = $y - $initial_y[$i];

      if ($initial_dx[$i]) {
        $rx *= $initial_dx[$i];
      } else {
        next if $rx;
      }

      if ($initial_dy[$i]) {
        $ry *= $initial_dy[$i];
      } else {
        next if $ry;
      }

      if ($rx >= 0 && $rx <= $len && $ry >= 0 && $ry <= $len) {
        return $initial_n[$i] + $rx + $ry;
      }
    }
  } else {
    $d -= 1;
    ### $d
    my $tx = 4*$d + 2;
    my $ty = 4*$d + 4;
    my $n = ((64*$d + 120)*$d + 55);
    foreach my $i (0 .. $#len) {
      ### at: "txy=$tx,$ty  n=$n"

      my $len = $len[$i] + 4*$d*$dlen[$i];

      my $rx = $x - $tx;
      my $ry = $y - $ty;
      $tx += $dx[$i]*$len;
      $ty += $dy[$i]*$len;
      $n += $len;
      ### rxy: "$rx,$ry"

      if ($dx[$i]) {
        $rx *= $dx[$i];
      } else {
        next if $rx;
      }

      if ($dy[$i]) {
        $ry *= $dy[$i];
      } else {
        next if $ry;
      }

      if ($rx >= 0 && $rx <= $len && $ry >= 0 && $ry <= $len) {
        ### found: "n=".($n-$len)." plus ".($rx+$ry)
        return $n-$len + $rx + $ry;
      }
    }
  }
  return undef;
}
sub _xy_to_d {
  my ($x, $y) = @_;
  ### _xy_to_d(): "$x,$y"

  if ($x >= abs($y)-2) {
    ### right ...
    return int(($x+2)/4);
  }
  if ($x <= -abs($y)) {
    ### left ...
    return int((-1-$x)/4);
  }
  ### vertical ...
  return int((abs($y)-1)/4);
}


# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### CretanLabyrinth rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest($x1);
  $y1 = round_nearest($y1);
  $x2 = round_nearest($x2);
  $y2 = round_nearest($y2);

  my $d = max (_xy_to_d($x1,$y1),
               _xy_to_d($x2,$y1),
               _xy_to_d($x1,$y2),
               _xy_to_d($x2,$y2));
  return (1,
          (64*$d + 120)*$d + 54);
}

1;
__END__

=for stopwords eg Ryde Math-PlanePath

=head1 NAME

Math::PlanePath::CretanLabyrinth -- infinite Cretan labyrinth

=head1 SYNOPSIS

 use Math::PlanePath::CretanLabyrinth;
 my $path = Math::PlanePath::CretanLabyrinth->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is a Cretan 7-circuit style labyrinth extended out infinitely.

    81--80--79--78--77--76--75--74--73--72--71--70--69         7
     |                                               |
    82 137-138-139-140-141-142-143-144-145-146-147  68         6
     |   |                                       |   |
    83 136 165-164-163-162-161-160-159-158-157 148  67         5
     |   |   |                               |   |   |
    84 135 166  49--50--51--52--53--54--55 156 149  66         4
     |   |   |   |                       |   |   |   |
    85 134 167  48   9-- 8-- 7-- 6-- 5  56 155 150  65         3
     |   |   |   |   |               |   |   |   |   |
    86 133 168  47  10  25--26--27   4  57 154 151  64         2
     |   |   |   |   |   |       |   |   |   |   |   |
    87 132 169  46  11  24  29--28   3  58 153-152  63         1
     |   |   |   |   |   |   |       |   |           |
    88 131 170  45  12  23  30   1-- 2  59--60--61--62    <- Y=0
     |   |   |   |   |   |   |
    89 130 171  44  13  22  31--32--33 186-187-188-189        -1
     |   |   |   |   |   |           |   |           |
    90 129 172  43  14  21--20--19  34 185 112-111 190        -2
     |   |   |   |   |           |   |   |   |   |   |
    91 128 173  42  15--16--17--18  35 184 113 110  ...       -3
     |   |   |   |                   |   |   |   |
    92 127 174  41--40--39--38--37--36 183 114 109            -4
     |   |   |                           |   |   |
    93 126 175-176-177-178-179-180-181-182 115 108            -5
     |   |                                   |   |
    94 125-124-123-122-121-120-119-118-117-116 107            -6
     |                                           |
    95--96--97--98--99-100-101-102-103-104-105-106            -7

                                 ^
    -7  -6  -5  -4  -3  -2  -1  X=0  1   2   3   4

The repeating part is the N=59 to N=189 style groups of 4 circuits going
back and forward.

The gaps between the path are the labyrinth walls.  Notice at N=2,59,33,186
the "+" joining of those walls which is characteristic of this style
labyrinth.

          |   3  |  58  |
          |      |      |
    ------+      |      +-------
                 |
      1       2  |  59      60
                 |
    -------------+--------------       walls
                 |
     32      33  | 186     187
                 |
    ------+      |      +-------
          |      |      |
          |  34  | 185  |

See F<examples/cretan-walls.pl> for a sample program carving out the path
from a solid block to leave the walls.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::CretanLabyrinth-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional positions give an X,Y position along a straight line between the
integer positions.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  If there's nothing at
C<$x,$y> then return C<undef>.

=item C<$n = $path-E<gt>n_start()>

Return 1, the first N in the path.

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::SquareSpiral>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
