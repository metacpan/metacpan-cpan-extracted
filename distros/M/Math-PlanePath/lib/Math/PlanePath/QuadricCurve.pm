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


package Math::PlanePath::QuadricCurve;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 125;
use Math::PlanePath;
use Math::PlanePath::Base::NSEW;
@ISA = ('Math::PlanePath::Base::NSEW',
        'Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'round_up_pow',
  'digit_split_lowtohigh';
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

# uncomment this to run the ### lines
#use Devel::Comments;

use constant n_start => 0;
use constant class_x_negative => 0;
use constant y_negative_at_n => 5;
use constant sumxy_minimum => 0;  # triangular X>=-Y
use constant diffxy_minimum => 0; # triangular Y<=X so X-Y>=0


#------------------------------------------------------------------------------

#     2---3
#     |   |
# 0---1   4   7---8
#         |   |
#         5---6
#
sub n_to_xy {
  my ($self, $n) = @_;
  ### QuadricCurve n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  my $x;
  {
    my $int = int($n);
    $x = $n - $int;  # frac
    $n = $int;       # BigFloat/BigRat int() gives BigInt, use that
  }
  my $y = $x * 0;     # inherit bignum 0
  my $len = $y + 1;   # inherit bignum 1

  foreach my $digit (digit_split_lowtohigh($n,8)) {
    ### at: "$x,$y  digit=$digit"

    if ($digit == 0) {

    } elsif ($digit == 1) {
      ($x,$y) = (-$y + $len,     # rotate +90 and offset
                 $x);

    } elsif ($digit == 2) {
      $x += $len;    # offset
      $y += $len;

    } elsif ($digit == 3) {
      ($x,$y) = ($y + 2*$len,     # rotate -90 and offset
                 -$x  + $len);

    } elsif ($digit == 4) {
      ($x,$y) = ($y + 2*$len,     # rotate -90 and offset
                 -$x);

    } elsif ($digit == 5) {
      $x += 2*$len;    # offset
      $y -= $len;

    } elsif ($digit == 6) {
      ($x,$y) = (-$y + 3*$len,     # rotate +90 and offset
                 $x - $len);

    } elsif ($digit == 7) {
      ### assert: $digit==7
      $x += 3*$len;    # offset
    }
    $len *= 4;
  }

  ### final: "$x,$y"
  return ($x,$y);
}


#         8
#         |
#         7---6
#             |
#     3---4---5
#     |    
#     2---1
#         |
#         0
#
#                     |
#         *  11--12--13
#       /   \ |
#     2---3  10---9
#   / |   |     \ |
# 0---1   4   7---8
#   \     |   | /
#         5---6
#      \    /
#         *
#
sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### QuadricCurve xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($x < 0) {
    ### neg x ...
    return undef;
  }
  my ($len,$level) = round_down_pow (($x+abs($y)) || 1, 4);
  ### $level
  ### $len
  if (is_infinite($level)) {
    return $level;
  }

  my $diamond_p = sub {
    ### diamond_p(): "$x,$y  len=$len  is ".(($x == 0 && $y == 0) || ($y <= $x && $y > -$x && $y < $len-$x && $y >= $x-$len))
    return (($x == 0 && $y == 0)
            || ($y <= $x
                && $y > -$x
                && $y <  $len-$x
                && $y >= $x-$len));
  };

  my $n = 0;
  foreach (0 .. $level) {
    $n *= 8;
    ### at: "level=$level len=$len   x=$x,y=$y  n=$n"
    if (&$diamond_p()) {
      # digit 0 ...
    } else {
      ($x,$y) = ($y, -($x-$len));   # shift and rotate -90

      if (&$diamond_p()) {
        # digit 1 ...
        $n += 1;
      } else {
        ($x,$y) = (-$y, $x-$len);  # shift and rotate +90

        if (&$diamond_p()) {
          # digit 2 ...
          $n += 2;
        } else {
          ($x,$y) = (-$y, $x-$len);  # shift and rotate +90

          if (&$diamond_p()) {
            # digit 3 ...
            $n += 3;
          } else {
            $x -= $len;

            if (&$diamond_p()) {
              # digit 4 ...
              $n += 4;
            } else {
              ($x,$y) = ($y, -($x-$len));   # shift and rotate -90

              if (&$diamond_p()) {
                # digit 5 ...
                $n += 5;
              } else {
                ($x,$y) = ($y, -($x-$len));   # shift and rotate -90

                if (&$diamond_p()) {
                  # digit 6 ...
                  $n += 6;
                } else {
                  ($x,$y) = (-$y, $x-$len);   # shift and rotate +90

                  if (&$diamond_p()) {
                    # digit 7 ...
                    $n += 7;

                  } else {
                    return undef;
                  }
                }
              }
            }
          }
        }
      }
    }
    $len /= 4;
  }
  ### end at: "x=$x,y=$y   n=$n"
  if ($x != 0 || $y != 0) {
    return undef;
  }
  return $n;
}

# level extends to x= 4^level
#                  level = log4(x)
#
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### QuadricCurve rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  if ($x2 < $x1) {
    $x2 = $x1;   # x2 bigger
  }
  if ($x2 < 0) {
    return (1,0);  # rect all x negative, no points
  }
  $y1 = abs (round_nearest ($y1));
  $y2 = abs (round_nearest ($y2));
  if ($y2 < $y1) {
    $y2 = $y1;   # y2 bigger abs
  }

  my $p4 = $x2+$y2+1;
  ### $p4
  return (0, $p4*$p4);
}

#------------------------------------------------------------------------------
# levels

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0, 8**$level);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  my ($pow, $exp) = round_up_pow ($n, 8);
  return $exp;
}

#------------------------------------------------------------------------------

{
  #                                    0     1  2  3  4  5 6  7
  my @_UNDOCUMENTED__n_to_turn_LSR = (undef, 1,-1,-1, 0, 1,1,-1);
  sub _UNDOCUMENTED__n_to_turn_LSR {
    my ($self, $n) = @_;
    while ($n) {
      if (my $digit = _divrem_mutate($n,8)) {  # lowest non-zero digit
        return $_UNDOCUMENTED__n_to_turn_LSR[$digit];
      }
    }
    return undef;
  }
}


#------------------------------------------------------------------------------
1;
__END__






    #                 0   1   2   3   4   5   6   7   8
    #                                          
    # 8                                               @
    #                                                 |
    # 7                                               +---+
    #                                                     |
    # 6                                           +---+---+
    #                                             |       
    # 5                                           +---+
    #                                                 |
    # 4                                               @---+   +   +---@
    #                                                                 |
    # 3           +---+                                               +
    #             |   |                                                
    # 2       @---+   +   +---@                                       +
    #                 |   |   |                                        
    # 1               +---+   +---+       +---+                       +
    #                             |       |   |                        
    # 0                   +---+---+   @---+   +   +---@---+   +   +---@
    #                     |           |       |   |
    #             +---+   +---+       +       +---+
    #             |   |       |        
    #         @---+   +   +---@       +
    #                 |   |            
    #                 +---+           +
    #                                 |
    #                                 @---+   +   +---@
    #                                                 |
    #                                                 +
    #                                                  
    #                                                 +
    #                                                  
    #                                                 +
    #                                                 |
    #                                                 @

=for stopwords eg Ryde Math-PlanePath zig-zag OEIS

=head1 NAME

Math::PlanePath::QuadricCurve -- eight segment zig-zag

=head1 SYNOPSIS

 use Math::PlanePath::QuadricCurve;
 my $path = Math::PlanePath::QuadricCurve->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is a self-similar zig-zag of eight segments,

                  18-19                                       5
                   |  |                                  
               16-17 20 23-24                                 4
                |     |  |  |                            
               15-14 21-22 25-26                              3
                   |           |                         
            11-12-13    29-28-27                              2
             |           |                               
       2--3 10--9       30-31             58-59    ...        1
       |  |     |           |              |  |     |    
    0--1  4  7--8          32          56-57 60 63-64     <- Y=0
          |  |              |           |     |  |       
          5--6             33-34       55-54 61-62           -1
                               |           |             
                        37-36-35    51-52-53                 -2
                         |           |                   
                        38-39 42-43 50-49                    -3
                            |  |  |     |                
                           40-41 44 47-48                    -4
                                  |  |                   
                                 45-46                       -5
    ^
   X=0 1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16

The base figure is the initial N=0 to N=8,

          2---3
          |   |    
      0---1   4   7---8
              |   |
              5---6

It then repeats, turned to follow edge directions, so N=8 to N=16 is the
same shape going upwards, then N=16 to N=24 across, N=24 to N=32 downwards,
etc.

The result is the base at ever greater scale extending to the right and with
wiggly lines making up the segments.  The wiggles don't overlap.

The name C<QuadricCurve> here is a slight mistake.  Mandelbrot ("Fractal
Geometry of Nature" 1982 page 50) calls any islands initiated from a square
"quadric", only one of which is with sides by this eight segment expansion.
This curve expansion also appears (unnamed) in Mandelbrot's "How Long is the
Coast of Britain", 1967.

=head2 Level Ranges

A given replication extends to

    Nlevel = 8^level
    X = 4^level
    Y = 0

    Ymax = 4^0 + 4^1 + ... + 4^level   # 11...11 in base 4
         = (4^(level+1) - 1) / 3
    Ymin = - Ymax

=head2 Turn

The sequence of turns made by the curve is straightforward.  In the base 8
(octal) representation of N, the lowest non-zero digit gives the turn

   low digit   turn (degrees)
   ---------   --------------
      1            +90  L
      2            -90  R
      3            -90  R
      4              0
      5            +90  L
      6            +90  L
      7            -90  R

When the least significant digit is non-zero it determines the turn, to make
the base N=0 to N=8 shape.  When the low digit is zero it's instead the next
level up, the N=0,8,16,24,etc shape which is in control, applying a turn for
the subsequent base part.  So for example at N=16 = 20 octal 20 is a turn
-90 degrees.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::QuadricCurve-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 8**$level)>.

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A133851> (etc)

=back

    A133851    Y at N=2^k, being successive powers 2^j at k=1mod4

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::QuadricIslands>,
L<Math::PlanePath::KochCurve>

L<Math::Fractal::Curve> -- its F<examples/generator4.pl> is this curve

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
