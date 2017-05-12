# Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


package Math::PlanePath::KochSquareflakes;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem = \&Math::PlanePath::_divrem;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'digit_split_lowtohigh';

# uncomment this to run the ### lines
#use Devel::Comments;


use constant n_frac_discontinuity => 0;

use constant parameter_info_array =>
  [ { name        => 'inward',
      display     => 'Inward',
      type        => 'boolean',
      default     => 0,
      description => 'Whether to direct the sides of the square inward, rather than outward.',
    } ];

use constant x_negative_at_n => 1;
use constant y_negative_at_n => 1;
use constant sumabsxy_minimum => 1;
use constant rsquared_minimum => 0.5; # minimum X=0.5,Y=0.5

# jump across rings is South-West, so
use constant dx_maximum => 1;
use constant dy_maximum => 1;
use constant dsumxy_maximum => 2; # diagonal NE
use constant ddiffxy_maximum => 2;
use constant ddiffxy_minimum => -2;
use constant dir_maximum_dxdy => (1,-1); # South-East

# N=1,2,3,4  gcd(1/2,1/2) = 1/2
use constant gcdxy_minimum => 1/2;

use constant turn_any_straight => 0; # never straight


#------------------------------------------------------------------------------

# level 0 inner square
# sidelen = 4^level
# ring points 4*4^level
# Nend = 4 * [ 1 + ... + 4^level ]
#      = 4 * (4^(level+1) - 1) / 3
#      = (4^(level+2) - 4) / 3
# Nstart = Nend(level-1) + 1
#        = (4^(level+1) - 4) / 3 + 1
#        = (4^(level+1) - 4 + 3) / 3
#        = (4^(level+1) - 1) / 3
#
# level    Nstart             Nend
#    0     (4-1)/3=1          (16-4)/3=12/3=4
#    1     (16-1)/3=15/3=5    (64-4)/3=60/3=20
#    2     (64-1)/3=63/3=21   (256-4)/3=252/3=84
#    3     (256-1)/3=255/3=85
#

sub n_to_xy {
  my ($self, $n) = @_;
  ### KochSquareflakes n_to_xy(): $n
  if ($n < 1) { return; }

  my $frac;
  {
    my $int = int($n);
    $frac = $n - $int;
    $n = $int;       # BigFloat int() gives BigInt, use that
  }

  # (4^(level+1) - 1) / 3 = N
  # 4^(level+1) - 1 = 3*N
  # 4^(level+1) = 3*N+1
  #
  my ($pow,$level) = round_down_pow (3*$n + 1, 4);
  ### $level
  ### $pow
  if (is_infinite($level)) { return ($level,$level); }

  # Nstart = (4^(level+1)-1)/3 with $power=4^(level+1) here
  #
  $n -= ($pow-1)/3;

  ### base: ($pow-1)/3
  ### next base would be: (4*$pow-1)/3
  ### n remainder from base: $n

  my $sidelen = $pow/4;
  (my $rot, $n) = _divrem ($n, $sidelen);  # high part is rot
  ### $sidelen
  ### n remainder: $n
  ### $rot

  ### assert: $n>=0
  ### assert: $n < 4 ** $level

  my @horiz = (1);
  my @diag = (1);
  my $i = 0;
  while (--$level > 0) {
    $horiz[$i+1] = 2*$horiz[$i] + 2*$diag[$i];
    $diag[$i+1]  = $horiz[$i] + 2*$diag[$i];
    ### horiz: $horiz[$i+1]
    ### diag: $diag[$i+1]
    $i++;
  }

  ### horiz: join(', ',@horiz)
  ### $i
  my $x
    = my $y
      = ($n * 0) + $horiz[$i]/-2;  # inherit bignum
  if ($rot & 1) {
    ($x,$y) = (-$y,$x);
  }
  if ($rot & 2) {
    $x = -$x;
    $y = -$y;
  }
  $rot *= 2;

  my $inward = $self->{'inward'};
  my @digits = digit_split_lowtohigh($n,4);

  while ($i > 0) {
    $i--;
    my $digit = $digits[$i] || 0;

    my ($dx, $dy, $drot);
    if ($digit == 0) {
      $dx = 0;
      $dy = 0;
      $drot = 0;
    } elsif ($digit == 1) {
      if ($rot & 1) {
        $dx = $diag[$i];
        $dy = $diag[$i];
      } else {
        $dx = $horiz[$i];
        $dy = 0;
      }
      $drot = ($inward ? 1 : -1);
    } elsif ($digit == 2) {
      if ($rot & 1) {
        if ($inward) {
          $dx = $diag[$i];
          $dy = $diag[$i] + $horiz[$i];
        } else {
          $dx = $diag[$i] + $horiz[$i];
          $dy = $diag[$i];
        }
      } else {
        $dx = $horiz[$i] + $diag[$i];
        $dy = $diag[$i];
        unless ($inward) { $dy = -$dy; }
      }
      $drot = ($inward ? -1 : 1);
    } elsif ($digit == 3) {
      if ($rot & 1) {
        $dx = $dy = $diag[$i] + $horiz[$i];
      } else {
        $dx = $horiz[$i] + 2*$diag[$i];
        $dy = 0;
      }
      $drot = 0;
    }
    ### delta: "$dx,$dy   rot=$rot   drot=$drot"

    if ($rot & 2) {
      ($dx,$dy) = (-$dy,$dx);
    }
    if ($rot & 4) {
      $dx = -$dx;
      $dy = -$dy;
    }
    ### delta with rot: "$dx,$dy"

    $x += $dx;
    $y += $dy;
    $rot += $drot;
  }

  {
    my $dx = $frac;
    my $dy = ($rot & 1 ? $frac : 0);
    if ($rot & 2) {
      ($dx,$dy) = (-$dy,$dx);
    }
    if ($rot & 4) {
      $dx = -$dx;
      $dy = -$dy;
    }
    $x = $dx + $x;
    $y = $dy + $y;
  }

  return ($x,$y);
}

my @inner_to_n = (1,2,4,3);

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### KochSquareflakes xy_to_n(): "$x, $y"

  # +/- 0.75
  if (4*$x < 3 && 4*$y < 3 && 4*$x >= -3 && 4*$y >= -3) {
    return $inner_to_n[($x >= 0) + 2*($y >= 0)];
  }

  $x = round_nearest($x);
  $y = round_nearest($y);

  # quarter curve segment and high digit
  my $n;
  {
    my $negx = -$x;
    if (($y > 0 ? $x > $y : $x >= $y)) {
      ### below leading diagonal ...
      if ($negx > $y) {
        ### bottom quarter ...
        $n = 1;
      } else {
        ### right quarter ...
        $n = 2;
        ($x,$y) = ($y, $negx);   # rotate -90
      }
    } else {
      ### above leading diagonal
      if ($y > $negx) {
        ### top quarter ...
        $n = 3;
        $x = $negx;   # rotate 180
        $y = -$y;
      } else {
        ### right quarter ...
        $n = 4;
        ($x,$y) = (-$y, $x);   # rotate +90
      }
    }
  }
  $y = -$y;
  ### rotate to: "$x,$y   n=$n"

  if (is_infinite($x)) {
    return $x;
  }
  if (is_infinite($y)) {
    return $y;
  }

  my @horiz;
  my @diag;
  my $horiz = 1;
  my $diag = 1;
  for (;;) {
    push @horiz, $horiz;
    push @diag, $diag;
    my $offset = $horiz+$diag;
    my $nextdiag = $offset + $diag;  # horiz + 2*diag
    ### $horiz
    ### $diag
    ### $offset
    ### $nextdiag

    if ($y <= $nextdiag) {
      ### found level at: "top=$nextdiag vs y=$y"
      $y -= $offset;
      $x += $offset;
      last;
    }
    $horiz = 2*$offset;  # 2*horiz+2*diag
    $diag = $nextdiag;
  }
  ### base subtract to: "$x,$y"


  if ($self->{'inward'}) {
    $y = -$y;
    ### inward invert to: "$x,$y"
  }

  ### origin based side: "$x,$y   horiz=$horiz diag=$diag  with levels ".scalar(@horiz)

  # loop 4*1, 4*4, 4*4^2 etc, extra +1 on the digits to include that in the sum
  #
  my $slope;
  while (@horiz) {
    ### at: "$x,$y slope=".($slope||0)." n=$n"
    $horiz = pop @horiz;
    $diag = pop @diag;
    $n *= 4;

    if ($slope) {
      if ($y < $diag) {
        ### slope digit 0 ...
        $n += 1;
      } else {
        $x -= $diag;
        $y -= $diag;
        ### slope not digit 0, move to: "$x,$y"

        if ($y < $horiz) {
          ### digit 1 ...
          $n += 2;
          ($x,$y) = ($y, -$x);   # rotate -90
          $slope = 0;
        } else {
          $y -= $horiz;
          ### slope not digit 1, move to: "$x,$y"

          if ($x < $horiz) {
            ### digit 2 ...
            $n += 3;
            $slope = 0;

          } else {
            ### digit 3 ...
            $n += 4;
            $x -= $horiz;
          }
        }
      }

    } else {
      if ($x < $horiz) {
        ### digit 0 ...
        $n += 1;
      } else {
        $x -= $horiz;
        ### not digit 0, move to: "$x,$y"

        if ($x < $diag) {
          ### digit 1 ...
          $n += 2;
          $slope = 1;
        } else {
          $x -= $diag;
          ### not digit 1, move to: "$x,$y"

          if ($x < $diag) {
            ### digit 2 ...
            $n += 3;
            $slope = 1;
            ($x,$y) = ($diag-$y, $x);   # offset and rotate +90

          } else {
            ### digit 3 ...
            $n += 4;
            $x -= $diag;
          }
        }
      }
    }
  }
  ### final: "$x,$y n=$n"

  if ($x == 0 && $y == 0) {
    return $n;
  } else {
    return undef;
  }
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### KochSquareflakes rect_to_n_range(): "$x1,$y1  $x2,$y2"

  foreach ($x1,$y1, $x2,$y2) {
    if (is_infinite($_)) {
      return (0, $_);
    }
    $_ = abs(round_nearest($_));
  }
  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); }
  my $max = ($x2 > $y2 ? $x2 : $y2);

  # Nend = 4 * [ 1 + ... + 4^level ]
  #      = 4 + 16 + ... + 4^(level+1)
  #
  my $horiz = 4;
  my $diag = 3;
  my $nhi = 4;
  for (;;) {
    $nhi += 1;
    $nhi *= 4;
    my $nextdiag = $horiz + 2*$diag;
    if (($self->{'inward'} ? $horiz : $nextdiag) >= 2*$max) {
      return (1, $nhi);
    }
    $horiz = $nextdiag + $horiz;   # 2*$horiz + 2*$diag;
    $diag = $nextdiag;
  }
}


#------------------------------------------------------------------------------
# Nstart = (4^(k+1) - 1)/3
# Nend = Nstart(k+1) - 1
#      = (4*4^(k+1) - 1)/3 - 1
#      = (4*4^(k+1) - 1 - 3)/3
#      = (4*4^(k+1) - 4)/3
#      = 4*(4^(k+1) - 1)/3
#      = 4*Nstart(k)

sub level_to_n_range {
  my ($self, $level) = @_;
  my $n_lo = (4**($level+1) - 1)/3;
  return ($n_lo, 4*$n_lo);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 1) { return undef; }
  if (is_infinite($n)) { return $n; }
  my ($pow,$exp) = round_down_pow (3*$n + 1, 4);
  return $exp-1;
}

#------------------------------------------------------------------------------
1;
__END__

    #                             15                     3
    #                            /  \
    #                     17--16      14--13             2
    #                      |               |
    #                     18              12             1
    #                   /       4 -- 3      \
    #                 19             |        11     <- Y=0
    #                   \       1 -- 2      /
    #                     20              10            -1
    #                                      |
    #                      5-- 6       8-- 9            -2
    #                            \   /
    #                              7                    -3
    #
    #                                                   -4
    #
    #                                                   -5
    #
    # ...                                               -6
    #
    # 21--22      24--25                      33--...   -7
    #       \   /       \                   /
    #         23          26              32            -8
    #                      |               |
    #                     27--28      30--31            -9
    #                           \   /
    #                             29                   -10




=for stopwords eg Ryde ie Math-PlanePath Koch Nstart Xstart,Ystart OEIS Xstart

=head1 NAME

Math::PlanePath::KochSquareflakes -- four-sided Koch snowflakes

=head1 SYNOPSIS

 use Math::PlanePath::KochSquareflakes;
 my $path = Math::PlanePath::KochSquareflakes->new (inward => 0);
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is the Koch curve shape arranged as four-sided concentric snowflakes.

=cut

# math-image --path=KochSquareflakes --all --output=numbers_dash --size=132x50

=pod

                                  61                                10
                                 /  \
                            63-62    60-59                           9
                             |           |
                   67       64          58       55                  8
                  /  \     /              \     /  \
             69-68    66-65                57-56    54-53            7
              |                                         |
             70                                        52            6
            /                                            \
          71                                              51         5
            \                                            /
             72                                        50            4
              |                                         |
             73                   15                   49            3
            /                    /  \                    \
       75-74                17-16    14-13                48-47      2
        |                    |           |                    |
       76                   18          12                   46      1
      /                    /     4---3    \                    \
    77                   19        . |     11                   45  Y=0
      \                    \     1---2    /                    /
       78                   20          10                   44     -1
        |                                |                    |
       79-80                 5--6     8--9                42-43     -2
            \                    \  /                    /
             81                    7                   41           -3
              |                                         |
             82                                        40           -4
            /                                            \
          83                                              39        -5
            \                                            /
             84                                        38           -6
                                                        |
             21-22    24-25                33-34    36-37           -7
                  \  /     \              /     \  /
                   23       26          32       35                 -8
                             |           |
                            27-28    30-31                          -9
                                 \  /
                                  29                               -10

                                   ^
       -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8  9 10

The innermost square N=1 to N=4 is the initial figure.  Its sides expand as
the Koch curve pattern in subsequent rings.  The initial figure is on
X=+/-0.5,Y=+/-0.5 fractions.  The points after that are integer X,Y.

=head1 Inward

The C<inward=E<gt>1> option can direct the sides inward.  The shape and
lengths etc are the same.  The angles and sizes mean there's no overlaps.

    69-68    66-65                57-56    54-53     7
     |   \  /     \              /     \  /    |
    70    67       64          58       55    52     6
      \             |           |            /
       71          63-62    60-59          51        5
      /                 \  /                 \
    72                   61                   50     4
     |                                         |
    73                                        49     3
      \                                      /
       74-75       17-16    14-13       47-48        2
           |        |   \  /    |        |
          76       18    15    12       46           1
            \        \  4--3  /        /
             77       19   |11       45          <- Y=0
            /        /  1--2  \        \
          78       20     7    10       44          -1
           |            /  \    |        |
       80-79        5--6     8--9       43-42       -2
      /                                      \
    81                                        41    -3
     |                                         |
    82                   29                   40    -4
      \                 /  \                 /
       83          27-28    30-31          39       -5
      /             |           |            \
    84    23       26          32       35    38    -6
         /  \     /              \     /  \    |
    21-22    24-25                33-34    36-37    -7

                          ^
    -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7

=head2 Level Ranges

Counting the innermost N=1 to N=4 square as level 0, a given level has

    looplen = 4*4^level

many points.  The start of a level is N=1 plus the preceding loop lengths so

    Nstart = 1 + 4*[ 1 + 4 + 4^2 + ... + 4^(level-1) ]
           = 1 + 4*(4^level - 1)/3
           = (4^(level+1) - 1)/3

and the end of a level similarly the total loop lengths, or simply one less
than the next Nstart,

    Nend = 4 * [ 1 + ... + 4^level ]
         = (4^(level+2) - 4) / 3

         = Nstart(level+1) - 1

For example,

    level  Nstart   Nend                       (A002450,A080674)
      0       1       4
      1       5      20
      2      21      84
      3      85     340                       

X<Lucas Sequence>The Xstart,Ystart position of the Nstart corner is a Lucas
sequence,

    Xstart(0) = -0.5
    Xstart(1) = -2
    Xstart(2) = 4*Xstart(1) - 2*Xstart(0) = -7
    Xstart(3) = 4*Xstart(2) - 2*Xstart(1) = -24
    ...
    Xstart(level+1) = 4*Xstart(level) - 2*Xstart(level-1)

    0.5, 2, 7, 24, 82, 280, 956, 3264, ...             (A003480)

This recurrence occurs because the replications are 4 wide when horizontal
but 3 wide when diagonal.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::KochSquareflakes-E<gt>new ()>

=item C<$path = Math::PlanePath::KochSquareflakes-E<gt>new (inward =E<gt> $bool)>

Create and return a new path object.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return per L</Level Ranges> above,

    (  (4**$level - 1)/3,
     4*(4**$level - 1)/3 )

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include

=over

L<http://oeis.org/A003480> (etc)

=back

    A003480    -X and -Y coordinate first point of each ring
               likewise A020727
    A007052    X,Y coordinate of axis crossing,
               and also maximum height of a side
    A072261    N on Y negative axis (half way along first side)
    A206374    N on South-East diagonal (end of first side)

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::KochSnowflakes>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
