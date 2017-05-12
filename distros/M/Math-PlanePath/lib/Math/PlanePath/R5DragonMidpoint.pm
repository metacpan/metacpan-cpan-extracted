# Copyright 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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




# math-image --path=R5DragonMidpoint --lines --scale=40
#
# math-image --path=R5DragonMidpoint --all --output=numbers_dash --size=78x60
# math-image --path=R5DragonMidpoint,arms=6 --all --output=numbers_dash --size=78x60


package Math::PlanePath::R5DragonMidpoint;
use 5.004;
use strict;
use List::Util 'min'; # 'max'
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 124;

use Math::PlanePath;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;
use Math::PlanePath::Base::NSEW;
@ISA = ('Math::PlanePath::Base::NSEW',
        'Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_up_pow',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;
use constant parameter_info_array => [ { name        => 'arms',
                                         share_key   => 'arms_4',
                                         display     => 'Arms',
                                         type        => 'integer',
                                         minimum     => 1,
                                         maximum     => 4,
                                         default     => 1,
                                         width       => 1,
                                         description => 'Arms',
                                       } ];

{
  my @x_negative_at_n = (undef, 14,5,2,2);
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n[$self->{'arms'}];
  }
}
{
  my @y_negative_at_n = (undef, 93,35,11,7);
  sub y_negative_at_n {
    my ($self) = @_;
    return $y_negative_at_n[$self->{'arms'}];
  }
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'arms'} = max(1, min(4, $self->{'arms'} || 1));
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### R5DragonMidpoint n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n, $n); }

  {
    my $int = int($n);
    if ($n != $int) {
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+$self->{'arms'});
      my $frac = $n - $int;  # inherit possible BigFloat
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int; # BigFloat int() gives BigInt, use that
  }

  # ENHANCE-ME: own code ...
  #
  require Math::PlanePath::R5DragonCurve;
  my ($x1,$y1) = $self->Math::PlanePath::R5DragonCurve::n_to_xy($n);
  my ($x2,$y2) = $self->Math::PlanePath::R5DragonCurve::n_to_xy($n+$self->{'arms'});

  # x = x1+x2
  # y = y1+y2
  # rotx = x+y = (y1+y2)+(x1+x2)
  # roty = y-x = (y1+y2)-(x1+x2)
  # cx = (rotx-1)/2
  # cy = (rotx+1)/2

  $x1 += $x2;
  $y1 += $y2;
  return (($x1+$y1-1)/2,
          ($y1-$x1+1)/2);
}


# table of triplets $ndigit,$dx,$dy for ($y%10)*10+($x%10), total 300 entries
my @yx_to_digdxdy # 30 each row
  = (0,0,0,   1,-1,0,  1,0,-1,  2,-1,-1, 3,-2,-1,
     3,-1,-2, 4,-2,-2, 0,-2,0,  2,-1,-1, 4,0,-2,
     4,-2,0,  2,-1,-1, 0,0,-2,  4,0,0,   3,-1,0,
     3,0,-1,  2,-1,-1, 1,-2,-1, 1,-1,-2, 0,-2,-2,
     3,-2,-1, 3,-1,-2, 4,-2,-2, 0,-2,0,  2,-1,-1,
     4,0,-2,  0,0,0,   1,-1,0,  1,0,-1,  2,-1,-1,
     3,-1,0,  3,0,-1,  2,-1,-1, 1,-2,-1, 1,-1,-2,
     0,-2,-2, 4,-2,0,  2,-1,-1, 0,0,-2,  4,0,0,
     2,-1,-1, 4,0,-2,  0,0,0,   1,-1,0,  1,0,-1,
     2,-1,-1, 3,-2,-1, 3,-1,-2, 4,-2,-2, 0,-2,0,
     1,-1,-2, 0,-2,-2, 4,-2,0,  2,-1,-1, 0,0,-2,
     4,0,0,   3,-1,0,  3,0,-1,  2,-1,-1, 1,-2,-1,
     1,0,-1,  2,-1,-1, 3,-2,-1, 3,-1,-2, 4,-2,-2,
     0,-2,0,  2,-1,-1, 4,0,-2,  0,0,0,   1,-1,0,
     0,0,-2,  4,0,0,   3,-1,0,  3,0,-1,  2,-1,-1,
     1,-2,-1, 1,-1,-2, 0,-2,-2, 4,-2,0,  2,-1,-1,
     4,-2,-2, 0,-2,0,  2,-1,-1, 4,0,-2,  0,0,0,
     1,-1,0,  1,0,-1,  2,-1,-1, 3,-2,-1, 3,-1,-2,
     2,-1,-1, 1,-2,-1, 1,-1,-2, 0,-2,-2, 4,-2,0,
     2,-1,-1, 0,0,-2,  4,0,0,   3,-1,0,  3,0,-1,
    );

# arm $x $y         2 | 1     Y=1
#  0   0  0         3 | 0     Y=0
#  1   0  1       ----+----
#  2  -1  1       X=-1  X=0
#  3  -1  0
my @xy_to_arm = ([0,   # x=0,y=0
                  1],  # x=0,y=1
                 [3,   # x=-1,y=0
                  2]); # x=-1,y=1

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### R5DragonMidpoint xy_to_n(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);

  foreach my $overflow (2*$x + 2*$y, 2*$x - 2*$y) {
    if (is_infinite($overflow)) { return $overflow; }
  }
  my $zero = ($x * 0 * $y); # inherit bignum 0
  my @ndigits;     # low to high;

  for (;;) {
    last if ($x <= 0 && $x >= -1 && $y <= 1 && $y >= 0);

    my $k = 3*(10*($y%10) + ($x%10));

    ### at: "x=$x,y=$y (k=$k)  ndigits=".join(',',@ndigits)."  digit=$yx_to_digdxdy[$k]  offset=$yx_to_digdxdy[$k+1],$yx_to_digdxdy[$k+2] to ".($x+$yx_to_digdxdy[$k+1]).",".($y+$yx_to_digdxdy[$k+2])

    push @ndigits, $yx_to_digdxdy[$k++]; # ndigit
    $x += $yx_to_digdxdy[$k++];          # dx
    $y += $yx_to_digdxdy[$k];            # dy

    # (x+iy)/(1+2i)
    # = (x+iy)*(1-2i) / (1+4)
    # = (x+iy)*(1-2i) / 5
    # = (x+2y +i(y-2x)) / 5
    #
    ### assert: abs($x + 2 * $y) % 5 == 0
    ### assert: abs($y - 2 * $x) % 5 == 0

    ($x,$y) = (($x+2*$y) / 5,    # divide 1+2i
               ($y-2*$x) / 5);
    ### divide down to: "$x,$y"
  }

  ### final: "xy=$x,$y"
  my $arm = $xy_to_arm[$x]->[$y];
  ### $arm

  my $arms_count = $self->arms_count;
  if ($arm >= $arms_count) {
    return undef;
  }
  if ($arm & 1) {
    ### flip ...
    @ndigits = map {4-$_} @ndigits;
  }

  return digit_join_lowtohigh(\@ndigits, 5, $zero) * $arms_count + $arm;
}

#------------------------------------------------------------------------------

# whole plane covered when arms==4
sub xy_is_visited {
  my ($self, $x, $y) = @_;
  return ($self->{'arms'} == 4
          || defined($self->xy_to_n($x,$y)));
}

#------------------------------------------------------------------------------

# FIXME: half size of R5DragonCurve ?
#
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### R5DragonCurve rect_to_n_range(): "$x1,$y1  $x2,$y2"

  my $xmax = int(max(abs($x1),abs($x2)));
  my $ymax = int(max(abs($y1),abs($y2)));
  return (0,
          ($xmax*$xmax + $ymax*$ymax)
          * 6
          * $self->{'arms'});
}

#-----------------------------------------------------------------------------
# level_to_n_range()

#           arms=1       arms=2
# level 0  0..0  = 1    0..1  = 2
# level 1  0..4  = 5    0..9  = 10
# level 2  0..24 = 25   0..49 = 50

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0, 5**$level * $self->{'arms'} - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  _divrem_mutate ($n, $self->{'arms'});
  my ($pow, $exp) = round_up_pow ($n+1, 5);
  return $exp;
}

#-----------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Math-PlanePath Nlevel et al terdragon ie Xmod10 Ymod10 Jorg Arndt

=head1 NAME

Math::PlanePath::R5DragonMidpoint -- R5 dragon curve midpoints

=head1 SYNOPSIS

 use Math::PlanePath::R5DragonMidpoint;
 my $path = Math::PlanePath::R5DragonMidpoint->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Arndt, Jorg>This is midpoints of the R5 dragon curve by Jorg Arndt,

                                       31--30                       11
                                        |   |
                                       32  29                       10
                                        |   |
               51--50          35--34--33  28--27--26                9
                |   |           |                   |
               52  49          36--37--38  23--24--25                8
                |   |                   |   |
       55--54--53  48--47--46  41--40--39  22                        7
        |                   |   |           |
       56--57--58  63--64  45  42  19--20--21                        6
                |   |   |   |   |   |
       81--80  59  62  65  44--43  18--17--16  11--10                5
        |   |   |   |   |                   |   |   |
       82  79  60--61  66--67--68          15  12   9                4
        |   |                   |           |   |   |
    ..-83  78--77--76  71--70--69          14--13   8-- 7-- 6        3
                    |   |                                   |
                   75  72                           3-- 4-- 5        2
                    |   |                           |
                   74--73                           2                1
                                                    |
                                                0-- 1           <- Y=0

        ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^
      -10  -9  -8  -7  -6  -5  -4  -3  -2  -1  X=0  1   2   3

The points are the middle of each edge of the C<R5DragonCurve>, rotated -45
degrees, shrunk by sqrt(2). and shifted to the origin.

              *--11--*     *--7--*     R5DragonCurve
              |      |     |     |     and its midpoints
             12     10     8     6
              |      |     |     |
       *--17--*--13--*--9--*--5--*
       |      |      |     |
      18     16     14     4
       |      |      |     |
    ..-*      *--15--*     *--3--*
                                 |
                                 2
                                 |
                           +--1--*

=head2 Arms

Multiple copies of the curve can be selected, each advancing successively.
Like the main C<R5DragonCurve> this midpoint curve covers 1/4 of the plane
and 4 arms rotated by 0, 90, 180, 270 degrees mesh together perfectly.  With
4 arms all integer X,Y points are visited.

C<arms =E<gt> 4> begins as follows.  N=0,4,8,12,16,etc is the first arm (the
same shape as the plain curve above), then N=1,5,9,13,17 the second,
N=2,6,10,14 the third, etc.

    arms=>4     76--80-...                                6
                 |
                72--68--64  44--40                        5
                         |   |   |
                25--21  60  48  36                        4
                 |   |   |   |   |
                29  17  56--52  32--28--24  75--79        3
                 |   |                   |   |   |
        41--37--33  13-- 9-- 5  12--16--20  71  83        2
         |                   |   |           |   |
        45--49--53   6-- 2   1   8  59--63--67  ...       1
                 |   |           |   |
    ... 65--61--57  10   3   0-- 4  55--51--47        <- Y=0
     |   |           |   |                   |
    81  69  22--18--14   7--11--15  35--39--43           -1
     |   |   |                   |   |
    77--73  26--30--34  54--58  19  31                   -2
                     |   |   |   |   |
                    38  50  62  23--27                   -3
                     |   |   |
                    42--46  66--70--74                   -4
                                     |
                            ...-82--78                   -5

     ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^
    -6  -5  -4  -3  -2  -1  X=0  1   2   3   4   5

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::R5DragonMidpoint-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional positions give an X,Y position along a straight line between the
integer positions.

=item C<$n = $path-E<gt>n_start()>

Return 0, the first N in the path.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 5**$level - 1)>, or for multiple arms return C<(0, $arms *
5**$level - 1)>.

There are 5^level segments comprising the curve, or arms*5^level when
multiple arms, numbered starting from 0.

=back

=head1 FORMULAS

=head2 X,Y to N

An X,Y point can be turned into N by dividing out digits of a complex base
1+2i.  At each step the low base-5 digit is formed from X,Y and an
adjustment applied to move X,Y to a multiple of 1+2i ready to divide out.

A 10x10 table is used for the digit and adjustments, indexed by Xmod10 and
Ymod10.  There's probably an a*X+b*Y mod 5 or mod 20 for a smaller table.
But in any case once the adjustment is found the result is

    Ndigit = digit_table[X mod 10, Y mod 10]  # low to high
    Xm = X + Xadj_table [X mod 10, Y mod 10]
    Ym = Y + Yadj_table [X mod 10, Y mod 10]

    new X,Y = (Xm,Ym) / (1+2i)
            = (Xm,Ym) * (1-2i) / 5
            = ((Xm+2*Ym)/5, (Ym-2*Xm)/5)

These X,Y reductions eventually reach one of the starting points for the
four arms

    X,Y endpoint   Arm        +---+---+
    ------------   ---        | 2 | 1 |  Y=1
        0, 0        0         +---+---+     
        0, 1        1         | 3 | 0 |  Y=0
       -1, 1        2         +---+---+     
       -1, 0        3         X=-1 X=0      

For arms 1 and 3 the digits must be flipped 4-digit, so 0,1,2,3,4 ->
4,3,2,1,0.  The arm number and hence whether this flip is needed is not
known until reaching the endpoint.

    if arm odd
    then  N = 5^numdigits - 1 - N

If only some of the arms are of interest then reaching one of the other arm
numbers means the original X,Y was outside the desired curve.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::R5DragonCurve>

L<Math::PlanePath::DragonMidpoint>,
L<Math::PlanePath::TerdragonMidpoint>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
