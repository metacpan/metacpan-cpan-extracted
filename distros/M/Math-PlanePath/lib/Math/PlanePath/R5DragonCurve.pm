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


package Math::PlanePath::R5DragonCurve;
use 5.004;
use strict;
use List::Util 'first','sum';
use List::Util 'min'; # 'max'
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
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'round_up_pow';
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;
use constant parameter_info_array =>
  [ { name        => 'arms',
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
  my @x_negative_at_n = (undef, 9,5,5,6);
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n[$self->{'arms'}];
  }
}
{
  my @y_negative_at_n = (undef, 54,19,8,7);
  sub y_negative_at_n {
    my ($self) = @_;
    return $y_negative_at_n[$self->{'arms'}];
  }
}

use constant turn_any_straight => 0; # never straight


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'arms'} = max(1, min(4, $self->{'arms'} || 1));
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### R5dragonCurve n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n, $n); }

  my $int = int($n);
  $n -= $int;    # fraction part

  my $zero = ($n * 0);    # inherit bignum 0
  my $one = $zero + 1;    # inherit bignum 1

  my $x = 0;
  my $y = 0;
  my $sx = $zero;
  my $sy = $zero;

  # initial rotation from arm number
  {
    my $rot = _divrem_mutate ($int, $self->{'arms'});
    if ($rot == 0)    { $x = $n;  $sx = $one;  }
    elsif ($rot == 1) { $y = $n;  $sy = $one;  }
    elsif ($rot == 2) { $x = -$n; $sx = -$one; }
    else              { $y = -$n; $sy = -$one; } # rot==3
  }

  foreach my $digit (digit_split_lowtohigh($int,5)) {

    ### at: "$x,$y   side $sx,$sy"
    ### $digit

    if ($digit == 1) {
      ($x,$y) = ($sx-$y, $sy+$x); # rotate +90 and offset
    } elsif ($digit == 2) {
      $x = $sx-$sy - $x;  # rotate 180 and offset diag
      $y = $sy+$sx - $y;
    } elsif ($digit == 3) {
      ($x,$y) = (-$sy - $y, $sx + $x); # rotate +90 and offset vert
    } elsif ($digit == 4) {
      $x -= 2*$sy;  # offset vert 2*
      $y += 2*$sx;
    }

    # add 2*(rot+90), which is multiply by (2i+1)
    ($sx,$sy) = ($sx - 2*$sy,
                 $sy + 2*$sx);
  }

  ### final: "$x,$y   side $sx,$sy"

  return ($x, $y);
}

my @digit_to_dir = (0,1,2,1,0);
my @dir4_to_dx = (1,0,-1,0);
my @dir4_to_dy = (0,1,0,-1);
my @digit_to_nextturn = (1,1,-1,-1);

sub n_to_dxdy {
  my ($self, $n) = @_;
  ### R5dragonCurve n_to_dxdy(): $n

  if ($n < 0) { return; }

  my $int = int($n);
  $n -= $int;    # fraction part

  if (is_infinite($int)) { return ($int, $int); }

  # direction from arm number
  my $dir = _divrem_mutate ($int, $self->{'arms'});

  # plus direction from digits
  my @ndigits = digit_split_lowtohigh($int,5);
  $dir = sum($dir, map {$digit_to_dir[$_]} @ndigits) & 3;

  ### direction: $dir
  my $dx = $dir4_to_dx[$dir];
  my $dy = $dir4_to_dy[$dir];

  # fractional $n incorporated using next turn
  if ($n) {
    # lowest non-4 digit, or 0 if all 4s (implicit 0 above high digit)
    $dir += $digit_to_nextturn[ first {$_!=4} @ndigits, 0 ];
    $dir &= 3;
    ### next direction: $dir
    $dx += $n*($dir4_to_dx[$dir] - $dx);
    $dy += $n*($dir4_to_dy[$dir] - $dy);
  }
  return ($dx, $dy);
}

sub xy_to_n {
  return scalar((shift->xy_to_n_list(@_))[0]);
}
sub xy_to_n_list {
  my ($self, $x, $y) = @_;
  ### R5DragonCurve xy_to_n(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);

  if (is_infinite($x)) {
    return $x;  # infinity
  }
  if (is_infinite($y)) {
    return $y;  # infinity
  }

  if ($x == 0 && $y == 0) {
    return (0 .. $self->arms_count - 1);
  }

  require Math::PlanePath::R5DragonMidpoint;

  my @n_list;
  my $xm = $x+$y;  # rotate -45 and mul sqrt(2)
  my $ym = $y-$x;
  foreach my $dx (0,-1) {
    foreach my $dy (0,1) {
      my $t = $self->Math::PlanePath::R5DragonMidpoint::xy_to_n
        ($xm+$dx, $ym+$dy);

      ### try: ($xm+$dx).",".($ym+$dy)
      ### $t
      next unless defined $t;

      my ($tx,$ty) = $self->n_to_xy($t)
        or next;

      if ($tx == $x && $ty == $y) {
        ### found: $t
        if (@n_list && $t < $n_list[0]) {
          unshift @n_list, $t;
        } else {
          push @n_list, $t;
        }
        if (@n_list == 2) {
          return @n_list;
        }
      }
    }
  }
  return @n_list;
}

#------------------------------------------------------------------------------

# whole plane covered when arms==4
sub xy_is_visited {
  my ($self, $x, $y) = @_;
  return ($self->{'arms'} == 4
          || defined($self->xy_to_n($x,$y)));
}

#------------------------------------------------------------------------------

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### R5DragonCurve rect_to_n_range(): "$x1,$y1  $x2,$y2"
  my $xmax = int(max(abs($x1),abs($x2))) + 1;
  my $ymax = int(max(abs($y1),abs($y2))) + 1;
  return (0,
          ($xmax*$xmax + $ymax*$ymax)
          * 10
          * $self->{'arms'});
}

#------------------------------------------------------------------------------
{
  # This is a search for disallowed digit pairs going from low to high.
  # $state encodes the preceding digit, ie. of lower significance.  Initial
  # $state=1 for no low digits yet.  The initial no low digits skips low
  # digit=1 and then begins the allowing/disallowing on the first non-1
  # digit.
  #
  # The digits are found by repeated _divrem_mutate() in the expectation
  # that with 8 out of 20 digit pairs disallowed, after stripping low 1s, we
  # should be able to usually answer "no" in less work than a full
  # digit_split_lowtohigh(), and since currently that code for base 5 is
  # only repeated divrems anyway.
  #
  my @table
    = (undef,                              # state   prev  allowed pairs
       #                                   # -----   ----  -------------
       [     2,     1,     3,     4, 5 ],  #   1     none
       [     2,     2,     3           ],  #   2      0      00, 20
       [     2,     3, undef, undef, 5 ],  #   3      2      02,    42
       [     2,     4, undef, undef, 5 ],  #   4      3      03,    43
       [     2,     5, undef, undef, 5 ],  #   5      4      04,    44
      );

  sub _UNDOCUMENTED__n_segment_is_right_boundary {
    my ($self, $n) = @_;
    if (is_infinite($n)) { return 0; }
    unless ($n >= 0) { return 0; }
    $n = int($n);

    my $state = 1;
    while ($n) {
      my $digit = _divrem_mutate($n,5);  # low to high
      $state = $table[$state][$digit] || return 0;
    }
    return 1;
  }

  sub _UNDOCUMENTED__n_segment_is_left_boundary {
    my ($self, $n, $level) = @_;
    ### _UNDOCUMENTED__n_segment_is_left_boundary(): $n
    if (is_infinite($n)) { return 0; }
    unless ($n >= 0) { return 0; }
    $n = int($n);

    my $state = 1;
    while ($n) {
      if (defined $level && ($level -= 1) < 0) {
        ### stop at level: "state=$state"
        if ($n) {
          ### N >= 5**$level ...
          return undef;
        }
        last;
        # return 1;
        # return ($state == 2);
      }
      my $digit = 4 - _divrem_mutate($n,5);  # low to high
      $state = $table[$state][$digit] || return 0;
    }
    ### final state: $state
    if (defined $level) {
      if ($level > 0) {
        return ($state != 2);
      } else {
        return 1;
      }
    }
    return ($state != 2);

    # my @table
    #   #       0     1     2  3  4 digit
    #   = (undef,
    #      [    4,    3,    2, 1, 1 ],  # 1 L -> ZYXLL
    #      [undef,undef,undef, 2, 1 ],  # 2 X -> ___XL
    #      [undef,undef,undef, 3    ],  # 3 Y -> ___Y_
    #      [    4,    3,    2, 4    ],  # 4 Z -> ZYXX_
    #     );
    #   my $state = 4;
    #   foreach my $digit (reverse digit_split_lowtohigh($n,5)) { # high to low
    #     $state = $table[$state][$digit] || return 0;
    #   }
    #   return 1;
  }
}


#-----------------------------------------------------------------------------
# level_to_n_range()

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0,  (5**$level + 1) * $self->{'arms'} - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  _divrem_mutate ($n, $self->{'arms'});
  my ($pow, $exp) = round_up_pow ($n, 5);
  return $exp;
}

#-----------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Dragon Math-PlanePath Nlevel et al vertices doublings OEIS Online terdragon ie morphism R5DragonMidpoint radix Jorg Arndt Arndt's fxtbook PlanePath min xy TerdragonCurve arctan gt lt undef diff abs dX dY characterization DDUU

=head1 NAME

Math::PlanePath::R5DragonCurve -- radix 5 dragon curve

=head1 SYNOPSIS

 use Math::PlanePath::R5DragonCurve;
 my $path = Math::PlanePath::R5DragonCurve->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path is a "DDUU" turn pattern similar in nature to the terdragon but on
a square grid and with 5 segments instead of 3.

             31-----30     27-----26                                  5
              |      |      |      |
             32---29/33--28/24----25                                  4
                     |      |
             35---34/38--39/23----22     11-----10      7------6      3
              |      |             |      |      |      |      |
             36---37/41--20/40--21/17--16/12---13/9----8/4-----5      2
                     |      |      |      |      |      |
    --50     47---42/46--19/43----18     15-----14      3------2      1
       |      |      |      |                                  |
    49/53--48/64  45/65--44/68    69                    0------1  <-Y=0

       ^      ^      ^      ^      ^      ^      ^      ^      ^
      -7     -6     -5     -4     -3     -2     -1     X=0     1

The name "R5" is by Jorg Arndt.  The base figure is an "S" shape

    4----5
    |
    3----2
         |
    0----1

which then repeats in self-similar style, so N=5 to N=10 is a copy rotated
+90 degrees, as per the direction of the N=1 to N=2 segment.

    10    7----6
     |    |    |  <- repeat rotated +90
     9---8,4---5
          |
          3----2
               |
          0----1

Like the terdragon there are no reversals or mirroring.  Each replication is
the plain base curve.

The shape of N=0,5,10,15,20,25 repeats the initial N=0 to N=5,

           25                          4
          /
         /           10__              3
        /           /    ----___
      20__         /            5      2
          ----__  /            /
                15            /        1
                            /
                           0       <-Y=0

       ^    ^    ^    ^    ^    ^
      -4   -3   -2   -1   X=0   1


The curve never crosses itself.  The vertices touch at corners like N=4 and
N=8 above, but no edges repeat.

=head2 Spiralling

The first step N=1 is to the right along the X axis and the path then slowly
spirals anti-clockwise and progressively fatter.  The end of each
replication is

    Nlevel = 5^level

Each such point is at arctan(2/1)=63.43 degrees further around from the
previous,

    Nlevel     X,Y     angle (degrees)
    ------    -----    -----
      1        1,0         0
      5        2,1        63.4
     25       -3,4      2*63.4 = 126.8
    125      -11,-2     3*63.4 = 190.3

=head2 Arms

The curve fills a quarter of the plane and four copies mesh together
perfectly rotated by 90, 180 and 270 degrees.  The C<arms> parameter can
choose 1 to 4 such curve arms successively advancing.

C<arms =E<gt> 4> begins as follows.  N=0,4,8,12,16,etc is the first arm (the
same shape as the plain curve above), then N=1,5,9,13,17 the second,
N=2,6,10,14 the third, etc.

    arms => 4
                    16/32---20/63
                      |
    21/60    9/56----5/12----8/59
      |       |       |       |
    17/33--- 6/13--0/1/2/3---4/15---19/35
              |       |       |       |
            10/57----7/14---11/58   23/62
                      |
            22/61---18/34

With four arms every X,Y point is visited twice, except the origin 0,0 where
all four begin.  Every edge between the points is traversed once.

=head2 Tiling

The little "S" shapes of the N=0to5 base shape tile the plane with 2x1
bricks and 1x1 holes in the following pattern,

    +--+-----|  |--+--+-----|  |--+--+---
    |  |     |  |  |  |     |  |  |  |
    |  |-----+-----|  |-----+-----|  |---
    |  |  |  |     |  |  |  |     |  |  |
    +-----|  |-----+-----|  |-----+-----+
    |     |  |  |  |     |  |  |  |     |
    +-----+-----|  |-----+-----|  |-----+
    |  |  |     |  |  |  |     |  |  |  |
    ---|  |-----+-----|  |-----+-----|  |
       |  |  |  |     |  |  |  |     |  |
    ---+-----|  |-----o-----|  |-----+---
    |  |     |  |  |  |     |  |  |  |
    |  |-----+-----|  |-----+-----|  |---
    |  |  |  |     |  |  |  |     |  |  |
    +-----|  |-----+-----|  |-----+-----+
    |     |  |  |  |     |  |  |  |     |
    +-----+-----|  |-----+-----|  |-----+
    |  |  |     |  |  |  |     |  |  |  |
    ---|  |-----+-----|  |-----+-----|  |
       |  |  |  |     |  |  |  |     |  |
    ---+--+--|  |-----+--+--|  |-----+--+

This is the curve with each segment N=2mod5 to N=3mod5 omitted.  A 2x1 block
has 6 edges but the "S" traverses just 4 of them.  The way the blocks mesh
meshes together mean the other 2 edges are traversed by another brick,
possibly a brick on another arm of the curve.

This tiling is also found for example at

=over

L<http://tilingsearch.org/HTML/data182/AL04.html>

Or with enlarged square part,
L<http://tilingsearch.org/HTML/data149/L3010.html>

=back

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::R5DragonCurve-E<gt>new ()>

=item C<$path = Math::PlanePath::R5DragonCurve-E<gt>new (arms =E<gt> 4)>

Create and return a new path object.

The optional C<arms> parameter can make 1 to 4 copies of the curve, each arm
successively advancing.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional C<$n> gives an X,Y position along a straight line between the
integer positions.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  If there's nothing at
C<$x,$y> then return C<undef>.

The curve can visit an C<$x,$y> twice.  The smallest of the these N values
is returned.

=item C<@n_list = $path-E<gt>xy_to_n_list ($x,$y)>

Return a list of N point numbers for coordinates C<$x,$y>.

The origin 0,0 has C<arms_count()> many N since it's the starting point for
each arm.  Other points have up to two Ns for a given C<$x,$y>.  If arms=4
then every C<$x,$y> except the origin has exactly two Ns.

=item C<$n = $path-E<gt>n_start()>

Return 0, the first N in the path.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 5**$level)>, or for multiple arms return C<(0, $arms *
5**$level + ($arms-1))>.

There are 5^level segments in a curve level, so 5^level+1 points numbered
from 0.  For multiple arms there are arms*(5^level+1) points, numbered from
0 so n_hi = arms*(5^level+1)-1.

=back

=head1 FORMULAS

Various formulas for boundary length, area, and more, can be found in the
author's mathematical write-up

=over

L<http://user42.tuxfamily.org/r5dragon/index.html>

=back

=head2 Turn

X<Arndt, Jorg>X<fxtbook>At each point N the curve always turns 90 degrees
either to the left or right, it never goes straight ahead.  As per the code
in Jorg Arndt's fxtbook, if N is written in base 5 then the lowest non-zero
digit gives the turn

    lowest non-0 digit     turn
    ------------------     ----
            1              left
            2              left
            3              right
            4              right

At a point N=digit*5^level for digit=1,2,3,4 the turn follows the shape at
that digit, so two lefts then two rights,

    4*5^k----5^(k+1)
     |
     |
    2*5^k----2*5^k
              |
              |
     0------1*5^k

The first and last unit segments in each level are the same direction, so at
those endpoints it's the next level up which gives the turn.

=head2 Next Turn

The turn at N+1 can be calculated in a similar way but from the lowest non-4
digit.

    lowest non-4 digit     turn
    ------------------     ----
            0              left
            1              left
            2              right
            3              right

This works simply because in N=...z444 becomes N+1=...(z+1)000 and so the
turn at N+1 is given by digit z+1.

=head2 Total Turn

The direction at N, ie. the total cumulative turn, is given by the direction
of each digit when N is written in base 5,

    digit       direction
      0             0
      1             1
      2             2
      3             1
      4             0

    direction = (sum direction for each digit) * 90 degrees

For example N=13 in base 5 is "23" so digit=2 direction=2 plus digit=3
direction=1 gives direction=(2+1)*90 = 270 degrees, ie. south.

Because there's no reversals etc in the replications there's no state to
maintain when considering the digits, just a plain sum of direction for each
digit.

=head1 OEIS

The R5 dragon is in Sloane's Online Encyclopedia of Integer Sequences as,

=over

L<http://oeis.org/A175337> (etc)

=back

    A175337    next turn 0=left,1=right
                 (n=0 is the turn at N=1)

    A006495    level end X, Re(b^k)
    A006496    level end Y, Re(b^k)

    A079004    boundary length N=0 to 5^k, skip initial 7,10
                 being 4*3^k - 2

    A048473    boundary/2 (one side), N=0 to 5^k
                 being half whole, 2*3^n - 1
    A198859    boundary/2 (one side), N=0 to 25^k
                 being even levels, 2*9^n - 1
    A198963    boundary/2 (one side), N=0 to 5*25^k
                 being odd levels, 6*9^n - 1

    A052919,A100702  U part boundary length, N=0 to 5^k

    A007798    1/2 * area enclosed N=0 to 5^k
    A016209    1/4 * area enclosed N=0 to 5^k

    A005058    1/2 * new area N=5^k to N=5^(k+1)
                 being area increments, 5^n - 3^n
    A005059    1/4 * new area N=5^k to N=5^(k+1)
                 being area increments, (5^n - 3^n)/2

    A125831    N middle segment of level k, (5^k-1)/2
    A008776    count single-visited points N=0 to 5^k, being 2*3^k
    A146086    count visited points N=0 to 5^k

    A024024    C[k] boundary lengths, 3^k-k
    A104743    E[k] boundary lengths, 3^k+k

    A135518    1/4 * sum distinct abs(n-other(n)) in level N=0 to 5^k

    arms=1 and arms=3
      A059841    abs(dX), being simply 1,0 repeating
      A000035    abs(dY), being simply 0,1 repeating

    arms=4
      A165211    abs(dY), being 0,1,0,1,1,0,1,0 repeating

=head1 HOUSE OF GRAPHS

House of Graphs entries for the R5 dragon curve as a graph include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=19655> etc

=back

    19655     level=0 (1-segment path)
    568       level=1 (5-segment path)
    25149     level=2
    25147     level=3

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::DragonCurve>,
L<Math::PlanePath::TerdragonCurve>

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
