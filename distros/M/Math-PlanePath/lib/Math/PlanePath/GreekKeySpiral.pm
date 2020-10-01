# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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


# math-image --path=GreekKeySpiral --lines --scale=25
# http://gwydir.demon.co.uk/jo/greekkey/corners.htm


package Math::PlanePath::GreekKeySpiral;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 128;
use Math::PlanePath;
use Math::PlanePath::Base::NSEW;
@ISA = ('Math::PlanePath::Base::NSEW',
        'Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest',
  'floor';
*_divrem = \&Math::PlanePath::_divrem;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;
*_sqrtint = \&Math::PlanePath::_sqrtint;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant xy_is_visited => 1;
use constant parameter_info_array =>
  [ { name      => 'turns',
      share_key => 'turns_2',
      display   => 'Turns',
      type      => 'integer',
      minimum   => 0,
      default   => 2,
      width     => 2,
    },
  ];

sub x_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 4*($self->{'turns'}+1)**2;
}
sub y_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 6*($self->{'turns'}+1)**2;
}

#   17--  18--19--20--21
#    |               
#   16   3t-2 -- 8 -- 2t
#    |     |          | 
#   15   4t-5 ---11   6 
#    |            |   | 
#   14--  13-----12   5 
#                     | 
#    1---- 2----- 3-- t 
#
sub _UNDOCUMENTED__dxdy_list_at_n {
  my ($self) = @_;
  my $turns = $self->{'turns'};
  return $self->n_start + ($turns == 0   ? 4   # turns=0
                           : $turns <= 2 ? 6   # turns=1,2
                           : 3*$turns - 4);
}

sub turn_any_right {
  my ($self) = @_;
  return ($self->{'turns'} != 0);  # SquareSpiral is left or straight only
}
sub _UNDOCUMENTED__turn_any_right_at_n {
  my ($self) = @_;
  # turns=1   2,4,7,11,22,29
  return ($self->{'turns'} == 0 ? undef # SquareSpiral left or straight only
          :  $self->n_start + $self->{'midpoint'}-1);
}
sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  my $turns = $self->{'turns'};
  # turns=1   2,4,7,11,22,29
  return $self->n_start + ($turns==0 ? 1
                           : $turns==1 ? 3
                           : $turns-1);
}


#------------------------------------------------------------------------------

# turns=1
#       2---3
#       |   |
#   0---1   4
#
# turns=2                   |
#       5---6---7          18  15--14
#       |       |           |   |   |
#       4---3   8          17--16  13         x=1,y=1
#           |   |                   |
#   0---1---2   9          10--11--12
#
# turns=3
#     10--11--12--13
#      |           |
#      9   6---5  14                             x=2,y=1
#      |   |   |   |
#      8---7   4  15
#              |   |
#  0---1---2---3  16
#
# turns=4
#     17--18--19--20--21  50  37--36--35--34
#      |               |   |   |           |    3,3,2,1,1,1,2,3,4,down4
#     16   9---8---7  22  49  38  41--42  33
#      |   |       |   |   |   |   |   |   |
#     15  10--11   6  23  48  39--40  43  32      x=3,y=2
#      |       |   |   |   |           |   |
#     14--13--12   5  24  47--46--45--44  31
#                  |   |                   |
#  0---1---2---3---4  25--26--27--28--29--30    5,4,3,2,1,1,1,2,3,up3
#
# turns=5
#      26--27--28--29--30--31
#       |                   |       4,4,3,2,1,1,1,2,3,4,5,5
#      25  12--11--10---9  32
#       |   |           |   |
#      24  13  16--17   8  33       5,4,3,2,1,1,1,2,3,4,5,rem
#   |   |   |   |   |   |   |
#  35  23  14--15  18   7  34
#   |   |           |   |   |                     x=3,y=3
#  36  22--21--20--19   6  35
#                       |   |
#   0---1---2---3---4---5  36-
#
# turns=6
#      37--38--39--40--41--42--43
#       |                       |
#      36  15--14--13--12--11  44                x=3,y=3
#       |   |               |   |
#      35  16  23--24--25  10  45
#       |   |   |       |   |   |
#      34  17  22--21  26   9  46   6,5,4,3,2,1,1,1,2,3,4,5,rem
#       |   |       |   |   |   |
#      33  18--19--20  27   8  47
#       |               |   |   |
#      32--31--30--29--28   7  48
#                           |   |
#   0---1---2---3---4---5---6  49-
#
# turns=7
#      50--51--52--53--54--55--56--57
#       |                           |
#      49  18--17--16--15--14--13  58
#       |   |                   |   |
#      48  19  32--33--34--35  12  59               x=4,y=3
#       |   |   |           |   |   |
#      47  20  31  28--27  36  11  60
#       |   |   |   |   |   |   |   |
#      46  21  30--29  26  37  10  61  6,5,4,3,2,1,1,1,2,3,4,5,rem
#       |   |           |   |   |   |
#      45  22--23--24--25  38   9  62
#       |                   |   |   |
#      44--43--42--41--40--39   8  63
#                               |   |
#   0---1---2---3---4---5---6---7  64
#
# turns=8   x=5,y=4


# centre
# 2   1 1
# 3   2 1

# 4   3 2
# 5   3 3
# 6   3 3
# 7   4 3

# 8   5 4
# 9   5 5
# 10  5 5
# 11  6 5

# 12  7 6
# 13  7 7
# 14  7 7
# 15  8 7
#
# turns 2, 3,  4,  5
# midp  4  6, 10, 15, 21   N = (1/2 d^2 + 1/2 d)
#
# 63, 189, 387, 657
# 9*7 9*21, 9*43, 9*73
#
# 82     226     442
# 9*9+1  9*25+1  9*49+1

sub new {
  my $self = shift->SUPER::new (@_);

  my $turns = $self->{'turns'};
  if (! defined $turns) {
    $turns = 2;
  } elsif ($turns < 0) {
  }
  $self->{'turns'} = $turns;
  my $t1 = $turns + 1;

  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }

  $self->{'centre_x'} = int($t1/2) + (($turns%4)==0);
  $self->{'centre_y'} = int($turns/2) + (($turns%4)==1);

  $self->{'midpoint'} = $turns*$t1/2 + 1;
  $self->{'side'} = $t1;
  $self->{'squared'} = $t1*$t1;

  ### turns   : $self->{'turns'}
  ### midpoint: $self->{'midpoint'}
  ### side    : $self->{'side'}
  ### squared : $self->{'squared'}

  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  #### GreekKeySpiral n_to_xy: $n

  $n = $n - $self->{'n_start'};
  ### n zero based: $n
  if ($n < 0) { return; }

  my $turns = $self->{'turns'};
  my $squared = $self->{'squared'};
  my $side = $turns + 1;

  ### sqrt of: ($n-1) / $squared

  my $d = _sqrtint($n / $squared);
  $n -= $squared*$d*$d - 1;
  my $dhalf = int($d/2);

  ### $d
  ### $dhalf
  ### n remainder: $n

  my ($x,$y);
  my $square_rot = 0;
  my $frac;
  { my $int = int($n);
    $frac = $n - int($n);
    $n = $int;
  }
  ### $frac
  ### $n

  if ($d % 2) {
    ### odd d, right and top ...
    if ($n >= $squared*($d+1)) {
      ### top ...
      $n -= $squared*2*$d;
      (my $q, $n) = _divrem ($n, $squared);
      $x = (-$dhalf-$q)*$side + 1;
      $y = ($dhalf+1)*$side;
      $square_rot = 2;
    } else {
      ### right ...
      (my $q, $n) = _divrem ($n-$turns-1 + $squared, $squared);
      $x = ($dhalf+1)*$side;
      $y = ($q-$dhalf-1)*$side;
      $square_rot = 1;
    }
  } else {
    ### even d, left and bottom ...
    if ($d == 0 || $n >= $squared*($d+1)) {
      ### bottom ...
      $n -= $squared*2*$d;
      (my $q, $n) = _divrem ($n, $squared);
      $x = ($dhalf+$q)*$side-1;
      $y = -($dhalf)*$side;
      $square_rot = 0;
    } else {
      ### left ...
      (my $q, $n) = _divrem ($n-$turns-1 + $squared, $squared);
      $x = -($dhalf)*$side;
      $y = -($q-$dhalf-1)*$side;
      $square_rot = 3;
    }
  }

  ### assert: ! ($n < 0)
  ### assert: ! ($n >= $squared)

  my $rot = $turns;
  my $kx = 0;
  my $ky = 0;
  my $before;
  ### n-midpoint: $n - $self->{'midpoint'}

  if (($n -= $self->{'midpoint'}) >= 0) {
    ### after middle ...
  } elsif ($n += 1) {
    ### before middle ...
    $n = -$n;
    if ($frac) {
      ### fraction ...
      $frac = 1-$frac;
      $n -= 1;
    } else {
      ### integer ...
      $n -= 0;
    }
    $rot += 2;
    $before = 1;
  } else {
    ### centre segment ...
    $rot += 1;
    $before = 1;
  }
  ### key n: $n

  # d: [ 0, 1,  2 ]
  # n: [ 0, 3, 10 ]
  # d = -1/4 + sqrt(1/2 * $n + 1/16)
  #   = (-1 + sqrt(8*$n + 1)) / 4
  # N = (2*$d + 1)*$d
  # rel = (2*$d + 1)*$d + 2*$d+1
  #     = (2*$d + 3)*$d + 1
  #
  $d = int( (_sqrtint(8*$n+1) - 1)/4 );
  $n -= (2*$d+3)*$d + 1;
  ### $d
  ### key signed rem: $n

  if ($n < 0) {
    ### key vertical ...
    $kx += $d;
    $ky = -$frac-$n-$d - 1 + $ky;
    if ($d % 2) {
      ### key right ...
      $rot += 2;
      $kx += 1;
    } else {
    }
  } else {
    ### key horizontal ...
    $kx = $frac+$n-$d + $kx;
    $ky += $d + 1;
    $rot += 2;
    if ($d % 2) {
      ### key bottom ...
      $rot += 2;
      $kx += -1;
    } else {
    }
  }
  ### kxy raw: "$kx, $ky"

  if ($rot & 2) {
    $kx = -$kx;
    $ky = -$ky;
  }
  if ($rot & 1) {
    ($kx,$ky) = (-$ky,$kx);
  }
  ### kxy rotated: "$kx,$ky"

  if ($before) {
    if (($turns % 4) == 0) {
      $kx -= 1;
    }
    if (($turns % 4) == 1) {
      $ky -= 1;
    }
    if (($turns % 4) == 2) {
      $kx += 1;
    }
    if (($turns % 4) == 3) {
      $ky += 1;
    }
  }

  $kx += $self->{'centre_x'};
  $ky += $self->{'centre_y'};

  if ($square_rot & 2) {
    $kx = $turns-$kx;
    $ky = $turns-$ky;
  }
  if ($square_rot & 1) {
    ($kx,$ky) = ($turns-$ky,$kx);
  }

  # kx,ky first to inherit BigRat etc from $frac
  return ($kx + $x,
          $ky + $y);
}


# t+(t-1)+(t-2)+(t-3) = 4t-6

# y=0  0
# y=2  0+1+2+3  total 6
# y=4  4+5+6+7  total 28
#      (2 d^2 - d)
# N=4*t*y/2 - (2y-1)*y
#  =(2t - 2y + 1)*y

# x=1  0+1+2    total 3
# x=3  3+4+5+6  total 21
# x=5  7+8+9+10 total 55
#      (2 d^2 + d)
# N = 4*t*(x-1)/2 + 3t-3 - (2x+1)*x
#   = 2*t*(x-1) + 3t-3 - (2x+1)*x
#   = 2tx-2t + 3t-3 - (2x+1)*x
#   = (2t-2x-1)x - 2t + 3t-3
#   = (2t-2x-1)x + t-3

# y=0  squared-t-t                total 0
# y=2  - (t-1)-(t-2)-(t-3)-(t-4)  total 10
# y=4  - 5+6+7+8                  total 36
#      (2 d^2 + d)
# N = squared - 4*t*y/2 - 2t - (2y+1)*y +(x-y)
#   = squared - (2t+2y+1)*y - 2t + x

sub xy_to_n {
  my ($self, $x, $y) = @_;

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### xy_to_n: "x=$x, y=$y"

  my $turns = $self->{'turns'};
  my $side = $turns + 1;
  my $squared = $self->{'squared'};

  my $xs = floor($x/$side);
  my $ys = floor($y/$side);
  $x %= $side;
  $y %= $side;
  my $n;
  if ($xs > -$ys) {
    ### top or right
    if ($xs >= $ys) {
      ### right going upwards
      $n = $squared*((4*$xs - 3)*$xs + $ys);
      ($x,$y) = ($y,$turns-$x);  # rotate -90
      if ($x == 0) {
        $x = $turns;
        $n -= $side*$turns;   # +$side modulo
      } else {
        $x -= 1;
        $n += $side;
      }
    } else {
      ### top going leftwards
      $n = $squared*((4*$ys - 1)*$ys - $xs);
      $x = $turns-$x;  # rotate 180
      $y = $turns-$y;
    }
  } else {
    ### bottom or left
    if ($xs > $ys || ($xs == 0 && $ys == 0)) {
      ### bottom going rightwards: "$xs,$ys"
      $n = $squared*((4*$ys - 3)*$ys + $xs);
    } else {
      ### left going downwards
      $n = $squared*((4*$xs - 1)*$xs - $ys);
      ($x,$y) = ($turns-$y,$x);  # rotate +90
      if ($x == 0) {
        $x = $turns;
        $n -= $side*$turns;   # +$side modulo
      } else {
        $x -= 1;
        $n += $side;
      }
    }
  }

  if ($x + $y >= $turns) {
    ### key top or right ...
    if ($x > $y) {
      ### key right ...
      $x = $turns-$x;
      if ($x % 2) {
        ### forward ...
        $n += (2*$turns-2*$x+2)*$x + $y - $turns;
      } else {
        ### backward ...
        $n += $squared - (2*$turns-2*$x+2)*$x - $y;
      }
    } else {
      ### key top ...
      $y = $turns-$y;
      if ($y % 2) {
        ### backward ...
        $n += (2*$turns-2*$y)*$y + $turns-$x;
      } else {
        ### forward ...
        $n += $squared - (2*$turns - 2*$y)*$y - 2*$turns + $x;
      }
    }
  } else {
    ### key bottom or left ...
    if ($x >= $y) {
      ### key bottom ...
      if ($y % 2) {
        ### backward ...
        $n += $squared - (2*$turns - 2*$y)*$y - $turns - $x - 1;
      } else {
        ### forward ...
        $n += (2*$turns-2*$y)*$y + $x + 1;
      }
    } else {
      ### key left ...
      if ($x % 2) {
        ### forward ...
        $n += (2*$turns-2*$x-2)*$x + 2*$turns - $y;
      } else {
        ### backward ...
        $n += $squared - (2*$turns - 2*$x - 2)*$x - 3*$turns + $y;
      }
    }
  }

  return $n + $self->{'n_start'}-1;
}

use Math::PlanePath::SquareArms;
*_rect_square_range = \&Math::PlanePath::SquareArms::_rect_square_range;

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  # floor divisions to square blocks
  {
    my $side = $self->{'turns'} + 1;
    _divrem_mutate($x1,$side);
    _divrem_mutate($y1,$side);
    _divrem_mutate($x2,$side);
    _divrem_mutate($y2,$side);
  }
  my ($dlo, $dhi) = _rect_square_range ($x1, $y1,
                                        $x2, $y2);
  my $squared = $self->{'squared'};

  ### d range sides: "$dlo, $dhi"
  ### right start: ((4*$squared*$dlo - 4*$squared)*$dlo + 10)

  return (($dlo == 0 ? 0  # special case Nlo=1 for innermost square
          # Nlo at right vertical start
          : ((4*$squared*$dlo - 4*$squared)*$dlo + $squared))
          + $self->{'n_start'},

          # Nhi at bottom horizontal end
          (4*$squared*$dhi + 4*$squared)*$dhi
          + $squared
          + $self->{'n_start'}-1);
}

1;
__END__

=for stopwords Ryde Math-PlanePath Edkins

=head1 NAME

Math::PlanePath::GreekKeySpiral -- square spiral with Greek key motif

=head1 SYNOPSIS

 use Math::PlanePath::GreekKeySpiral;
 my $path = Math::PlanePath::GreekKeySpiral->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path makes a spiral with a Greek key scroll motif,

    39--38--37--36  29--28--27  24--23                      5
     |           |   |       |   |   |
    40  43--44  35  30--31  26--25  22                      4
     |   |   |   |       |           |
    41--42  45  34--33--32  19--20--21  ...                 3
             |               |           |
    48--47--46   5---6---7  18  15--14  99  96--95          2
     |           |       |   |   |   |   |   |   |
    49  52--53   4---3   8  17--16  13  98--97  94          1
     |   |   |       |   |           |           |
    50--51  54   1---2   9--10--11--12  91--92--93     <- Y=0
             |                           |
    57--56--55  68--69--70  77--78--79  90  87--86         -1
     |           |       |   |       |   |   |   |
    58  61--62  67--66  71  76--75  80  89--88  85         -2
     |   |   |       |   |       |   |           |
    59--60  63--64--65  72--73--74  81--82--83--84         -3

                 ^

    -3  -2  -1  X=0  1   2   3   4   5   6   7   8 ...

The repeating figure is a 3x3 pattern

       |
       *   *---*
       |   |   |      right vertical
       *---*   *      going upwards
               |
       *---*---*
       |

The turn excursion is to the outside of the 3-wide channel and forward in
the direction of the spiral.  The overall spiralling is the same as the
C<SquareSpiral>, but composed of 3x3 sub-parts.

=head2 Sub-Part Joining

The verticals have the "entry" to each figure on the inside edge, as for
example N=90 to N=91 above.  The horizontals instead have it on the outside
edge, such as N=63 to N=64 along the bottom.  The innermost N=1 to N=9 is a
bottom horizontal going right.

      *---*---*
      |       |        bottom horizontal
      *---*   *        going rightwards
          |   |
    --*---*   *-->

On the horizontals the excursion part is still "forward on the outside", as
for example N=73 through N=76, but the shape is offset.  The way the entry
is alternately on the inside and outside for the vertical and horizontal is
necessary to make the corners join.

=head2 Turn

An optional C<turns =E<gt> $integer> parameter controls the turns within the
repeating figure.  The default is C<turns=E<gt>2>.  Or for example
C<turns=E<gt>4> begins

=cut

# math-image --path=GreekKeySpiral,turns=4 --all --output=numbers_dash --size=78

=pod

    turns => 4

    105-104-103-102-101-100  79--78--77--76--75  62--61--60--59
      |                   |   |               |   |           |
    106 119-120-121-122  99  80  87--88--89  74  63  66--67  58
      |   |           |   |   |   |       |   |   |   |   |   |
    107 118 115-114 123  98  81  86--85  90  73  64--65  68  57
      |   |   |   |   |   |   |       |   |   |           |   |
    108 117-116 113 124  97  82--83--84  91  72--71--70--69  56
      |           |   |   |               |                   |
    109-110-111-112 125  96--95--94--93--92  51--52--53--54--55
                      |                       |
    130-129-128-127-126  17--18--19--20--21  50  37--36--35--34
      |                   |               |   |   |           |
    131 144-145-146-147  16   9-- 8-- 7  22  49  38  41--42  33
      |   |           |   |   |       |   |   |   |   |   |   |
    132 143 140-139 148  15  10--11   6  23  48  39--40  43  32
      |   |   |   |   |   |       |   |   |   |           |   |
    133 142-141 138 149  14--13--12   5  24  47--46--45--44  31
      |           |   |               |   |                   |
    134-135-136-137 150   1-- 2-- 3-- 4  25--26--27--28--29--30
                      |
             ..-152-151

The count of turns is chosen to make C<turns=E<gt>0> a straight line, the
same as the C<SquareSpiral>.  C<turns=E<gt>1> is a single wiggle,

=cut

# math-image --path=GreekKeySpiral,turns=1 --all --output=numbers_dash --size=78

=pod

    turns => 1

    66--65--64  61--60  57--56  53--52--51
     |       |   |   |   |   |   |       |
    67--68  63--62  59--58  55--54  49--50
         |                           |    
    70--69  18--17--16  13--12--11  48--47
     |       |       |   |       |       |
    71--72  19--20  15--14   9--10  45--46
         |       |           |       |    
       ...  22--21   2-- 3   8-- 7  44--43
             |       |   |       |       |
            23--24   1   4-- 5-- 6  41--42
                 |                   |    
            26--25  30--31  34--35  40--39
             |       |   |   |   |       |
            27--28--29  32--33  36--37--38

In general the repeating figure is a square of turns+1 points on each side,
spiralling in and then out again.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::GreekKeySpiral-E<gt>new ()>

=item C<$path = Math::PlanePath::GreekKeySpiral-E<gt>new (turns =E<gt> $integer)>

Create and return a new Greek key spiral object.  The default C<turns> is 2.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

For C<$n E<lt> 1> the return is an empty list, it being considered the path
starts at 1.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are
each rounded to the nearest integer, which has the effect of treating each N
in the path as centred in a square of side 1, so the entire plane is
covered.

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::SquareSpiral>

Jo Edkins Greek Key pages C<http://gwydir.demon.co.uk/jo/greekkey/index.htm>

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
