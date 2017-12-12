# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


# rule=50,58,114,122,178,179,186,242,250
# spacing=2,step=1
# full V with points spaced apart
# math-image --path=CellularRule,rule=50 --all --text
#
# A091018, A090894 using n_start=0
# A196199, A000196, A053186 using n_start=0

package Math::PlanePath::PyramidRows;
use 5.004;
use strict;
use Carp 'croak';
#use List::Util 'min','max';
*min = \&Math::PlanePath::_min;
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 125;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_sqrtint = \&Math::PlanePath::_sqrtint;

use Math::PlanePath::Base::Generic
  'round_nearest';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;

use constant parameter_info_array =>
  [ { name        => 'step',
      share_key   => 'step_2',
      display     => 'Step',
      type        => 'integer',
      minimum     => 0,
      default     => 2,
      width       => 2,
      description => 'How much longer each row is than the preceding.',
    },
    { name            => 'align',
      type            => 'enum',
      share_key       => 'align_crl',
      display         => 'Align',
      default         => 'centre',
      choices         => ['centre', 'right', 'left'],
      choices_display => ['Centre', 'Right', 'Left'],
    },
    Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];

{
  my %align_x_negative_step = (left   => 1,
                               centre => 2);
  sub x_negative {
    my ($self) = @_;
    my $align = $self->{'align'};
    return ($align ne 'right'
            && $self->{'step'} >= $align_x_negative_step{$align});
  }
}
sub x_maximum {
  my ($self) = @_;
  return ($self->{'step'} == 0 || $self->{'align'} eq 'left'
          ? 0    # X=0 vertical, or left X<=0
          : undef);
}
{
  my %x_negative_at_n = (left  => 3,
                         right => 5,
                         up    => 3,
                         down  => 5);
  sub x_negative_at_n {
    my ($self) = @_;
    return (($self->{'align'} eq 'left' && $self->{'step'} >= 1)
            || ($self->{'align'} eq 'centre' && $self->{'step'} >= 2)
            ? $self->n_start + 1
            : undef);
  }
}
sub sumxy_minimum {
  my ($self) = @_;
  # for align=left   step<=1 has X>=-Y so X+Y >= 0
  # for align=centre step<=3 has X>=-Y so X+Y >= 0
  # for align=right X>=0 so X+Y >= 0
  return (($self->{'align'}    eq 'left'   && $self->{'step'} <= 1)
          || ($self->{'align'} eq 'centre' && $self->{'step'} <= 3)
          || ($self->{'align'} eq 'right')
          ? 0
          : undef);
}
sub diffxy_maximum {
  my ($self) = @_;
  # for align=left   X<=0 so X-Y<=0 always
  # for align=centre step<=2 has X<=Y so X-Y<=0
  # for align=right  step<=1 has X<=Y so X-Y<=0
  return (($self->{'align'}    eq 'left')
          || ($self->{'align'} eq 'centre' && $self->{'step'} <= 2)
          || ($self->{'align'} eq 'right'  && $self->{'step'} <= 1)
          ? 0
          : undef);
}

sub dx_minimum {
  my ($self) = @_;
  return ($self->{'step'} == 0 ? 0 : undef);
}
sub dx_maximum {
  my ($self) = @_;
  return ($self->{'step'} == 0
          ? 0    # vertical only
          : 1);  # East
}

sub dy_minimum {
  my ($self) = @_;
  return ($self->{'step'} == 0 ? 1 : 0);
}
use constant dy_maximum => 1;
sub _UNDOCUMENTED__dxdy_list {
  my ($self) = @_;
  return ($self->{'step'} == 0 ? (0,1) # N always
          : ());
}

sub absdx_minimum {
  my ($self) = @_;
  return ($self->{'step'} == 0
          || $self->{'align'} eq 'right' # dX=0 at N=1
          || ($self->{'step'} == 1 && $self->{'align'} eq 'centre')
          ? 0 : 1);
}
sub absdy_minimum {
  my ($self) = @_;
  return ($self->{'step'} == 0 ? 1 : 0);
}

# within row X increasing dSum=1
# end row decrease by big
sub dsumxy_minimum {
  my ($self) = @_;
  return ($self->{'step'} == 0 ? 1 : undef);
}
use constant dsumxy_maximum => 1;
sub ddiffxy_minimum {
  my ($self) = @_;
  return ($self->{'step'} == 0 ? -1  # constant North dY=1
          : undef);
}
sub ddiffxy_maximum {
  my ($self) = @_;
  return ($self->{'step'} == 0 ? -1  # constant North dY=1
          : 1);
}

sub dir_minimum_dxdy {
  my ($self) = @_;
  return ($self->{'step'} == 0
          ? (0,1)    # north only
          : (1,0));  # east
}
sub dir_maximum_dxdy {
  my ($self) = @_;
  return ($self->{'step'} == 0
          ? (0,1)    # north only
          : (-1,0)); # supremum, west and 1 up
}

sub turn_any_left {
  my ($self) = @_;
  return ($self->{'step'} != 0);  # always straight vertical only
}
*turn_any_right = \&turn_any_left;


#------------------------------------------------------------------------------

my %align_known = (left   => 1,
                   right  => 1,
                   centre => 1);

sub new {
  my $self = shift->SUPER::new(@_);

  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }

  my $align = ($self->{'align'} ||= 'centre');
  $align_known{$align}
    or croak "Unrecognised align option: ",$align;

  my $step = $self->{'step'};
  $step = $self->{'step'} =
    (! defined $step ? 2 # default
     : $step < 0     ? 0 # minimum
     : $step);

  my $left_slope = $self->{'left_slope'} = ($align eq 'left' ? $step
                                            : $align eq 'right' ? 0
                                            : int($step/2));  # 'centre'
  my $right_slope = $self->{'right_slope'} = $step - $left_slope;

  # "b" term in the quadratic giving N on the Y axis
  $self->{'axis_b'} = $left_slope - $right_slope + 2;

  ### $align
  ### $step
  ### $left_slope
  ### right_slope: $self->{'right_slope'}

  return $self;
}

# step==2 row line beginning at x=-0.5,
# y =          0    1    2    3     4
# N start  = -0.5  1.5  4.5  9.5  16.5
#
#
# step==1
#   N = (1/2*$d^2 + 1/2*$d + 1/2)
#   s = -1/2 + sqrt(2 * $n + -3/4)
# step==2
#   N = ($d^2 + 1/2)
#   s = 0 + sqrt(1 * $n + -1/2)
# step==3
#   N = (3/2*$d^2 + -1/2*$d + 1/2)
#   s = 1/6 + sqrt(2/3 * $n + -11/36)
# step==4
#   N = (2*$d^2 + -1*$d + 1/2)
#   s = 1/4 + sqrt(1/2 * $n + -3/16)
#
# a = $step / 2
# b = 1 - $step / 2 = (2-$step)/2
# c = 0.5
#
# s = (-b + sqrt(4*a*$n + b*b - 4*a*c)) / 2*a
#   = (-b + sqrt(2*$step*$n + b*b - 2*$step*c)) / $step
#   = (-b + sqrt(2*$step*$n + b*b - $step)) / $step
#
# N = a*s*s + b*s + c
#   = $step/2 *s*s + (-$step+2)/2 * s + 1/2
#   = ($step * $d*$d - ($step-2)*$d + 1) / 2
#
# left at - 0.5 - $d*int($step/2)
# so x = $n - (($step * $d*$d - ($step-2)*$d + 1) / 2) - 0.5 - $d*int($step/2)
#      = $n - (($step * $d*$d - ($step-2)*$d + 1) / 2 + 0.5 + $d*int($step/2))
#      = $n - ($step/2 * $d*$d - ($step-2)/2*$d + 1/2 + 0.5 + $d*int($step/2))
#      = $n - ($step/2 * $d*$d - ($step-2)/2*$d + 1 + $d*int($step/2))
#      = $n - ($step/2 * $d*$d - ($step-2)/2*$d + int($step/2)*$d + 1)
#      = $n - ($step/2 * $d*$d - (($step-2)/2 - int($step/2))*$d + 1)
#      = $n - ($step/2 * $d*$d - ($step/2 - int($step/2) - 1)*$d + 1)
#      = $n - ($step/2 * $d*$d - (($step&1)/2 - 1)*$d + 1)
#      = $n - ($step * $d*$d - (($step&1) - 2)*$d + 2)/2
#
sub n_to_xy {
  my ($self, $n) = @_;
  ### PyramidRows n_to_xy(): $n

  # adjust to N=1 at origin X=0,Y=0
  $n = $n - $self->{'n_start'} + 1;

  # $n<0.5 no good for Math::BigInt circa Perl 5.12, compare in integers
  return if 2*$n < 1;

  my $step = $self->{'step'};
  if ($step == 0) {
    # step==0 is vertical line starting N=1 at Y=0
    my $int = round_nearest($n);
    return ($n-$int, $int-1);
  }

  my $neg_b = $step-2;
  my $y = int (($neg_b + _sqrtint(8*$step*$n + $neg_b*$neg_b - 4*$step))
               / (2*$step));

  ### d frac: (($neg_b + sqrt(int(8*$step*$n) + $neg_b*$neg_b - 4*$step)) / (2*$step))
  ### $y
  ### centre N: (($self->{'step'}*$y + $self->{'axis_b'})*$y/2+1)

  return ($n - (($self->{'step'}*$y + $self->{'axis_b'})*$y/2+1),
          $y);
}

sub n_to_radius {
  my ($self, $n) = @_;
  if ($self->{'step'} == 0) {
    $n = $n - $self->{'n_start'};  # to N=0 basis
    if ($n < 0) { return undef; }
    return $n;  # vertical on Y axis, including $n=+infinity or nan
  }
  return $self->SUPER::n_to_radius($n);
}

# N = ($step * $y*$y - ($step-2)*$y + 1) / 2
#
# right polygonal
# P(i) = (k-2)/2 * i*(i+1) - (k-3)*i
#      = [(k-2)/2 *(i+1) - (k-3) ]*i
#      = [(k-2)*(i+1) - 2*(k-3) ]/2*i
#      = [(k-2)*i + k-2 - 2*(k-3) ]/2*i
#      = [(k-2)*i + k-2 - 2k+6) ]/2*i
#      = [(k-2)*i + -k+4 ]/2*i
#
sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);

  if ($y < 0
      || $x < -$y*$self->{'left_slope'}
      || $x > $y*$self->{'right_slope'}) {
    return undef;
  }
  return (($self->{'step'}*$y + $self->{'axis_b'})*$y/2
          + $x
          + $self->{'n_start'});
}

# left N   = ($step * $d*$d - ($step-2)*$d + 1) / 2
# plus .5  = ($step * $d*$d - ($step-2)*$d) / 2 + 1
#          = (($step * $d - ($step-2))*$d) / 2 + 1
#
# left X  = - $d*int($step/2)
# right X = $d * ceil($step/2)
#
# x_bottom_start = - y1 * step_left
# want x2 >= x_bottom_start
#      x2 >= - y1 * step_left
#      x2/step_left >= - y1
#      - x2/step_left <= y1
#      y1 >= - x2/step_left
#      y1 >= ceil(-x2/step_left)
#
# x_bottom_end = y1 * step_right
# want x1 <= x_bottom_end
#      x1 <= y1 * step_right
#      y1 * step_right >= x1
#      y1 >= ceil(x1/step_right)
#
# left N = (($step * $y1 - ($step-2))*$y1) / 2 + 1
# bottom_offset = $x1 - $y1 * $step_left
# N lo   = leftN + bottom_offset
#        = ((step * y1 - (step-2))*y1) / 2 + 1 + x1 - y1 * step_left
#        = ((step * y1 - (step-2)-2*step_left)*y1) / 2 + 1 + x1
# step_left = floor(step/2)
# 2*step_left = step - step&1
# N lo   = ((step * y1 - (step-2)-2*step_left)*y1) / 2 + 1 + x1

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### PyramidRows rect_to_n_range(): "$x1,$y1, $x2,$y2  step=$self->{'step'}"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); } # swap to y1<=y2
  if ($y2 < 0) {
    return (1, 0); # rect all negative, no N
  }
  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); } # swap to x1<=x2

  my $left_slope = $self->{'left_slope'};
  my $right_slope = $self->{'right_slope'};

  my $x_top_right = $y2 * $right_slope;
  ### $x_top_right
  ### x_top_left: - $y2 * $left_slope

  # \    |    /
  #  \   |   /
  #   \  |  /  +-----    x_top_right > x1
  #    \ | /   |x1,y2
  #     \|/
  # -----+-----------
  #
  #       \    |    x_top_start = -y2*step_left
  # -----+ \   |      x_top_start < x2
  # x2,y2|  \  |
  #          \ | /
  #           \|/
  # -----------+--
  #
  if ($x1 > $x_top_right
      || $x2 < - $y2 * $left_slope) {
    ### rect all off to the left or right, no N ...
    return (1, 0);
  }

  ### x1 to x2 of top row y2 intersects some of the pyramid ...
  ### assert: $x2 >= -$y2*$left_slope
  ### assert: $x1 <= $y2*$right_slope

  # raise y1 to the lowest row of the rectangle which intersects some of the
  # pyramid
  $y1 = max ($y1,
             0,

             # for x2 >= x_bottom_left, round up
             $left_slope && int((-$x2+$left_slope-1)/$left_slope),

             # for x1 <= x_bottom_right, round up
             $right_slope && int(($x1+$right_slope-1)/$right_slope),
            );
  ### $y1
  ### y1 for bottom left: $left_slope && int((-$x2+$left_slope-1)/$left_slope)
  ### y1 for bottom right: $right_slope && int(($x1+$right_slope-1)/$right_slope)
  ### assert: $x2 >= -$y1*$left_slope
  ### assert: $x1 <= $y1*$right_slope

  return ($self->xy_to_n (max($x1, -$y1*$left_slope), $y1),
          $self->xy_to_n (min($x2, $x_top_right), $y2));


  # my $step = $self->{'step'};
  # my $sub = ($step&1) - 2;
  #
  # ### x bottom start: -$y1*$left_slope
  # ### x bottom end: $y1*$right_slope
  # ### $x1
  # ### $x2
  # ### bottom left x: max($x1, -$y1*$left_slope)
  # ### top right x: min ($x2, $x_top_end)
  # ### $y1
  # ### $y2
  # ### n_lo: (($step * $y1 - $sub)*$y1 + 2)/2 + max($x1, -$y1*$left_slope)
  # ### n_hi: (($step * $y2 - $sub)*$y2 + 2)/2 + min($x2, $x_top_end)
  #
  # ### assert: $y1-1==$y1 || (($step * $y1 - $sub)*$y1 + 2) == int (($step * $y1 - $sub)*$y1 + 2)
  # ### assert: $y2-1==$y2 || (($step * $y2 - $sub)*$y2 + 2) == int (($step * $y2 - $sub)*$y2 + 2)

  # (($step * $y1 - $sub)*$y1 + 2)/2
  #           + max($x1, -$y1*$left_slope),  # x_bottom_start
  #
  #           (($step * $y2 - $sub)*$y2 + 2)/2
  #           + min($x2, $x_top_end));
  #
  #   # return ($self->xy_to_n (max ($x1, -$y1*$left_slope), $y1),
  #   #         $self->xy_to_n (min ($x2, $x_top_end),      $y2));
}

1;
__END__

=for stopwords pronic PlanePath Ryde Math-PlanePath ie Pentagonals onwards factorizations OEIS

=head1 NAME

Math::PlanePath::PyramidRows -- points stacked up in a pyramid

=head1 SYNOPSIS

 use Math::PlanePath::PyramidRows;
 my $path = Math::PlanePath::PyramidRows->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path arranges points in successively wider rows going upwards so as to
form an upside-down pyramid.  The default step is 2, ie. each row 2 wider
than the preceding, an extra point at the left and the right,

    17  18  19  20  21  22  23  24  25         4
        10  11  12  13  14  15  16             3
             5   6   7   8   9                 2
                 2   3   4                     1
                     1                   <-  Y=0

    -4  -3  -2  -1  X=0  1   2   3   4 ...

X<Square numbers>The right end N=1,4,9,16,etc is the perfect squares.  The
vertical 2,6,12,20,etc at x=-1 is the X<Pronic numbers>pronic numbers
s*(s+1), half way between those successive squares.

The step 2 is the same as the C<PyramidSides>, C<Corner> and C<SacksSpiral>
paths.  For the C<SacksSpiral>, spiral arms going to the right correspond to
diagonals in the pyramid, and arms to the left correspond to verticals.

=head2 Step Parameter

A C<step> parameter controls how much wider each row is than the preceding,
to make wider pyramids.  For example step 4

    my $path = Math::PlanePath::PyramidRows->new (step => 4);

makes each row 2 wider on each side successively

   29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45        4
         16 17 18 19 20 21 22 23 24 25 26 27 28              3
                7  8  9 10 11 12 13 14 15                    2
                      2  3  4  5  6                          1
                            1                          <-  Y=0

         -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6 ...

If the step is an odd number then the extra is at the right, so step 3 gives

    13  14  15  16  17  18  19  20  21  22        3
         6   7   8   9  10  11  12                2
             2   3   4   5                        1
                 1                          <-  Y=0

    -3  -2  -1  X=0  1   2   3   4 ...

Or step 1 goes solely to the right.  This is equivalent to the Diagonals
path, but columns shifted up to make horizontal rows.

    step => 1

    11  12  13  14  15                4
     7   8   9  10                    3
     4   5   6                        2
     2   3                            1
     1                          <-  Y=0

    X=0  1   2   3   4 ...

Step 0 means simply a vertical, each row 1 wide and not increasing.  This is
unlikely to be much use.  The Rows path with C<width> 1 does this too.

    step => 0

     5        4
     4        3
     3        2
     2        1
     1    <-y=0

    X=0

Various number sequences fall in regular patterns positions depending on the
step.  Large steps are not particularly interesting and quickly become very
wide.  A limit might be desirable in a user interface, but there's no limit
in the code as such.

=head2 Align Parameter

An optional C<align> parameter controls how the points are arranged relative
to the Y axis.  The default shown above is "centre".

"right" means points to the right of the axis,

=cut

# math-image --path=PyramidRows,align=right --all --output=numbers

=pod

    align=>"right"

    26  27  28  29  30  31  32  33  34  35  36        5
    17  18  19  20  21  22  23  24  25                4
    10  11  12  13  14  15  16                        3
     5   6   7   8   9                                2
     2   3   4                                        1
     1                                            <- Y=0

    X=0  1   2   3   4   5   6   7   8   9  10

"left" is similar but to the left of the Y axis, ie. into negative X.

=cut

# math-image --path=PyramidRows,align=left --all --output=numbers

=pod

    align=>"left"

    26  27  28  29  30  31  32  33  34  35  36        5
            17  18  19  20  21  22  23  24  25        4
                    10  11  12  13  14  15  16        3
                             5   6   7   8   9        2
                                     2   3   4        1
                                             1    <- Y=0

    -10 -9  -8  -7  -6  -5  -4  -3  -2  -1  X=0

The step parameter still controls how much longer each row is than its
predecessor.

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, in the same rows sequence.  For
example to start at 0,

=cut

# math-image --path=PyramidRows,n_start=0 --all --output=numbers --size=48x5

=pod

    n_start => 0

    16 17 18 19 20 21 22 23 24        4 
        9 10 11 12 13 14 15           3 
           4  5  6  7  8              2 
              1  2  3                 1 
                 0                <- Y=0
    --------------------------
    -4 -3 -2 -1 X=0 1  2  3  4

=head2 Step 3 Pentagonals

For step=3 the pentagonal numbers 1,5,12,22,etc, P(k) = (3k-1)*k/2, are at
the rightmost end of each row.  The second pentagonal numbers 2,7,15,26,
S(k) = (3k+1)*k/2 are the vertical at x=-1.  Those second numbers are
obtained by P(-k), and the two together are the "generalized pentagonal
numbers".

Both these sequences are composites from 12 and 15 onwards, respectively,
and the immediately preceding P(k)-1, P(k)-2, and S(k)-1, S(k)-2 are too.
They factorize simply as

    P(k)   = (3*k-1)*k/2
    P(k)-1 = (3*k+2)*(k-1)/2
    P(k)-2 = (3*k-4)*(k-1)/2
    S(k)   = (3*k+1)*k/2
    S(k)-1 = (3*k-2)*(k+1)/2
    S(k)-2 = (3*k+4)*(k-1)/2

Plotting the primes on a step=3 C<PyramidRows> has the second pentagonal
S(k),S(k)-1,S(k)-2 as a 3-wide vertical gap of no primes at X=-1,-2,-3.  The
the plain pentagonal P(k),P(k-1),P(k)-2 are the endmost three N of each row
non-prime.  The vertical is much more noticeable in a plot.

=cut

# math-image --path=PyramidRows,step=3 --all --output=numbers --size=128x7

=pod

       no primes these three columns         no primes these end three
         except the low 2,7,13                     except low 3,5,11
               |  |  |                                /  /  /
     52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70
        36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51
           23 24 25 26 27 28 29 30 31 32 33 34 35
              13 14 15 16 17 18 19 20 21 22
                  6  7  8  9 10 11 12
                     2  3  4  5
                        1
     -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8  9 10 11 ...

With align="left" the end values can be put into columns,

=cut

# math-image --path=PyramidRows,step=3,align=left --all --output=numbers --size=150x6

=pod

                                no primes these end three
    align => "left"                  except low 3,5,11
                                            |  |  |
    36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51        5
             23 24 25 26 27 28 29 30 31 32 33 34 35        4
                      13 14 15 16 17 18 19 20 21 22        3
                                6  7  8  9 10 11 12        2
                                         2  3  4  5        1
                                                  1    <- Y=0
              ... -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0

In general a constant offset S(k)-c is a column and from P(k)-c is a
diagonal sloping up dX=2,dY=1 right.  The simple factorizations above using
the roots of the quadratic P(k)-c or S(k)-c is possible whenever 24*c+1 is a
perfect square.  This means the further columns S(k)-5, S(k)-7, S(k)-12, etc
also have no primes.

The columns S(k), S(k)-1, S(k)-2 are prominent because they're adjacent.
There's no other adjacent columns of this type because the squares after 49
are too far apart for 24*c+1 to be a square for successive c.  Of course
there could be other reasons for other columns or diagonals to have few or
many primes.

=cut

# (3/2)*k^2 + (1/2)*k - c
# roots (-1/2 +/- sqrt ((1/2)^2 - 4*(3/2)*-c)) / (2*(3/2))
#     = (-1/2 +/- sqrt (1/4 + (12/2)*c)) / 3
#     = -1/6 +/- sqrt (1/4 + (12/2)*c)/3
#     = -1/6 +/- sqrt (1/4 + 6*c)/3
#     = -1/6 +/- sqrt (1/4 + 6*c)*2/6
#     = -1/6 +/- sqrt (4*(1/4 + 6*c))/6
#     = -1/6 +/- sqrt(1 + 24c)/6
#     must have 1+24c a perfect square to factorize by roots
#
# i   i^2   i^2 mod 24
#  0    0    0
#  1    1    1          1+0*24
#  2    4    4
#  3    9    9
#  4   16   16
#  5   25    1          1+1*24
#  6   36   12
#  7   49    1          1+2*24
#  8   64   16
#  9   81    9
# 10  100    4
# 11  121    1          1+5*24
# 12  144    0
# 13  169    1          1+7*24
# 14  196    4
# 15  225    9
# 16  256   16
# 17  289    1          1+12*24
# 18  324   12
# 19  361    1          1+15*24
# 20  400   16
# 21  441    9
# 22  484    4
# 23  529    1          1+22*24
#

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::PyramidRows-E<gt>new ()>

=item C<$path = Math::PlanePath::PyramidRows-E<gt>new (step =E<gt> $integer, align =E<gt> $str, n_start =E<gt> $n)>

Create and return a new path object.  The default C<step> is 2.  C<align> is
a string, one of

    "centre"    the default
    "right"     points aligned right of the Y axis
    "left"      points aligned left of the Y axis

Points are always numbered from left to right in the rows, the alignment
changes where each row begins (or ends).

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

For C<$n <= 0> the return is an empty list since the path starts at N=1.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are
each rounded to the nearest integer, which has the effect of treating each
point in the pyramid as a square of side 1.  If C<$x,$y> is outside the
pyramid the return is C<undef>.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=back

=head2 Descriptive Methods

=over

=item C<$x = $path-E<gt>sumxy_minimum()>

=item C<$x = $path-E<gt>sumxy_maximum()>

Return the minimum or maximum values taken by coordinate sum X+Y reached by
integer N values in the path.  If there's no minimum or maximum then return
C<undef>.

The path is right and above the X=-Y diagonal, thus giving a minimum sum, in
the following cases.

    align      condition for sumxy_minimum=0
    ------     -----------------------------
    centre              step <= 3
    right               always
    left                step <= 1

=item C<$x = $path-E<gt>diffxy_minimum()>

=item C<$x = $path-E<gt>diffxy_maximum()>

Return the minimum or maximum values taken by coordinate difference X-Y
reached by integer N values in the path.  If there's no minimum or maximum
then return C<undef>.

The path is left and above the X=Y leading diagonal, thus giving a minimum
X-Y difference, in the following cases.

    align      condition for diffxy_minimum=0
    ------     -----------------------------
    centre              step <= 2
    right               step <= 1
    left                always

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include

=over

L<http://oeis.org/A023531> (etc)

=back

    step=1
      A002262    X coordinate, runs 0 to k
      A003056  	 Y coordinate, k repeated k+1 times
      A051162    X+Y sum
      A025581  	 Y-X diff, runs k to 0
      A079904    X*Y product
      A069011    X^2+Y^2, n_to_rsquared()
      A080099    X bitwise-AND Y
      A080098    X bitwise-OR  Y
      A051933    X bitwise-XOR Y
      A050873    GCD(X+1,Y+1) greatest common divisor by rows
      A051173    LCM(X+1,Y+1) least common multiple by rows

      A023531    dY, being 1 at triangular numbers (but starting n=0)
      A167407    dX-dY, change in X-Y (extra initial 0)
      A129184    turn 1=left, 0=right or straight

      A079824    N total along each opposite diagonal
      A000124    N on Y axis (triangular+1)
      A000217    N on X=Y diagonal, extra initial 0
    step=1, n_start=0
      A109004    GCD(X,Y) greatest common divisor starting (0,0)
      A103451    turn 1=left or right,0=straight, but extra initial 1
      A103452    turn 1=left,0=straight,-1=right, but extra initial 1

    step=2
      A196199    X coordinate, runs -n to +n
      A000196    Y coordinate, n appears 2n+1 times
      A053186    X+Y, being distance to next higher square
      A010052    dY,  being 1 at perfect square row end
      A000290    N on X=Y diagonal, extra initial 0
      A002522    N on X=-Y North-West diagonal (start row), Y^2+1
      A004201    N for which X>=0, ie. right hand half
      A020703    permutation N at -X,Y
    step=2, n_start=0
      A005563    N on X=Y diagonal, Y*(Y+2)
      A000290    N on X=-Y North-West diagonal (start row), Y^2
    step=2, n_start=2
      A059100    N on north-west diagonal (start each row), Y^2+2
      A053615    abs(X), runs k..0..k
    step=2, align=right, n_start=0
      A196199    X-Y, runs -k to +k
      A053615    abs(X-Y), runs k..0..k
    step=2, align=left, n_start=0
      A005563    N on Y axis, Y*(Y+2)
    
    step=3
      A180447    Y coordinate, n appears 3n+1 times
      A104249    N on Y axis, Y*(3Y+1)/2+1
      A143689    N on X=-Y North-West diagonal
    step=3, n_start=0
      A005449    N on Y axis, second pentagonals Y*(3Y+1)/2
      A000326    N on diagonal north-west, pentagonals Y*(3Y-1)/2

    step=4
      A084849    N on Y axis
      A001844    N on X=Y diagonal (North-East)
      A058331    N on X=-Y North-West diagonal
      A221217    permutation N at -X,Y
    step=4, n_start=0
      A014105    N on Y axis, the second hexagonal numbers
      A046092    N on X=Y diagonal, 4*triangular numbers
    step=4, align=right, n_start=0
      A060511    X coordinate, amount n exceeds hexagonal number
      A000384    N on Y axis, the hexagonal numbers
      A001105    N on X=Y diagonal, 2*squares

    step=5
      A116668    N on Y axis

    step=6
      A056108    N on Y axis
      A056109    N on X=Y diagonal (North-East)
      A056107    N on X=-Y North-West diagonal

    step=8
      A053755    N on X=-Y North-West diagonal

    step=9
      A006137    N on Y axis
      A038764    N on X=Y diagonal (North-East)

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::PyramidSides>,
L<Math::PlanePath::Corner>,
L<Math::PlanePath::SacksSpiral>,
L<Math::PlanePath::MultipleRings>

L<Math::PlanePath::Diagonals>,
L<Math::PlanePath::DiagonalsOctant>,
L<Math::PlanePath::Rows>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
