# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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


# http://d4maths.lowtech.org/mirage/ulam.htm
# http://d4maths.lowtech.org/mirage/img/ulam.gif
#     sample gif of primes made by APL or something
#
# http://www.sciencenews.org/view/generic/id/2696/title/Prime_Spirals
#     Ulam's spiral of primes
#
# http://yoyo.cc.monash.edu.au/%7Ebunyip/primes/primeSpiral.htm
# http://yoyo.cc.monash.edu.au/%7Ebunyip/primes/triangleUlam.htm
#     Pulchritudinous Primes of Ulam spiral.

# http://mathworld.wolfram.com/PrimeSpiral.html
#
# Mark C. Chu-Carroll "The Surprises Never Eend: The Ulam Spiral of Primes"
# http://scienceblogs.com/goodmath/2010/06/the_surprises_never_eend_the_u.php
#
# http://yoyo.cc.monash.edu.au/%7Ebunyip/primes/index.html
# including image highlighting the lines

# S. M. Ellerstein, The square spiral, J. Recreational
# Mathematics 29 (#3, 1998) 188; 30 (#4, 1999-2000), 246-250.
#
# Stein, M. and Ulam, S. M. "An Observation on the
# Distribution of Primes." Amer. Math. Monthly 74, 43-44,
# 1967.
#
# Stein, M. L.; Ulam, S. M.; and Wells, M. B. "A Visual
# Display of Some Properties of the Distribution of Primes."
# Amer. Math. Monthly 71, 516-520, 1964.

# cf sides alternately prime and fibonacci
# A160790 corner N
# A160791 side lengths, alternately integer and triangular adding that integer
# A160792 corner N
# A160793 side lengths, alternately integer and sum primes
# A160794 corner N
# A160795 side lengths, alternately primes and fibonaccis


package Math::PlanePath::SquareSpiral;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 127;
use Math::PlanePath;
*_sqrtint = \&Math::PlanePath::_sqrtint;
use Math::PlanePath::Base::NSEW;
@ISA = ('Math::PlanePath::Base::NSEW',
        'Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest';

# uncomment this to run the ### lines
#use Smart::Comments '###';


# Note: this shared by other paths
use constant parameter_info_array =>
  [
   { name        => 'wider',
     display     => 'Wider',
     type        => 'integer',
     minimum     => 0,
     default     => 0,
     width       => 3,
     description => 'Wider path.',
   },
   Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];

use constant xy_is_visited => 1;

#    2w+4 -- 2w+3 ----- w+2
#      |                 |
#    2w+5      0------- w+1
#      |     
#    2w+6 ---
#                  ^
#                 X=0
#
sub x_negative_at_n {
  my ($self) = @_;
  return $self->n_start + ($self->{'wider'} ? 0 : 4);
}
sub y_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 2*$self->{'wider'} + 6;
}
sub _UNDOCUMENTED__dxdy_list_at_n {
  my ($self) = @_;
  return $self->n_start + 2*$self->{'wider'} + 4;
}

use constant turn_any_right => 0; # only left or straight

sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  return $self->n_start + $self->{'wider'} + 1;
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);

  # parameters
  $self->{'wider'} ||= 0;  # default
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }

  return $self;
}

# wider==0
# base from bottom-right corner
#   d = [ 1,  2,  3,  4 ]
#   N = [ 2, 10, 26, 50 ]
#   N = (4 d^2 - 4 d + 2)
#   d = 1/2 + sqrt(1/4 * $n + -4/16)
#
# wider==1
# base from bottom-right corner
#   d = [ 1,  2,  3,  4 ]
#   N = [ 3, 13, 31, 57 ]
#   N = (4 d^2 - 2 d + 1)
#   d = 1/4 + sqrt(1/4 * $n + -3/16)
#
# wider==2
# base from bottom-right corner
#   d = [ 1,  2,  3, 4 ]
#   N = [ 4, 16, 36, 64 ]
#   N = (4 d^2)
#   d = 0 + sqrt(1/4 * $n + 0)
#
# wider==3
# base from bottom-right corner
#   d = [ 1,  2,  3 ]
#   N = [ 5, 19, 41 ]
#   N = (4 d^2 + 2 d - 1)
#   d = -1/4 + sqrt(1/4 * $n + 5/16)
#
# N = 4*d^2 + (-4+2*w)*d + (2-w)
#   = 4*$d*$d + (-4+2*$w)*$d + (2-$w)
# d = 1/2-w/4 + sqrt(1/4*$n + b^2-4ac)
# (b^2-4ac)/(2a)^2 = [ (2w-4)^2 - 4*4*(2-w) ] / 64
#                  = [ 4w^2 - 16w + 16 - 32 + 16w ] / 64
#                  = [ 4w^2 - 16 ] / 64
#                  = [ w^2 - 4 ] / 16
# d = 1/2-w/4 + sqrt(1/4*$n + (w^2 - 4) / 16)
#   = 1/4 * (2-w + sqrt(4*$n + w^2 - 4))
#   = 0.25 * (2-$w + sqrt(4*$n + $w*$w - 4))
#
# then offset the base by +4*$d+$w-1 for top left corner for +/- remainder
# rem = $n - (4*$d*$d + (-4+2*$w)*$d + (2-$w) + 4*$d + $w - 1)
#     = $n - (4*$d*$d + (-4+2*$w)*$d + 2 - $w + 4*$d + $w - 1)
#     = $n - (4*$d*$d + (-4+2*$w)*$d + 1 - $w + 4*$d + $w)
#     = $n - (4*$d*$d + (-4+2*$w)*$d + 1 + 4*$d)
#     = $n - (4*$d*$d + (2*$w)*$d + 1)
#     = $n - ((4*$d + 2*$w)*$d + 1)
#

sub n_to_xy {
  my ($self, $n) = @_;
  #### SquareSpiral n_to_xy: $n

  $n = $n - $self->{'n_start'};  # starting $n==0, warn if $n==undef
  if ($n < 0) {
    #### before n_start ...
    return;
  }

  my $w = $self->{'wider'};
  my $w_right = int($w/2);
  my $w_left = $w - $w_right;
  if ($n <= $w+1) {
    #### centre horizontal
    # n=0 at w_left
    # x = $n - int(($w+1)/2)
    #   = $n - int(($w+1)/2)
    return ($n - $w_left,  # n=0 at w_left
            0);
  }

  my $d = int ((2-$w + _sqrtint(4*$n + $w*$w)) / 4);
  #### d frac: ((2-$w + sqrt(int(4*$n) + $w*$w)) / 4)
  #### $d

  #### base: 4*$d*$d + (-4+2*$w)*$d + (2-$w)
  $n -= ((4*$d + 2*$w)*$d);
  #### remainder: $n

  if ($n >= 0) {
    if ($n <= 2*$d) {
      ### left vertical
      return (-$d - $w_left,
              -$n + $d);
    } else {
      ### bottom horizontal
      return ($n - $w_left - 3*$d,
              -$d);
    }
  } else {
    if ($n >= -2*$d-$w) {
      ### top horizontal
      return (-$n - $d - $w_left,
              $d);
    } else {
      ### right vertical
      return ($d + $w_right,
              $n + 3*$d + $w);
    }
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;

  my $w = $self->{'wider'};
  my $w_right = int($w/2);
  my $w_left = $w - $w_right;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### xy_to_n: "x=$x, y=$y"
  ### $w_left
  ### $w_right

  my $d;
  if (($d = $x - $w_right) > abs($y)) {
    ### right vertical
    ### $d
    #
    # base bottom right per above
    ### BR: 4*$d*$d + (-4+2*$w)*$d + (2-$w)
    # then +$d-1 for the y=0 point
    # N_Y0  = 4*$d*$d + (-4+2*$w)*$d + (2-$w) + $d-1
    #       = 4*$d*$d + (-3+2*$w)*$d + (2-$w) + -1
    #       = 4*$d*$d + (-3+2*$w)*$d +  1-$w
    ### N_Y0: (4*$d + -3 + 2*$w)*$d + 1-$w
    #
    return (4*$d + -3 + 2*$w)*$d - $w + $y + $self->{'n_start'};
  }

  if (($d = -$x - $w_left) > abs($y)) {
    ### left vertical
    ### $d
    #
    # top left per above
    ### TL: 4*$d*$d + (2*$w)*$d + 1
    # then +$d for the y=0 point
    # N_Y0  = 4*$d*$d + (2*$w)*$d + 1 + $d
    #       = 4*$d*$d + (1 + 2*$w)*$d + 1
    ### N_Y0: (4*$d + 1 + 2*$w)*$d + 1
    #
    return (4*$d + 1 + 2*$w)*$d - $y + $self->{'n_start'};
  }

  $d = abs($y);
  if ($y > 0) {
    ### top horizontal
    ### $d
    #
    # top left per above
    ### TL: 4*$d*$d + (2*$w)*$d + 1
    # then -($d+$w_left) for the x=0 point
    # N_X0  = 4*$d*$d + (2*$w)*$d + 1 + -($d+$w_left)
    #       = 4*$d*$d + (-1 + 2*$w)*$d + 1 - $w_left
    ### N_Y0: (4*$d - 1 + 2*$w)*$d + 1 - $w_left
    #
    return (4*$d - 1 + 2*$w)*$d - $w_left - $x + $self->{'n_start'};
  }

  ### bottom horizontal, and centre y=0
  ### $d
  #
  # top left per above
  ### TL: 4*$d*$d + (2*$w)*$d + 1
  # then +2*$d to bottom left, +$d+$w_left for the x=0 point
  # N_X0  = 4*$d*$d + (2*$w)*$d + 1 + 2*$d + $d+$w_left)
  #       = 4*$d*$d + (3 + 2*$w)*$d + 1 + $w_left
  ### N_Y0: (4*$d + 3 + 2*$w)*$d + 1 + $w_left
  #
  return (4*$d + 3 + 2*$w)*$d + $w_left + $x + $self->{'n_start'};
}

# hi is exact but lo is not
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  # ENHANCE-ME: find actual minimum if rect doesn't cover 0,0
  return ($self->{'n_start'},
          max ($self->xy_to_n($x1,$y1),
               $self->xy_to_n($x2,$y1),
               $self->xy_to_n($x1,$y2),
               $self->xy_to_n($x2,$y2)));

  # my $w = $self->{'wider'};
  # my $w_right = int($w/2);
  # my $w_left = $w - $w_right;
  #
  # my $d = 1 + max (abs($y1),
  #                  abs($y2),
  #                  $x1 - $w_right, -$x1 - $w_left,
  #                  $x2 - $w_right, -$x2 - $w_left,
  #                  1);
  # ### $d
  # ### is: $d*$d
  #
  # # ENHANCE-ME: find actual minimum if rect doesn't cover 0,0
  # return (1,
  #         (4*$d - 4 + 2*$w)*$d + 2);  # bottom-right
}


# [ 1, 2, 3,  4,  5 ],
# [ 1, 3, 7, 13, 21 ]
# N = (d^2 - d + 1)
#   = ($d**2 - $d + 1)
#   = (($d - 1)*$d + 1)
# d = 1/2 + sqrt(1 * $n + -3/4)
#   = (1 + sqrt(4*$n - 3)) / 2
#
# wider=3
# [ 2, 3,  4,  5 ],
# [ 6, 13, 22, 33 ]
# N = (d^2 + 2 d - 2)
#   = ($d**2 + 2*$d - 2)
#   = (($d + 2)*$d - 2)
# d = -1 + sqrt(1 * $n + 3)
#
# wider=5
# [ 2, 3,  4,  5 ],
# [ 8, 17, 28, 41 ]
# N = (d^2 + 4 d - 4)
#   = ($d**2 + 4*$d - 4)
#   = (($d + 4)*$d - 4)
# d = -2 + sqrt(1 * $n + 8)
#
# wider=7
# [ 2, 3,  4,  5 ],
# [ 10, 21, 34, 49 ]
# N = (d^2 + 6 d - 6)
#   = ($d**2 + 6*$d - 6)
#   = (($d + 6)*$d - 6)
# d = -3 + sqrt(1 * $n + 15)
#
#
# N = (d^2 + (w-1)*d + 1-w)
# d = (1-w)/2 + sqrt($n + (w^2 + 2w - 3)/4)
#   = (1-w + sqrt(4*$n + (w-3)(w+1))) / 2
#
# extra subtract d+w-1
# Nbase = (d^2 + (w-1)*d + 1-w) + d+w-1
#       = d^2 + w*d

sub n_to_dxdy {
  my ($self, $n) = @_;
  ### n_to_dxdy(): $n

  $n = $n - $self->{'n_start'};  # starting $n==0, warn if $n==undef
  if ($n < 0) {
    #### before n_start ...
    return;
  }

  my $w = $self->{'wider'};
  my $d = int((1-$w + _sqrtint(4*$n + ($w+2)*$w+1)) / 2);

  my $int = int($n);
  $n -= $int;  # fraction 0 <= $n < 1
  $int -= ($d+$w)*$d-1;

  ### $d
  ### $w
  ### $n
  ### $int

  my ($dx, $dy);
  if ($int <= 0) {
    if ($int < 0) {
      ### horizontal ...
      $dx = 1;
      $dy = 0;
    } else {
      ### corner horiz to vert ...
      $dx = 1-$n;
      $dy = $n;
    }
  } else {
    if ($int < $d) {
      ### vertical ...
      $dx = 0;
      $dy = 1;
    } else {
      ### corner vert to horiz ...
      $dx = -$n;
      $dy = 1-$n;
    }
  }

  unless ($d % 2) {
    ### rotate +180 for even d ...
    $dx = -$dx;
    $dy = -$dy;
  }

  ### result: "$dx, $dy"
  return ($dx,$dy);
}



# old bit:
#
# wider==0
# base from two-way diagonal top-right and bottom-left
# s even for top-right diagonal doing top leftwards then left downwards
# s odd for bottom-left diagonal doing bottom rightwards then right pupwards
#   s = [ 0,  1,   2,   3,   4,   5,   6 ]
#   N = [ 1,  1,   3,   7,  13,  21,  31 ]
#         +0  +2  +4  +6  +8  +10
#            2   2   2   2   2
#
#   n = (($d - 1)*$d + 1)
#   s = 1/2 + sqrt(1 * $n + -3/4)
#     = .5 + sqrt ($n - .75)
#
#

#------------------------------------------------------------------------------

sub _NOTDOCUMENTED_n_to_figure_boundary {
  my ($self, $n) = @_;
  ### _NOTDOCUMENTED_n_to_figure_boundary(): $n

  # adjust to N=1 at origin X=0,Y=0
  $n = $n - $self->{'n_start'} + 1;

  if ($n < 1) {
    return undef;
  }

  my $wider = $self->{'wider'};
  if ($n <= $wider) {
    # single block row
    # +---+-----+----+
    # | 1 | ... | $n |  boundary = 2*N + 2
    # +---+-----+----+
    return 2*$n + 2;
  }

  my $d = int((_sqrtint(4*$n + $wider*$wider - 2) - $wider) / 2);
  ### $d
  ### $wider
  ### cmp: $d*($d+1+$wider) + $wider + 1

  if ($n > $d*($d+1+$wider)) {
    $wider++;
    ### increment for +2 after turn ...
  }
  return 4*$d + 2*$wider + 2;
}

#------------------------------------------------------------------------------
1;
__END__


=for stopwords Stanislaw Ulam pronic PlanePath Ryde Math-PlanePath Ulam's Honaker's decagonal OEIS Nbase sqrt BigRat Nrem wl wr Nsig incrementing

=head1 NAME

Math::PlanePath::SquareSpiral -- integer points drawn around a square (or rectangle)

=head1 SYNOPSIS

 use Math::PlanePath::SquareSpiral;
 my $path = Math::PlanePath::SquareSpiral->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path makes a square spiral,

=cut

# math-image --path=SquareSpiral --all --output=numbers_dash --size=40x16

=pod

    37--36--35--34--33--32--31              3
     |                       |
    38  17--16--15--14--13  30              2
     |   |               |   |
    39  18   5---4---3  12  29              1
     |   |   |       |   |   |
    40  19   6   1---2  11  28  ...    <- Y=0
     |   |   |           |   |   |
    41  20   7---8---9--10  27  52         -1
     |   |                   |   |
    42  21--22--23--24--25--26  51         -2
     |                           |
    43--44--45--46--47--48--49--50         -3

                 ^
    -3  -2  -1  X=0  1   2   3   4

See F<examples/square-numbers.pl> for a simple program printing these
numbers.

=head2 Ulam Spiral

This path is well known from Stanislaw Ulam finding interesting straight
lines when plotting the prime numbers on it.

=over

Stein, Ulam and Wells, "A Visual Display of Some Properties of the
Distribution of Primes", American Mathematical Monthly, volume 71, number 5,
May 1964, pages 516-520.  L<http://www.jstor.org/stable/2312588>

=back

=cut

# math-image --wx --path=SquareSpiral --primes

=pod

The cover of Scientific American March 1964 featured this spiral,

=over

L<http://www.nature.com/scientificamerican/journal/v210/n3/covers/index.html>

L<http://oeis.org/A143861/a143861.jpg>

=back

See F<examples/ulam-spiral-xpm.pl> for a standalone program, or see
L<math-image> using this C<SquareSpiral> to draw this pattern and more.

Stein, Ulam and Wells also considered primes on the
L<Math::PlanePath::Corner> path, and on a half-plane like two corners.

=head2 Straight Lines

X<Square numbers>The perfect squares 1,4,9,16,25 fall on two diagonals with
the even perfect squares going to the upper left and the odd squares to the
lower right.  The X<Pronic numbers>pronic numbers 2,6,12,20,30,42 etc k^2+k
half way between the squares fall on similar diagonals to the upper right
and lower left.  The decagonal numbers 10,27,52,85 etc 4*k^2-3*k go
horizontally to the right at Y=-1.

In general straight lines and diagonals are 4*k^2 + b*k + c.  b=0 is the
even perfect squares up to the left, then incrementing b is an eighth turn
anti-clockwise, or clockwise if negative.  So b=1 is horizontal West, b=2
diagonally down South-West, b=3 down South, etc.

Honaker's prime-generating polynomial 4*k^2 + 4*k + 59 goes down to the
right, after the first 30 or so values loop around a bit.

=head2 Wider

An optional C<wider> parameter makes the path wider, becoming a rectangle
spiral instead of a square.  For example

    wider => 3

    29--28--27--26--25--24--23--22        2
     |                           |
    30  11--10-- 9-- 8-- 7-- 6  21        1
     |   |                   |   |
    31  12   1-- 2-- 3-- 4-- 5  20   <- Y=0
     |   |                       |
    32  13--14--15--16--17--18--19       -1
     |
    33--34--35--36-...                   -2

                     ^
    -4  -3  -2  -1  X=0  1   2   3

The centre horizontal 1 to 2 is extended by C<wider> many further places,
then the path loops around that shape.  The starting point 1 is shifted to
the left by ceil(wider/2) places to keep the spiral centred on the origin
X=0,Y=0.

Widening doesn't change the nature of the straight lines which arise, it
just rotates them around.  For example in this wider=3 example the perfect
squares are still on diagonals, but the even squares go towards the bottom
left (instead of top left when wider=0) and the odd squares to the top right
(instead of the bottom right).

Each loop is still 8 longer than the previous, as the widening is basically
a constant amount in each loop.

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start with the same shape.  For example to
start at 0,

=cut

# math-image --path=SquareSpiral,n_start=0 --all --output=numbers_dash --size=35x16

=pod

    n_start => 0

    16-15-14-13-12 ...
     |           |  | 
    17  4--3--2 11 28 
     |  |     |  |  | 
    18  5  0--1 10 27 
     |  |        |  | 
    19  6--7--8--9 26 
     |              | 
    20-21-22-23-24-25 

The only effect is to push the N values around by a constant amount.  It
might help match coordinates with something else zero-based.

=head2 Corners

Other spirals can be formed by cutting the corners of the square so as to go
around faster.  See the following modules,

    Corners Cut    Class
    -----------    -----
         1        HeptSpiralSkewed
         2        HexSpiralSkewed
         3        PentSpiralSkewed
         4        DiamondSpiral

The C<PyramidSpiral> is a re-shaped C<SquareSpiral> looping at the same
rate.  It shifts corners but doesn't cut them.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::SquareSpiral-E<gt>new ()>

=item C<$path = Math::PlanePath::SquareSpiral-E<gt>new (wider =E<gt> $integer, n_start =E<gt> $n)>

Create and return a new square spiral object.  An optional C<wider>
parameter widens the spiral path, it defaults to 0 which is no widening.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

For C<$n E<lt> 1> the return is an empty list, as the path starts at 1.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are
each rounded to the nearest integer, which has the effect of treating each N
in the path as centred in a square of side 1, so the entire plane is
covered.

=back

=head1 FORMULAS

=head2 N to X,Y

There's a few ways to break an N into a side and offset into the side.  One
convenient way is to treat a loop as starting at the bottom right turn, so
N=2,10,26,50,etc, If the first loop at N=2 is reckoned loop number d=1 then
the loop starts at

    Nbase = 4*d^2 - 4*d + 2
          = 2,10,26,50,... for d=1,2,3,4,... 
                   (A069894 but it going from d=0)

For example d=3 is Nbase=4*3^2-4*3+2=26 at X=3,Y=-2.  The biggest d with
Nbase E<lt>= N can be found by inverting with the usual quadratic formula

    d = floor (1/2 + sqrt(N/4 - 1/4))

For Perl it's good to keep the sqrt argument an integer (when a UV integer
is bigger than an NV float, and for BigRat accuracy), so rearranging to

    d = floor ((1+sqrt(N-1)) / 2)

So Nbase from this d leaves a remainder which is an offset into the loop

    Nrem = N - Nbase
         = N - (4*d^2 - 4*d + 2)

The loop starts at X=d,Y=d-1 and has sides length 2d, 2d+1, 2d+1 and 2d+2,

             2d      
         +------------+        <- Y=d
         |            |
    2d   |            |  2d-1
         |     .      |
         |            |
         |            + X=d,Y=-d+1
         |
         +---------------+     <- Y=-d
             2d+1

         ^
       X=-d

The X,Y for an Nrem is then

     side      Nrem range            X,Y result
     ----      ----------            ----------
    right           Nrem <= 2d-1     X = d
                                     Y = -d+1+Nrem
    top     2d-1 <= Nrem <= 4d-1     X = d-(Nrem-(2d-1)) = 3d-1-Nrem
                                     Y = d
    left    4d-1 <= Nrem <= 6d-1     X = -d
                                     Y = d-(Nrem-(4d-1)) = 5d-1-Nrem
    bottom  6d-1 <= Nrem             X = -d+(Nrem-(6d-1)) = -7d+1+Nrem
                                     Y = -d

The corners Nrem=2d-1, Nrem=4d-1 and Nrem=6d-1 get the same result from the
two sides that meet so it doesn't matter if the high comparison is "E<lt>"
or "E<lt>=".

The bottom edge runs through to Nrem E<lt> 8d, but there's no need to
check that since d=floor(sqrt()) above ensures Nrem is within the loop.

A small simplification can be had by subtracting an extra 4d-1 from Nrem to
make negatives for the right and top sides and positives for the left and
bottom.

    Nsig = N - Nbase - (4d-1)
         = N - (4*d^2 - 4*d + 2) - (4d-1)
         = N - (4*d^2 + 1)

     side      Nsig range            X,Y result
     ----      ----------            ----------
    right           Nsig <= -2d      X = d
                                     Y = d+(Nsig+2d) = 3d+Nsig
    top      -2d <= Nsig <= 0        X = -d-Nsig
                                     Y = d
    left       0 <= Nsig <= 2d       X = -d
                                     Y = d-Nsig
    bottom    2d <= Nsig             X = -d+1+(Nsig-(2d+1)) = Nsig-3d
                                     Y = -d

This calculation can be found as an exercise in Graham, Knuth and Patashnik
"Concrete Mathematics", chapter 3 "Integer Functions", exercise 40, page 99.
They start the spiral from 0, and vertically so their x is -Y here.  Their
formula for x(n) tests a floor(2*sqrt(N)) to decide whether on a horizontal
and so whether to apply the equivalent of Nrem to the result.

=head2 N to X,Y with Wider

With the C<wider> parameter stretching the spiral loops the formulas above
become

    Nbase = 4*d^2 + (-4+2w)*d + 2-w

    d = floor ((2-w + sqrt(4N + w^2 - 4)) / 4)

Notice for Nbase the w is a term 2*w*d, being an extra 2*w for each loop.

The left offset ceil(w/2) described above (L</Wider>) for the N=1 starting
position is written here as wl, and the other half wr arises too,

    wl = ceil(w/2)
    wr = floor(w/2) = w - wl

The horizontal lengths increase by w, and positions shift by wl or wr, but
the verticals are unchanged.

             2d+w      
         +------------+        <- Y=d
         |            |
    2d   |            |  2d-1
         |     .      |
         |            |
         |            + X=d+wr,Y=-d+1
         |
         +---------------+     <- Y=-d
             2d+1+w

         ^
       X=-d-wl

The Nsig formulas then have w, wl or wr variously inserted.  In all cases if
w=wl=wr=0 then they simplify to the plain versions.

    Nsig = N - Nbase - (4d-1+w)
         = N - ((4d + 2w)*d + 1)

     side      Nsig range            X,Y result
     ----      ----------            ----------
    right         Nsig <= -(2d+w)    X = d+wr
                                     Y = d+(Nsig+2d+w) = 3d+w+Nsig
    top      -(2d+w) <= Nsig <= 0    X = -d-wl-Nsig
                                     Y = d
    left       0 <= Nsig <= 2d       X = -d-wl
                                     Y = d-Nsig
    bottom    2d <= Nsig             X = -d+1-wl+(Nsig-(2d+1)) = Nsig-wl-3d
                                     Y = -d

=head2 Rectangle to N Range

Within each row the minimum N is on the X=Y diagonal and N values increases
monotonically as X moves away to the left or right.  Similarly in each
column there's a minimum N on the X=-Y opposite diagonal, or X=-Y+1 diagonal
when X negative, and N increases monotonically as Y moves away from there up
or down.  When widerE<gt>0 the location of the minimum changes, but N is
still monotonic moving away from the minimum.

On that basis the maximum N in a rectangle is at one of the four corners,

              |
    x1,y2 M---|----M x2,y2      corner candidates
          |   |    |            for maximum N
       -------O---------
          |   |    |
          |   |    |
    x1,y1 M---|----M x1,y1
              |

=head1 OEIS

This path is in Sloane's Online Encyclopedia of Integer Sequences in various
forms.  Summary at

=over

L<http://oeis.org/A068225/a068225.html>

=back

And various sequences,

=over

L<http://oeis.org/A174344> (etc),
L<https://oeis.org/wiki/Ulam's_spiral>

=back

    wider=0 (the default)
      A174344    X coordinate
      A274923    Y coordinate
      A214526    abs(X)+abs(Y) "Manhattan" distance

      A079813    abs(dY), being k 0s followed by k 1s
      A063826    direction 1=right,2=up,3=left,4=down

      A027709    boundary length of N unit squares
      A078633    grid sticks to make N unit squares

      A033638    N turn positions (extra initial 1, 1)
      A172979    N turn positions which are primes too

      A054552    N values on X axis (East)
      A054556    N values on Y axis (North)
      A054567    N values on negative X axis (West)
      A033951    N values on negative Y axis (South)
      A054554    N values on X=Y diagonal (NE)
      A054569    N values on negative X=Y diagonal (SW)
      A053755    N values on X=-Y opp diagonal X<=0 (NW)
      A016754    N values on X=-Y opp diagonal X>=0 (SE)
      A200975    N values on all four diagonals
      A317186    N on Y axis positive and negative
      A267682    N on Y axis positive and negative (origin twice)

      A137928    N values on X=-Y+1 opposite diagonal
      A002061    N values on X=Y diagonal pos and neg
      A016814    (4k+1)^2, every second N on south-east diagonal

      A143856    N values on ENE slope dX=2,dY=1
      A143861    N values on NNE slope dX=1,dY=2
      A215470    N prime and >=4 primes among its 8 neighbours

      A214664    X coordinate of prime N (Ulam's spiral)
      A214665    Y coordinate of prime N (Ulam's spiral)
      A214666    -X  \ reckoning spiral starting West
      A214667    -Y  /

      A053999    prime[N] on X=-Y opp diagonal X>=0 (SE)
      A054551    prime[N] on the X axis (E)
      A054553    prime[N] on the X=Y diagonal (NE)
      A054555    prime[N] on the Y axis (N)
      A054564    prime[N] on X=-Y opp diagonal X<=0 (NW)
      A054566    prime[N] on negative X axis (W)

      A090925    permutation N at rotate +90
      A090928    permutation N at rotate +180
      A090929    permutation N at rotate +270
      A090930    permutation N at clockwise spiralling
      A020703    permutation N at rotate +90 and go clockwise
      A090861    permutation N at rotate +180 and go clockwise
      A090915    permutation N at rotate +270 and go clockwise
      A185413    permutation N at 1-X,Y
                   being rotate +180, offset X+1, clockwise

      A068225    permutation N to the N to its right, X+1,Y
      A121496     run lengths of consecutive N in that permutation
      A068226    permutation N to the N to its left, X-1,Y
      A020703    permutation N at transpose Y,X
                   (clockwise <-> anti-clockwise)

      A033952    digits on negative Y axis
      A033953    digits on negative Y axis, starting 0
      A033988    digits on negative X axis, starting 0
      A033989    digits on Y axis, starting 0
      A033990    digits on X axis, starting 0

      A062410    total sum previous row or column

    wider=1
      A069894    N on South-West diagonal

The following have "offset 0" in the OEIS and therefore are based on
starting from N=0.

    n_start=0
      A180714    X+Y coordinate sum
      A053615    abs(X-Y), runs n to 0 to n, distance to nearest pronic

      A001107    N on X axis
      A033991    N on Y axis
      A033954    N on negative Y axis, second 10-gonals
      A002939    N on X=Y diagonal North-East
      A016742    N on North-West diagonal, 4*k^2
      A002943    N on South-West diagonal
      A156859    N on Y axis positive and negative

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::PyramidSpiral>

L<Math::PlanePath::DiamondSpiral>,
L<Math::PlanePath::PentSpiralSkewed>,
L<Math::PlanePath::HexSpiralSkewed>,
L<Math::PlanePath::HeptSpiralSkewed>

L<Math::PlanePath::CretanLabyrinth>

L<Math::NumSeq::SpiroFibonacci>

X11 cursor font "box spiral" cursor which is this style (but going
clockwise).

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
