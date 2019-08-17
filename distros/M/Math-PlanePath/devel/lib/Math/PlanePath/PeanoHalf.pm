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


# math-image --path=PeanoHalf,arms=2 --all --output=numbers_dash

# http://www.nahee.com/spanky/www/fractint/lsys/variations.html
# http://www.nahee.com/spanky/www/fractint/lsys/moore.gif
# William McWorter mcworter@midohio.net

package Math::PlanePath::PeanoHalf;
use 5.004;
use strict;
use List::Util 'min'; # 'max'
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 127;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::PeanoCurve;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;

use constant parameter_info_array =>
  [ { name      => 'radix',
      share_key => 'radix_3',
      display   => 'Radix',
      type      => 'integer',
      minimum   => 2,
      default   => 3,
      width     => 3,
    },
    { name      => 'arms',
      share_key => 'arms_2',
      display   => 'Arms',
      type      => 'integer',
      minimum   => 1,
      maximum   => 2,
      default   => 1,
      width     => 1,
      description => 'Arms',
    } ];

sub new {
  my $self = shift->SUPER::new(@_);

  if (! $self->{'radix'} || $self->{'radix'} < 2) {
    $self->{'radix'} = 3;
  }
  $self->{'arms'} = max(1, min(2, $self->{'arms'} || 1));

  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### PeanoHalf n_to_xy(): $n

  if ($n < 0) { return; }

  my $arms = $self->{'arms'};
  my $x_reverse;
  if ($arms > 1) {
    my $int = int($n);
    my $x_reverse = _divrem_mutate($int,2);
    $int = -$int;
  } else {
    $x_reverse = 0;
  }

  my $radix = $self->{'radix'};
  my ($len, $level) = round_down_pow (2*$n*$radix, $radix);

  ### $len
  ### peano at: $n + ($len*$len-1)/2

  my ($x,$y) = $self->Math::PlanePath::PeanoCurve::n_to_xy($n + ($len*$len-1)/2);
  my $half = ($len-1)/2;

  my $y_reverse;
  if ($radix % 2) {
    $x_reverse ^= ($level & 1);
    $y_reverse = $x_reverse ^ 1;
  } else {
    $y_reverse = $x_reverse;
  }

  if ($x_reverse) {
    $x = $half - $x;
  } else {
    $x -= $half;
  }
  if ($y_reverse) {
    $y = $half - $y;
  } else {
    $y -= $half;
  }
  return ($x, $y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### PeanoHalf xy_to_n(): "$x, $y"

  return undef;
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### PeanoHalf rect_to_n_range(): "$x1,$y1, $x2,$y2"

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);

  my $radix = $self->{'radix'};
  my $zero = ($x1 * 0 * $y1 * $x2 * $y2);  # inherit bignum

  my ($len, $level) = round_down_pow ($zero + max(abs($x1),abs($y1),
                                                  abs($x2),abs($y2))*2-1,
                                      $radix);
  ### $len
  ### $level

  $len *= $radix;
  return (0,
          ($len*$len - 1) * $self->{'arms'} / 2);
}

1;
__END__

=for stopwords eg Ryde ie PeanoHalf Math-PlanePath Moore

=head1 NAME

Math::PlanePath::PeanoHalf -- 9-segment self-similar spiral

=head1 SYNOPSIS

 use Math::PlanePath::PeanoHalf;
 my $path = Math::PlanePath::PeanoHalf->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is an integer version of a 9-segment self-similar curve by ...

=cut

# math-image --path=PeanoHalf --expression='i<=44?i:0' --output=numbers_dash

=pod

     7-- 6-- 5-- 4-- 3-- 2                                 1 
     |                   |                                   
     8-- 9--10       0-- 1                            <- Y=0 
             |                                               
    13--12--11                                            -1 
     |                                                       
    14--15--16  29--30--31--32--33--34                    -2 
             |   |                   |                       
    19--18--17  28--27--26  37--36--35     ...--44        -3 
     |                   |   |                   |           
    20--21--22--23--24--25  38--39--40--41--42--43        -4 

                     ^
    -4  -3  -2  -1  X=0  1   2   3   4   5   6   7 

    ******************************************************
    ******************************************************
    ******************************************************
    ******************************************************
    ******************************************************
    ******************************************************
    ******************************************************
    ******************************************************
    ******************************************************
    ***************************                  *********
    ***************************                  *********
    ***************************                  *********
    ***************************         ******   *********
    ***************************         *** **   *********
    ***************************         ***      *********
    ***************************         ******************
    ***************************         ******************
    ***************************         ******************
    ***************************
    ***************************
    ***************************
    ***************************
    ***************************
    ***************************
    ***************************
    ***************************
    ***************************

=head2 Arms

The optional C<arms =E<gt> 2> parameter can give a second copy of the spiral
rotated 180 degrees.  With two arms all points of the plane are covered.

     93--91  81--79--77--75  57--55  45--43--41--39 122-124  ..
      |   |   |           |   |   |   |           |   |   |   |
     95  89  83  69--71--73  59  53  47  33--35--37 120 126 132 
      |   |   |   |           |   |   |   |           |   |   | 
     97  87--85  67--65--63--61  51--49  31--29--27 118 128-130 
      |                                           |   |
     99-101-103  22--20  10-- 8-- 6-- 4  13--15  25 116-114-112 
              |   |   |   |           |   |   |   |           | 
    109-107-105  24  18  12   1   0-- 2  11  17  23 106-108-110 
      |           |   |   |   |           |   |   |   |         
    111-113-115  26  16--14   3-- 5-- 7-- 9  19--21 104-102-100 
              |   |                                           | 
    129-127 117  28--30--32  50--52  62--64--66--68  86--88  98 
      |   |   |           |   |   |   |           |   |   |   |
    131 125 119  38--36--34  48  54  60  74--72--70  84  90  96 
      |   |   |   |           |   |   |   |           |   |   | 
     .. 123-121  40--42--44--46  56--58  76--78--80--82  92--94 

The first arm is the even numbers N=0,2,4,etc and the second arm is the odd
numbers N=1,3,5,etc.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for the behaviour common to all path
classes.

=over 4

=item C<$path = Math::PlanePath::PeanoHalf-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=back

=head1 FORMULAS

=head2 X,Y to N

The correspondence to Wunderlich's 3x3 serpentine curve can be used to turn
X,Y coordinates in base 3 into an N.  Reckoning the innermost 3x3 as level=1
then the smallest abs(X) or abs(Y) in a level is

    Xlevelmin = (3^level + 1) / 2
    eg. level=2 Xlevelmin=5

which can be reversed as

    level = log3floor( max(abs(X),abs(Y)) * 2 - 1 )
    eg. X=7 level=log3floor(2*7-1)=2

An offset can be applied to put X,Y in the range 0 to 3^level-1,

    offset = (3^level-1)/2
    eg. level=2 offset=4

Then a table can give the N base-9 digit corresponding to X,Y digits

    Y=2   4   3   2      N digit
    Y=1  -1   0   1
    Y=0  -2  -3  -4
         X=0 X=1 X=2

A current rotation maintains the "S" part directions and is updated by a
table

    Y=2   0  +3   0     rotation when descending
    Y=1  +1  +2  +1     into sub-part
    Y=0   0  +3   0
         X=0 X=1 X=2

The negative digits of N represent backing up a little in some higher part.
If N goes negative at any state then X,Y was off the main curve and instead
on the second arm.  If the second arm is not of interest the calculation can
stop at that stage.

It no doubt would also work to take take X,Y as balanced ternary digits
1,0,-1, but it's not clear that would be any faster or easier to calculate.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::PeanoCurve>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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
