# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
# 4*3^n
# QuintetCentres unit squares boundary  a(n) = 4*3^(n-3)
# 12,36,108,324,972
# match 12,36,108,324,972
# A003946 G.f.: (1+x)/(1-3*x).
# A025579 a(1)=1, a(2)=2, a(n) = 4*3^(n-3) for n >= 3.
# A027327 a(n) = Sum{(k+1)*T(n,m-k)}, 0<=k<=m, where m=0 for n=0,1; m=n for n >= 2; T given by A026120.


package Math::PlanePath::QuintetCentres;
use 5.004;
use strict;
use POSIX 'ceil';
#use List::Util 'min','max';
*min = \&Math::PlanePath::_min;
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 128;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::SacksSpiral;
*_rect_to_radius_range = \&Math::PlanePath::SacksSpiral::_rect_to_radius_range;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'round_up_pow';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;
use constant parameter_info_array => [ { name      => 'arms',
                                         share_key => 'arms_4',
                                         display   => 'Arms',
                                         type      => 'integer',
                                         minimum   => 1,
                                         maximum   => 4,
                                         default   => 1,
                                         width     => 1,
                                         description => 'Arms',
                                       } ];

{
  my @x_negative_at_n = (undef, 112, 9, 2, 2);
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n[$self->{'arms'}];
  }
}
{
  my @y_negative_at_n = (undef, 2, 4, 6, 7);
  sub y_negative_at_n {
    my ($self) = @_;
    return $y_negative_at_n[$self->{'arms'}];
  }
}

use constant dx_minimum => -1;
use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dy_maximum => 1;

*_UNDOCUMENTED__dxdy_list = \&Math::PlanePath::_UNDOCUMENTED__dxdy_list_eight;
{
  my @_UNDOCUMENTED__dxdy_list_at_n = (undef, 18, 14, 11, 11);
  sub _UNDOCUMENTED__dxdy_list_at_n {
    my ($self) = @_;
    return $_UNDOCUMENTED__dxdy_list_at_n[$self->{'arms'}];
  }
}

use constant dsumxy_minimum => -2;  # diagonals
use constant dsumxy_maximum => 2;
use constant ddiffxy_minimum => -2;
use constant ddiffxy_maximum => 2;
use constant dir_maximum_dxdy => (1,-1);  # South-East

# N=9 first straight, then for other arms 18,27,36
sub _UNDOCUMENTED__turn_any_straight_at_n {
  my ($self) = @_;
  return 9*$self->arms_count;
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'arms'} = max(1, min(4, $self->{'arms'} || 1));
  return $self;
}

my @rot_to_x = (0,0,-1,-1);
my @rot_to_y = (0,1,1,0);
my @dir4_to_dx = (1,0,-1,0);
my @dir4_to_dy = (0,1,0,-1);
my @digit_reverse = (0,1,0,0,1);

sub n_to_xy {
  my ($self, $n) = @_;
  ### QuintetCentres n_to_xy(): "arms=$self->{'arms'}   $n"

  if ($n < 0) {
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

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
  my $zero = ($n * 0);   # inherit BigInt 0

  # arm as initial rotation
  my $rot = _divrem_mutate ($n, $self->{'arms'});

  my @digits = digit_split_lowtohigh($n,5);
  my @sx;
  my @sy;
  {
    my $sx = $zero + $dir4_to_dx[$rot];
    my $sy = $zero + $dir4_to_dy[$rot];
    foreach (@digits) {
      push @sx, $sx;
      push @sy, $sy;

      # 2*(sx,sy) + rot+90(sx,sy)
      ($sx,$sy) = (2*$sx - $sy,
                   2*$sy + $sx);
    }
    ### @digits
    my $rev = 0;
    for (my $i = $#digits; $i >= 0; $i--) {  # high to low
      ### digit: $digits[$i]
      if ($rev) {
        ### reverse: "$digits[$i] to ".(5 - $digits[$i])
        $digits[$i] = 4 - $digits[$i];
      }
      $rev ^= $digit_reverse[$digits[$i]];
      ### now rev: $rev
    }
  }
  ### reversed n: @digits


  my $x =
    my $y =
      my $ox =
        my $oy = $zero;

  while (defined (my $digit = shift @digits)) {  # low to high
    my $sx = shift @sx;
    my $sy = shift @sy;
    ### at: "$x,$y  digit $digit   side $sx,$sy"

    # if ($rot & 2) {
    #   ($sx,$sy) = (-$sx,-$sy);
    # }
    # if ($rot & 1) {
    #   ($sx,$sy) = (-$sy,$sx);
    # }

    if ($digit == 0) {
      $x -= $sx;   # left at 180
      $y -= $sy;

    } elsif ($digit == 1) {
      # centre
      ($x,$y) = (-$y,$x);      # rotate -90
      ### rotate to: "$x,$y"
      # $rot--;

    } elsif ($digit == 2) {
      $x += $sy;   # down at -90
      $y -= $sx;
      ### offset to: "$x,$y"

    } elsif ($digit == 3) {
      ($x,$y) = (-$y,$x);      # rotate -90
      $x += $sx;   # right at 0
      $y += $sy;
      # $rot++;

    } else {  # $digit == 4
      ($x,$y) = ($y,-$x);      # rotate +90
      $x -= $sy;   # up at +90
      $y += $sx;
      # $rot++;
    }

    $ox += $sx;
    $oy += $sy;
  }

  ### final: "$x,$y  origin $ox,$oy"
  return ($x + $ox + $rot_to_x[$rot],
          $y + $oy + $rot_to_y[$rot]);
}


# modulus 2*X+Y
#              3
#          0   2   4
#              1
#
#   0 is X=0,Y=0
#
my @modulus_to_x = (0,1,1,1,2);
my @modulus_to_y = (0,-1,0,1,0);

my @modulus_to_digit
  = (0,2,1,4,3,    0,0,10,30,20,     #  0  base
     0,4,3,1,2,    0,10,50,40,10,    # 10
     4,0,1,3,2,    60,20,40,50,20,   # 20  rotated +90
     2,1,3,4,0,    30,60,0,30,50,    # 30
     1,0,3,2,4,    30,20,70,40,40,   # 40
     3,4,1,2,0,    70,10,30,50,50,   # 50  rotated +180
     4,2,3,0,1,    60,60,20,70,10,   # 60
     2,3,1,0,4,    70,0,60,70,40,    # 70  rotated +270
    );
sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### QuintetCentres xy_to_n(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);

  foreach my $overflow (2*$x + 2*$y, 2*$x - 2*$y) {
    if (is_infinite($overflow)) { return $overflow; }
  }

  # my $level_limit = log($x*$x + $y*$y + 1) * 1 * 2;
  # if (is_infinite($level_limit)) { return $level_limit; }

  my @digits;
  my $arm;
  my $state;
  for (;;) {
    # if ($level_limit-- < 0) {
    #   ### oops, level limit ...
    #   return undef;
    # }
    if ($x == 0) {
      if ($y == 0) {
        ### found first arm 0,0 ...
        $arm = 0;
        $state = 0;
        last;
      }
      if ($y == 1) {
        ### found second arm 0,1 ...
        $arm = 1;
        $state = 20;
        last;
      }
    } elsif ($x == -1) {
      if ($y == 1) {
        ### found third arm -1,1 ...
        $arm = 2;
        $state = 50;
        last;
      }
      if ($y == 0) {
        ### found fourth arm -1,0 ...
        $arm = 3;
        $state = 70;
        last;
      }
    }
    my $m = (2*$x + $y) % 5;
    ### at: "$x,$y   digits=".join(',',@digits)
    ### mod remainder: $m

    $x -= $modulus_to_x[$m];
    $y -= $modulus_to_y[$m];
    push @digits, $m;

    ### digit: "$m  to $x,$y"
    ### shrink to: ((2*$x + $y) / 5).','.((2*$y - $x) / 5)
    ### assert: (2*$x + $y) % 5 == 0
    ### assert: (2*$y - $x) % 5 == 0

    # shrink
    # (2 -1)  inverse (2  1)
    # (1 2)           (-1 2)
    #
    ($x,$y) = ((2*$x + $y) / 5,
               (2*$y - $x) / 5);
  }

  ### @digits
  my $arms = $self->{'arms'};
  if ($arm >= $arms) {
    return undef;
  }

  my $n = 0;
  foreach my $m (reverse @digits) {  # high to low
    ### $m
    ### digit: $modulus_to_digit[$state + $m]
    ### state: $state
    ### next state: $modulus_to_digit[$state+5 + $m]

    $n = 5*$n + $modulus_to_digit[$state + $m];
    $state = $modulus_to_digit[$state+5 + $m];
  }
  ### final n along arm: $n

  return $n*$arms + $arm;
}

#------------------------------------------------------------------------------

# whole plane covered when arms==4
sub xy_is_visited {
  my ($self, $x, $y) = @_;
  return ($self->{'arms'} == 4
          || defined($self->xy_to_n($x,$y)));
}

#------------------------------------------------------------------------------

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### QuintetCurve rect_to_n_range(): "$x1,$y1  $x2,$y2"

  my ($r_lo, $r_hi) = _rect_to_radius_range($x1,$y1, $x2,$y2);
  $r_hi *= 2;
  my $level_plus_1 = ceil( log(max(1,$r_hi/4)) / log(sqrt(5)) ) + 2;

  # Simple over-estimate would be: return (0, 5**$level_plus_1);

  my $level_limit = $level_plus_1;
  ### $level_limit
  if (is_infinite($level_limit)) { return ($level_limit,$level_limit); }

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);
  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
  ### sorted range: "$x1,$y1  $x2,$y2"

  my $rect_dist = sub {
    my ($x,$y) = @_;
    my $xd = ($x < $x1 ? $x1 - $x
              : $x > $x2 ? $x - $x2
              : 0);
    my $yd = ($y < $y1 ? $y1 - $y
              : $y > $y2 ? $y - $y2
              : 0);
    return ($xd*$xd + $yd*$yd);
  };

  my $arms = $self->{'arms'};
  ### $arms
  my $n_lo;
  {
    my @hypot = (4);
    my $top = 0;
    for (;;) {
    ARM_LO: foreach my $arm (0 .. $arms-1) {
        my $i = 0;
        my @digits;
        if ($top > 0) {
          @digits = ((0)x($top-1), 1);
        } else {
          @digits = (0);
        }

        for (;;) {
          my $n = 0;
          foreach my $digit (reverse @digits) { # high to low
            $n = 5*$n + $digit;
          }
          $n = $n*$arms + $arm;
          ### lo consider: "i=$i  digits=".join(',',reverse @digits)."  is n=$n"

          my ($nx,$ny) = $self->n_to_xy($n);
          my $nh = &$rect_dist ($nx,$ny);
          if ($i == 0 && $nh == 0) {
            ### lo found inside: $n
            if (! defined $n_lo || $n < $n_lo) {
              $n_lo = $n;
            }
            next ARM_LO;
          }

          if ($i == 0 || $nh > $hypot[$i]) {
            ### too far away: "nxy=$nx,$ny   nh=$nh vs ".$hypot[$i]

            while (++$digits[$i] > 4) {
              $digits[$i] = 0;
              if (++$i <= $top) {
                ### backtrack up ...
              } else {
                ### not found within this top and arm, next arm ...
                next ARM_LO;
              }
            }
          } else {
            ### lo descend ...
            ### assert: $i > 0
            $i--;
            $digits[$i] = 0;
          }
        }
      }

      # if an $n_lo was found on any arm within this $top then done
      if (defined $n_lo) {
        last;
      }

      ### lo extend top ...
      if (++$top > $level_limit) {
        ### nothing below level limit ...
        return (1,0);
      }
      $hypot[$top] = 5 * $hypot[$top-1];
    }
  }

  my $n_hi = 0;
 ARM_HI: foreach my $arm (reverse 0 .. $arms-1) {
    my @digits = ((4) x $level_limit);
    my $i = $#digits;
    for (;;) {
      my $n = 0;
      foreach my $digit (reverse @digits) { # high to low
        $n = 5*$n + $digit;
      }
      $n = $n*$arms + $arm;
      ### hi consider: "arm=$arm  i=$i  digits=".join(',',reverse @digits)."  is n=$n"

      my ($nx,$ny) = $self->n_to_xy($n);
      my $nh = &$rect_dist ($nx,$ny);
      if ($i == 0 && $nh == 0) {
        ### hi found inside: $n
        if ($n > $n_hi) {
          $n_hi = $n;
          next ARM_HI;
        }
      }

      if ($i == 0 || $nh > (4 * 5**$i)) {
        ### too far away: "$nx,$ny   nh=$nh vs ".(4 * 5**$i)

        while (--$digits[$i] < 0) {
          $digits[$i] = 4;
          if (++$i < $level_limit) {
            ### hi backtrack up ...
          } else {
            ### hi nothing within level limit for this arm ...
            next ARM_HI;
          }
        }

      } else {
        ### hi descend
        ### assert: $i > 0
        $i--;
        $digits[$i] = 4;
      }
    }
  }

  if ($n_hi == 0) {
    ### oops, lo found but hi not found
    $n_hi = $n_lo;
  }

  return ($n_lo, $n_hi);
}

#------------------------------------------------------------------------------
# levels

# level=0 
# level=1  0 to 4
# level=2  0 to 24    is 5^level-1
#
# multiple arms the same full points of arms=1
# so arms*5^level points numbered starting 0
#        = 5^level*arms - 1
sub level_to_n_range {
  my ($self, $level) = @_;
  return (0,  5**$level * $self->{'arms'} - 1);
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

#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Mandelbrot Math-PlanePath OEIS

=head1 NAME

Math::PlanePath::QuintetCentres -- self-similar "plus" shape centres

=head1 SYNOPSIS

 use Math::PlanePath::QuintetCentres;
 my $path = Math::PlanePath::QuintetCentres->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This a self-similar curve tracing out a "+" shape like the C<QuintetCurve>
but taking the centre of each square visited by that curve.

                                         92                        12
                                       /  |
            124-...                  93  91--90      88            11
              |                        \       \   /   \
        122-123 120     102              94  82  89  86--87        10
           \   /  |    /  |            /   /  |       |
            121 119 103 101-100      95  81  83--84--85             9
                   \   \       \       \   \
        114-115-116 118 104  32  99--98  96  80  78                 8
          |       |/   /   /  |       |/      |/   \
    112-113 110 117 105  31  33--34  97  36  79  76--77             7
       \   /   \       \   \       \   /   \      |
        111     109-108 106  30  42  35  38--37  75                 6
                      |/   /   /  |       |    /
                    107  29  43  41--40--39  74                     5
                           \   \              |
                 24--25--26  28  44  46  72--73  70      68         4
                  |       |/      |/   \   \   /   \   /   \
             22--23  20  27  18  45  48--47  71  56  69  66--67     3
               \   /   \   /   \      |        /   \      |
                 21   6  19  16--17  49  54--55  58--57  65         2
                    /  \      |       |    \      |    /
              4-- 5   8-- 7  15      50--51  53  59  64             1
               \      |    /              |/      |    \
          0-- 1   3   9  14              52      60--61  63     <- Y=0
              |/      |    \                          |/
              2      10--11  13                      62            -1
                          |/
                         12                                        -2

          ^
     -1  X=0  1   2   3   4   5   6   7   8   9  10  11  12  13

The base figure is the initial the initial N=0 to N=4.  It fills a "+" shape
as

           .....
           .   .
           . 4 .
           .  \.
       ........\....
       .   .   .\  .
       . 0---1 . 3 .
       .   . | ./  .
       ......|./....
           . |/.
           . 2 .
           .   .
           .....

=head2 Arms

The optional C<arms> parameter can give up to four copies of the curve, each
advancing successively.  For example C<arms=E<gt>4> is as follows.  Notice
the N=4*k points are the plain curve, and N=4*k+1, N=4*k+2 and N=4*k+3 are
rotated copies of it.

                         69                     ...              7
                       /  |                        \
        121     113  73  65--61      53             120          6
       /   \   /   \   \       \   /   \           /
    ...     117 105-109  77  29  57  45--49     116              5
                  |    /   /  |       |            \
                101  81  25  33--37--41  96-100-104 112          4
                  |    \   \              |       |/
             50  97--93  85  21  13  88--92  80 108  72          3
           /  |       |/      |/   \   \   /   \   /   \
         54  46--42  89  10  17   5-- 9  84  24  76  64--68      2
           \      |    /  |       |        /   \      |
             58  38  14   6-- 2   1  16--20  32--28  60          1
           /      |    \               \      |    /
         62  30--34  22--18   3   0-- 4  12  36  56          <- Y=0
          |    \   /          |       |/      |    \
     70--66  78  26  86  11-- 7  19   8  91  40--44  52         -1
       \   /   \   /   \   \   /  |    /  |       |/
         74 110  82  94--90  15  23  87  95--99  48             -2
           /  |       |            \   \      |
        114 106-102--98  43--39--35  27  83 103                 -3
           \              |       |/   /      |
            118      51--47  59  31  79 111-107 119     ...     -4
           /           \   /   \       \   \   /   \   /
        122              55      63--67  75 115     123         -5
           \                          |/
            ...                      71                         -6

                                  ^
     -7  -6  -5  -4  -3  -2  -1  X=0  1   2   3   4   5   6

The pattern an ever expanding "+" shape with first cell N=0 at the origin.
The further parts are effectively as follows,

                +---+
                |   |
        +---+---    +---+
        |   |           |
    +---+   +---+   +---+
    |         2 | 1 |   |
    +---+   +---+---+   +---+
        |   | 3 | 0         |
        +---+   +---+   +---+
        |           |   |
        +---+   +---+---+
            |   |
            +---+

At higher replication levels the sides become wiggly and spiralling, but
they're symmetric and mesh to fill the plane.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::QuintetCentres-E<gt>new ()>

=item C<$path = Math::PlanePath::QuintetCentres-E<gt>new (arms =E<gt> $a)>

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

Return C<(0, 5**$level - 1)>, or for multiple arms return C<(0, $arms *
5**$level - 1)>.

There are 5^level points in a level, or arms*5^level for multiple arms,
numbered starting from 0.

=back

=head1 FORMULAS

=head2 X,Y to N

The C<xy_to_n()> calculation is similar to the C<FlowsnakeCentres>.  For a
given X,Y a modulo 5 remainder is formed

    m = (2*X + Y) mod 5

This distinguishes the five squares making up the base figure.  For example
in the base N=0 to N=4 part the m values are

          +-----+
          | m=3 |           1
    +-----+-----+-----+
    | m=0 | m=2 | m=4 |   <- Y=0
    +-----+-----+-----+
          | m=1 |          -1
          +-----+
     X=0     1      2

From this remainder X,Y can be shifted down to the 0 position.  That
position corresponds to a vector multiple of X=2,Y=1 and 90-degree rotated
forms of that vector.  That vector can be divided out and X,Y shrunk with

    Xshrunk = (Y + 2*X) / 5
    Yshrunk = (2*Y - X) / 5

If X,Y are considered a complex integer X+iY the effect is a remainder
modulo 2+i, subtract that to give a multiple of 2+i, then divide by 2+i.
The vector X=2,Y=1 or 2+i is because that's the N=5 position after the base
shape.

The remainders can then be mapped to base 5 digits of N going from high to
low and making suitable rotations for the sub-part orientation of the curve.
The remainders alone give a traversal in the style of C<QuintetReplicate>.
Applying suitable rotations produces the connected path of
C<QuintetCentres>.

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A106665> (etc)

=back

    A099456   level Y end, being Im((2+i)^k)

    arms=2
      A139011   level Y end, being Re((2+i)^k)

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::QuintetCurve>,
L<Math::PlanePath::QuintetReplicate>,
L<Math::PlanePath::FlowsnakeCentres>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
