# Copyright 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


# x=45,y=10 x=59,y=19  dx=14,dy=9 14/9=1.55
#
# x=42,y=8 x=113,y=52 dx=71,dy=44 71/44=1.613
#
# below
# 32,12 to 36,4 sqrt((32-36)^2+(12-4)^2) = 9
# 84,34 to 99,14 sqrt((84-99)^2+(34-14)^2) = 25
# 180,64 to 216,11 sqrt((180-216)^2+(64-11)^2) = 64
#
# above
# 14,20 to 5,32 sqrt((14-5)^2+(20-32)^2) = 15 = 9*1.618               3
# 34,50 to 14,85 sqrt((34-14)^2+(50-85)^2) = 40 = 25*1.618            5
# 132,158 to 77,247 sqrt((132-77)^2+(158-247)^2) = 104 = 64*1.618     8
# 8,525 to 133,280  sqrt((8-133)^2+(525-280)^2) = 275 = 169*1.618    13


package Math::PlanePath::WythoffPreliminaryTriangle;
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
  'bit_split_lowtohigh';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant y_minimum => 1;
use constant diffxy_maximum => -1;  # Y>=X+1 so X-Y <= -1

# Apparent minimum dx=F(i),dy=F(i+5)
# eg. N=57313   dx=377,dy=34    F(14),F(9)
#     N=392835  dx=987,dy=89    F(16),F(11)
#     N=2692537 dx=2584,dy=233  F(18),F(13)
# dy/dx -> 1/phi^5
use constant dir_minimum_dxdy => (((1+sqrt(5))/2)**5, 1);
use constant dir_maximum_dxdy => (1,-1);  # SE at N=5

use Math::PlanePath::WythoffArray;
my $wythoff = Math::PlanePath::WythoffArray->new;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'shift'} ||= 0;
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### WythoffPreliminaryTriangle n_to_xy(): $n

  if ($n < 1) { return; }
  if (is_infinite($n) || $n == 0) { return ($n,$n); }

  {
    # fractions on straight line ?
    my $int = int($n);
    if ($n != $int) {
      my $frac = $n - $int;  # inherit possible BigFloat/BigRat
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int;
  }

  # prev+y=x
  # prev = x-y
  $n -= 1;
  my $y = $wythoff->xy_to_n(0,$n);
  my $x = $wythoff->xy_to_n(1,$n);

  while ($y <= $x) {
    ### at: "y=$y x=$x"
    ($y,$x) = ($x-$y,$y);
  }
  ### reduction to: "y=$y x=$x"

  ### return: "y=$y x=$x"
  return ($x, $y);
}

sub xy_is_visited {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  return $x >= 0 && $x < $y;
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### WythoffPreliminaryTriangle xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  my $orig_x = $x;
  my $orig_y = $y;
  if (is_infinite($y)) { return $y; }

  unless ($x >= 0 && $x < $y) {
    return undef;
  }

  ($y,$x) = ($x,$x+$y);
  foreach (0 .. 500) {
    ($y,$x) = ($x,$x+$y);
    ### at: "seek y=$y x=$x"
    my ($c,$r) = $wythoff->n_to_xy($y) or next;
    my $wx = $wythoff->xy_to_n($c+1,$r);
    if (defined $wx && $wx == $x) {
      ### found: "pair $y $x at c=$c r=$r"
      my $n = $r+1;
      my ($nx,$ny) = $self->n_to_xy($n);
      ### nxy: "nx=$nx, ny=$ny"
      if ($nx == $orig_x && $ny == $orig_y) {
        return $n;
      } else {
        ### no match: "cf x=$x y=$y"
        return undef;
      }
    }
  }
  ### not found ...
  return undef;
}

sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### WythoffPreliminaryTriangle rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  if ($x2 < 0 || $y2 < 1) {
    ### all outside first quadrant ...
    return (1, 0);
  }

  return (1,
          $self->xy_to_n(0,2*abs($y2)));
}

1;
__END__

=for stopwords eg Ryde Math-PlanePath Moore Wythoff Zeckendorf concecutive fibbinary OEIS Kimberling precurses

=head1 NAME

Math::PlanePath::WythoffPreliminaryTriangle -- Wythoff row containing X,Y recurrence

=head1 SYNOPSIS

 use Math::PlanePath::WythoffPreliminaryTriangle;
 my $path = Math::PlanePath::WythoffPreliminaryTriangle->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Kimberling, Clark>This path is the Wythoff preliminary triangle by Clark
Kimberling,

=cut

# math-image  --path=WythoffPreliminaryTriangle --output=numbers --all --size=60x14

=pod

     13  | 105 118 131 144  60  65  70  75  80  85  90  95 100
     12  |  97 110  47  52  57  62  67  72  77  82  87  92    
     11  |  34  39  44  49  54  59  64  69  74  79  84        
     10  |  31  36  41  46  51  56  61  66  71  76            
      9  |  28  33  38  43  48  53  58  63  26                
      8  |  25  30  35  40  45  50  55  23                    
      7  |  22  27  32  37  42  18  20                        
      6  |  19  24  29  13  15  17                            
      5  |  16  21  10  12  14                                
      4  |   5   7   9  11                                    
      3  |   4   6   8                                        
      2  |   3   2                                            
      1  |   1                                                
    Y=0  |                                                    
         +-----------------------------------------------------
           X=0   1   2   3   4   5   6   7   8   9  10  11  12

A given N is at an X,Y position in the triangle according to where row
number N of the Wythoff array "precurses" back to.  Each Wythoff row is a
Fibonacci recurrence.  Starting from the pair of values in the first and
second columns of row N it can be run in reverse by

    F[i-1] = F[i+i] - F[i]

It can be shown that such a reverse always reaches a pair Y and X with
YE<gt>=1 and 0E<lt>=XE<lt>Y, hence making the triangular X,Y arrangement
above.

    N=7 WythoffArray row 7 is 17,28,45,73,...
    go backwards from 17,28 by subtraction
       11 = 28 - 17
        6 = 17 - 11
        5 = 11 - 6
        1 = 6 - 5
        4 = 5 - 1
    stop on reaching 4,1 which is Y=4,X=1 with Y>=1 and 0<=X<Y

Conversely a coordinate pair X,Y is reckoned as the start of a Fibonacci
style recurrence,

    F[i+i] = F[i] + F[i-1]   starting F[1]=Y, F[2]=X       

Iterating these values gives a row of the Wythoff array
(L<Math::PlanePath::WythoffArray>) after some initial iterations.  The N
value at X,Y is the row number of the Wythoff array which is reached.  Rows
are numbered starting from 1.  For example,

    Y=4,X=1 sequence:       4, 1, 5, 6, 11, 17, 28, 45, ...
    row 7 of WythoffArray:                  17, 28, 45, ...
    so N=7 at Y=4,X=1

=cut

# =head2 Phi Slope Blocks
# 
# The effect of each step backwards is to move to successive blocks of values
# with slope golden ratio phi=(sqrt(5)+1)/2.
# 
# Suppose no backwards steps were applied, so Y,X were the first two values of
# Wythoff row N.  In the example above that would be N=7 at Y=17,X=28.  The
# first two values of the Wythoff array are
# 
#     Y = W[0,r] = r-1 + floor(r*phi)       # r = row numbered from 1
#     X = W[1,r] = r-1 + 2*floor(r*phi)
# 
# So this would put N values on a line of slope Y/X = 1/phi = 0.618.  The
# portion of that line which falls within 0E<lt>=XE<lt>Y

=pod

=cut

# (r-1 + floor(r*phi)) / (r-1 + 2*floor(r*phi))
#   ~= (r-1+r*phi)/(r-1+2*r*phi)
#    = (r*(phi+1) - 1) / (r*(2phi+1) - 1)
#   -> r*(phi+1) / r*(2*phi+1)
#    = (phi+1) / (2*phi+1)
#    = 1/phi = 0.618

=pod

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for the behaviour common to all path
classes.

=over 4

=item C<$path = Math::PlanePath::WythoffPreliminaryTriangle-E<gt>new ()>

Create and return a new path object.

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A165360> (etc)

=back

    A165360     X
    A165359     Y
    A166309     N by rows
    A173027     N on Y axis

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::WythoffArray>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
