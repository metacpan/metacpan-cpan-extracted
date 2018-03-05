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


# Boundary of unit squares:
# 2*(4*3^n+1)   cf A199108 = 4*3^n+1
#
# QuintetCurve unit squares boundary
# 12,28,76,220,652
# match 12,28,76,220,652
# [HALF]
# A079003 a(n) = 4*3^(n-2)+2



package Math::PlanePath::QuintetCurve;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 126;

# inherit: new(), rect_to_n_range(), arms_count(), n_start(),
#          parameter_info_array(), xy_is_visited()
use Math::PlanePath::QuintetCentres;
use Math::PlanePath::Base::NSEW;
@ISA = ('Math::PlanePath::Base::NSEW',
        'Math::PlanePath::QuintetCentres');

use Math::PlanePath;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'round_up_pow';

# uncomment this to run the ### lines
# use Smart::Comments;


{
  my @x_negative_at_n = (undef, 513, 9, 2, 2);
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n[$self->{'arms'}];
  }
}
{
  my @y_negative_at_n = (undef, 2, 4, 6, 3);
  sub y_negative_at_n {
    my ($self) = @_;
    return $y_negative_at_n[$self->{'arms'}];
  }
}
{
  my @_UNDOCUMENTED__dxdy_list_at_n = (undef, 8, 5, 5, 4);
  sub _UNDOCUMENTED__dxdy_list_at_n {
    my ($self) = @_;
    return $_UNDOCUMENTED__dxdy_list_at_n[$self->{'arms'}];
  }
}

# N=4 first straight, then for other arms 18,27,36
# must override base Math::PlanePath::QuintetCentres
sub _UNDOCUMENTED__turn_any_straight_at_n {
  my ($self) = @_;
  # arms=1   4    only first arm has origin 0    
  # arms=2   7
  # arms=3  10
  # arms=4  13
  return 3*$self->arms_count + 1;
}


#------------------------------------------------------------------------------
my @dir4_to_dx = (1,0,-1,0);
my @dir4_to_dy = (0,1,0,-1);
my @digit_reverse = (0,1,0,0,1,0);

sub n_to_xy {
  my ($self, $n) = @_;
  ### QuintetCurve n_to_xy(): $n

  if ($n < 0) {
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  my $arms = $self->{'arms'};
  my $int = int($n);
  $n -= $int;  # fraction part

  my $rot = _divrem_mutate ($int,$arms);
  if ($rot) { $int += 1; }

  my @digits = digit_split_lowtohigh($int,5);
  my @sx;
  my @sy;
  {
    my $sy = 0 * $int; # inherit bignum 0
    my $sx = 1 + $sy;  # inherit bignum 1
    foreach (@digits) {
      push @sx, $sx;
      push @sy, $sy;

      # 2*(sx,sy) + rot+90(sx,sy)
      ($sx,$sy) = (2*$sx - $sy,
                   2*$sy + $sx);
    }
    # ### @digits
    # my $rev = 0;
    # for (my $i = $#digits; $i >= 0; $i--) {  # high to low
    #   ### digit: $digits[$i]
    #   if ($rev) {
    #     ### reverse: "$digits[$i] to ".(5 - $digits[$i])
    #     $digits[$i] = (5 - $digits[$i]) % 5;
    #   }
    #   #      $rev ^= $digit_reverse[$digits[$i]];
    #   ### now rev: $rev
  }
  #    ### reversed n: @digits


  my $x = 0;
  my $y = 0;
  my $rev = 0;

  while (defined (my $digit = pop @digits)) {  # high to low
    my $sx = pop @sx;
    my $sy = pop @sy;
    ### at: "$x,$y  digit $digit   side $sx,$sy"

    if ($rot & 2) {
      ($sx,$sy) = (-$sx,-$sy);
    }
    if ($rot & 1) {
      ($sx,$sy) = (-$sy,$sx);
    }

    if ($rev) {
      if ($digit == 0) {
        $rev = 0;
        $rot++;

      } elsif ($digit == 1) {
        $x -= $sy;
        $y += $sx;
        $rot++;

      } elsif ($digit == 2) {
        $x += -2*$sy;
        $y += 2*$sx;

      } elsif ($digit == 3) {
        $x += $sx - 2*$sy;    # add 2*rot-90(side) + side
        $y += $sy + 2*$sx;
        $rot--;
        $rev = 0;

      } else {  # $digit == 4
        $x += $sx - $sy;    # add rot-90(side) + side
        $y += $sy + $sx;
      }

    } else {
      # normal

      if ($digit == 0) {

      } elsif ($digit == 1) {
        $x += $sx;
        $y += $sy;
        $rot--;
        $rev = 1;

      } elsif ($digit == 2) {
        $x += $sx + $sy;    # add side + rot-90(side)
        $y += $sy - $sx;

      } elsif ($digit == 3) {
        $x += 2*$sx + $sy;
        $y += 2*$sy - $sx;
        $rot++;

      } else {  # $digit == 4
        $x += 2*$sx;
        $y += 2*$sy;
        $rot++;
        $rev = 1;
      }
    }

    # lowest non-zero digit determines the direction
    if ($digit != 0) {
      ### frac_dir at non-zero: $rot
    }
  }

  ### final: "$x,$y"
  ### $rot
  $rot &= 3;
  return ($n * $dir4_to_dx[$rot] + $x,
          $n * $dir4_to_dy[$rot] + $y);
}

#                  up  upl left
my @attempt_x = (0, 0, -1, -1);
my @attempt_y = (0, 1,  1, 0);
sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### QuintetCurve xy_to_n(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);

  my ($n, $cx, $cy);
  foreach my $i (0, 1, 2, 3) {
    if (defined ($n = $self->SUPER::xy_to_n($x + $attempt_x[$i],
                                            $y + $attempt_y[$i]))
        && (($cx,$cy) = $self->n_to_xy($n))
        && $x == $cx
        && $y == $cy) {
      return $n;
    }
  }
  return undef;
}

#------------------------------------------------------------------------------
# levels

#           arms=1       arms=2            arms=3                 arms=4
# level 0  0..1  = 2    0..2  = 2+1=3     0..3  = 2+1+1=4      0..4 = 2+1+1+1=5
# level 1  0..5  = 6    0..10 = 6+5=11    0..15 = 6+5+5=16     0..20 = 6+5+5+5=21
# level 2  0..25 = 26   0..50 = 26+25=51  0..75 = 26+25+25=76  0..100 = 26+25+25+25=101
#          5^k          2*5^k             3*5^k                 4*5^k
#
sub level_to_n_range {
  my ($self, $level) = @_;
  return (0,  5**$level * $self->{'arms'});
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  $n += $self->{'arms'}-1;  # division rounding up
  _divrem_mutate ($n, $self->{'arms'});
  my ($pow, $exp) = round_up_pow ($n, 5);
  return $exp;
}


#------------------------------------------------------------------------------

# R,L,L,S
#
# forward       reverse
# 0 forward     0 forward
# 1 reverse     1 reverse
# 2 forward     2 reverse
# 3 forward     3 forward
# 4 reverse     4 reverse
{
  #                                   1   2  3  4
  my @_UNDOCUMENTED__n_to_turn_LSR = (-1, 1, 1, 0,  # forward no low zeros
                                      -1, 1, 0, 0,  # forward low zeros
                                       0,-1,-1, 1,  # reverse
                                       0, 0,-1, 1);
  sub _UNDOCUMENTED__n_to_turn_LSR {
    my ($self, $n) = @_;
    ### _UNDOCUMENTED__n_to_turn_LSR(): $n

    $n += $self->{'arms'}-1;  # division rounding up
    _divrem_mutate ($n, $self->{'arms'});
    if ($n < 1) { return undef; }

    my $any_low_zeros;
    my $low;
    while ($n) {
      last if ($low = _divrem_mutate($n,5));
      $any_low_zeros = 1;
    }
    ### $low
    ### $any_low_zeros

    my $non_two = 0;
    while (($non_two = _divrem_mutate($n,5)) == 2) {}
    ### $non_two

    $low = $low - 1
      + ($any_low_zeros ? 4 : 0)                   # low zeros
      + ($non_two == 1 || $non_two == 4 ? 8 : 0);  # reverse
    ### lookup: $low
    return $_UNDOCUMENTED__n_to_turn_LSR[$low];
  }
}


#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Mandelbrot Math-PlanePath Nlevel

=head1 NAME

Math::PlanePath::QuintetCurve -- self-similar "plus" shaped curve

=head1 SYNOPSIS

 use Math::PlanePath::QuintetCurve;
 my $path = Math::PlanePath::QuintetCurve->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path is Mandelbrot's "quartet" trace of spiralling self-similar "+"
shape,

            125--...                 93--92                      11
              |                       |   |
        123-124                      94  91--90--89--88          10
          |                           |               |
        122-121-120 103-102          95  82--83  86--87           9
                  |   |   |           |   |   |   |
        115-116 119 104 101-100--99  96  81  84--85               8
          |   |   |   |           |   |   |
    113-114 117-118 105  32--33  98--97  80--79--78               7
      |               |   |   |                   |
    112-111-110-109 106  31  34--35--36--37  76--77               6
                  |   |   |               |   |
                108-107  30  43--42  39--38  75                   5
                          |   |   |   |       |
                 25--26  29  44  41--40  73--74                   4
                  |   |   |   |           |
             23--24  27--28  45--46--47  72--71--70--69--68       3
              |                       |                   |
             22--21--20--19--18  49--48  55--56--57  66--67       2
                              |   |       |       |   |
              5---6---7  16--17  50--51  54  59--58  65           1
              |       |   |           |   |   |       |
      0---1   4   9---8  15          52--53  60--61  64       <- Y=0
          |   |   |       |                       |   |
          2---3  10--11  14                      62--63          -1
                      |   |
                     12--13                                      -2

      ^
     X=0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 ...

As per

    Benoit B. Mandelbrot, "The Fractal Geometry of Nature", W. H. Freeman
    and Co., 1983, ISBN 0-7167-1186-9, section 7, "Harnessing the Peano
    Monster Curves", pages 72-73.

Mandelbrot calls this a "quartet", taken as 4 parts around a further middle
part (like 4 players around a table).  The module name "quintet" here is a
mistake, though it does suggest the base-5 nature of the curve.

The base figure is the initial N=0 to N=5.

              5
              |
              |
      0---1   4      base figure
          |   |
          |   |
          2---3

It corresponds to a traversal of the following "+" shape,

         .... 5
         .    |
         .   <|
              |
    0----1 .. 4 ....
      v  |    |    .
    .    |>   |>   .
    .    |    |    .
    .... 2----3 ....
         . v  .
         .    .
         .    .
         . .. .

The "v" and ">" notches are the side the figure is directed at the higher
replications.  The 0, 2 and 3 sub-curves are the right hand side of the line
and are a plain repetition of the base figure.  The 1 and 4 parts are to the
left and are a reversal.  The first such reversal is seen in the sample
above as N=5 to N=10.
        .....
        .   .

    5---6---7 ...
    .   .   |   .
    .       |   .   reversed figure
    ... 9---8 ...
        |   .
        |   .
       10 ...

Mandelbrot gives the expansion without designating start and end.  The start
is chosen here so the expansion has sub-curve 0 forward (not reverse).  This
ensures the next expansion has the curve the same up to the preceding level,
and extending from there.

In the base figure it can be seen the N=5 endpoint is rotated up around from
the N=0 to N=1 direction.  This makes successive higher levels slowly spiral
around.

    base b = 2 + i
    N = 5^level
    angle = level * arg(b) = level*atan(1/2)
          = level * 26.56 degrees

In the sample shown above N=125 is level=3 and has spiralled around to angle
3*26.56=79.7 degrees.  The next level goes to X negative in the second
quadrant.  A full circle around the plane is approximately level 14.

=head2 Arms

The optional C<arms =E<gt> $a> parameter can give 1 to 4 copies of the
curve, each advancing successively.  For example C<arms=E<gt>4> is as
follows.  N=4*k points are the plain curve, and N=4*k+1, N=4*k+2 and N=4*k+3
are rotated copies of it.

                    69--65                      ...
                     |   |                       |
    ..-117-113-109  73  61--57--53--49         120
                 |   |               |           |
           101-105  77  25--29  41--45 100-104 116
             |       |   |   |   |       |   |   |
            97--93  81  21  33--37  92--96 108-112
                 |   |   |           |
        50--46  89--85  17--13-- 9  88--84--80--76--72
         |   |                   |                   |
        54  42--38  10-- 6   1-- 5  20--24--28  64--68
         |       |   |   |           |       |   |
        58  30--34  14   2   0-- 4  16  36--32  60
         |   |       |           |   |   |       |
    66--62  26--22--18   7-- 3   8--12  40--44  56
     |                   |                   |   |
    70--74--78--82--86  11--15--19  87--91  48--52
                     |           |   |   |
       110-106  94--90  39--35  23  83  95--99
         |   |   |       |   |   |   |       |
       114 102--98  47--43  31--27  79 107-103
         |           |               |   |
       118          51--55--59--63  75 111-115-119-..
         |                       |   |
        ...                     67--71

The curve is essentially an ever expanding "+" shape with one corner at the
origin.  Four such shapes pack as follows,

                +---+
                |   |
        +---@---    +---+
        |   |     B     |
    +---+   +---+   +---@
    |     C     |   |   |
    +---+   +---O---+   +---+
        |   |   |     A     |
        @---+   +---+   +---+
        |     D     |   |
        +---+   +---@---+ 
            |   |
            +---+

At higher replication levels the sides are wiggly and spiralling and the
centres of each rotate around, but their sides are symmetric and mesh
together perfectly to fill the plane.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::QuintetCurve-E<gt>new ()>

=item C<$path = Math::PlanePath::QuintetCurve-E<gt>new (arms =E<gt> $a)>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional positions give an X,Y position along a straight line between the
integer positions.

=item C<$n = $path-E<gt>n_start()>

Return 0, the first N in the path.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

In the current code the returned range is exact, meaning C<$n_lo> and
C<$n_hi> are the smallest and biggest in the rectangle, but don't rely on
that yet since finding the exact range is a touch on the slow side.  (The
advantage of which though is that it helps avoid very big ranges from a
simple over-estimate.)

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 5**$level)>, or for multiple arms return C<(0, $arms *
5**$level)>.

There are 5^level + 1 points in a level, numbered starting from 0.  On the
second and subsequent arms the origin is omitted (so as not to repeat that
point) and so just 5^level for them, giving 5^level+1 + (arms-1)*5^level =
arms*5^level + 1 many points starting from 0.

=back

=head1 FORMULAS

=head2 X,Y to N

The current approach uses the C<QuintetCentres> C<xy_to_n()>.  Because the
tiling in C<QuintetCurve> and C<QuintetCentres> is the same, the X,Y
coordinates for a given N are no more than 1 away in the grid.

The way the two lowest shapes are arranged in fact means that for a
C<QuintetCurve> N at X,Y then the same N on the C<QuintetCentres> is at one
of three locations

    X, Y          same
    X, Y+1        up
    X-1, Y+1      up and left
    X-1, Y        left

This is so even when the "arms" multiple paths are in use (the same arms in
both coordinates).

Is there an easy way to know which of the four offsets is right?  The
current approach is to give each to C<QuintetCentres> to make an N, put that
N back through C<n_to_xy()> to see if it's the target C<$n>.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::QuintetCentres>,
L<Math::PlanePath::QuintetReplicate>,
L<Math::PlanePath::Flowsnake>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
