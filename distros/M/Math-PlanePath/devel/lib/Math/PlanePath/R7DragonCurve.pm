# Copyright 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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



# math-image --path=R7DragonCurve --all --scale=10
# cf A176405 R7 turns
#    A176416 R7B turns


package Math::PlanePath::R7DragonCurve;
use 5.004;
use strict;
use List::Util 'min'; # 'max'
*max = \&Math::PlanePath::_max;

use Math::PlanePath;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest',
  'xy_is_even';
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh';

use vars '$VERSION', '@ISA';
$VERSION = 125;
@ISA = ('Math::PlanePath');

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;
use constant parameter_info_array =>
  [ { name      => 'type',
      share_key => 'type_r7dragon',
      display   => 'Type',
      type      => 'enum',
      default   => 'A',
      choices   => ['A','B'],
    },
    { name      => 'arms',
      share_key => 'arms_6',
      display   => 'Arms',
      type      => 'integer',
      minimum   => 1,
      maximum   => 6,
      default   => 1,
      width     => 1,
      description => 'Arms',
    } ];

use constant dx_minimum => -2;
use constant dx_maximum => 2;
use constant dy_minimum => -1;
use constant dy_maximum => 1;

#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'arms'} = max(1, min(6, $self->{'arms'} || 1));
  $self->{'type'} ||= 'A';
  return $self;
}

my @dir6_to_si = (1,0,0, -1,0,0);
my @dir6_to_sj = (0,1,0, 0,-1,0);
my @dir6_to_sk = (0,0,1, 0,0,-1);

# F0F1F1F0F0F1F, 0->0, 1->1
#
#         14   12
#           \  / \
#            \/   \
#         13,10--11,8
#              \  / \
#               9/   \
#         2----3,6----7    i=+2,j=+1
#          \   / \
#           \ /   \
#      0----1,4----5
#
#      0 1   2  3  4  5

#  B      5----6,3----7    i=+2,j=+1
#          \   / \
#           \ /   \
#      0----1,4----2
#
#      0 1   2  3  4  5



my @digit_to_i   = (0,1,0,1,1,2,1);
my @digit_to_j   = (0,0,1,1,0,0,1);
my @digit_to_rot = (0,1,0,-1,0,1,0);

#                   0 1 2 3 4 5 6
my @digit_b_to_a = (0,4,5,3,1,2,6);

sub n_to_xy {
  my ($self, $n) = @_;
  ### R7DragonCurve n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n, $n); }

  my $zero = ($n * 0);  # inherit bignum 0

  my $i = 0;
  my $j = 0;
  my $k = 0;
  my $si = $zero;
  my $sj = $zero;
  my $sk = $zero;

  # initial rotation from arm number
  {
    my $int = int($n);
    my $frac = $n - $int;  # inherit possible BigFloat
    $n = $int;             # BigFloat int() gives BigInt, use that

    my $rot = _divrem_mutate ($n, $self->{'arms'});

    my $s = $zero + 1;  # inherit bignum 1
    if ($rot >= 3) {
      $s = -$s;         # rotate 180
      $frac = -$frac;
      $rot -= 3;
    }
    if ($rot == 0)    { $i = $frac; $si = $s; } # rotate 0
    elsif ($rot == 1) { $j = $frac; $sj = $s; } # rotate +60
    else              { $k = $frac; $sk = $s; } # rotate +120
  }

  foreach my $digit (digit_split_lowtohigh($n,7)) {
    ### at: "$i,$j,$k   side $si,$sj,$sk"
    ### $digit

    if ($self->{'type'} eq 'B') {
      $digit = $digit_b_to_a[$digit];
    }

    if ($digit == 1) {
      ($i,$j,$k) = (-$j,-$k,$i);   # rotate +120
      $i += $si;
      $j += $sj;
      $k += $sk;

    } elsif ($digit == 2) {
      $i -= $sk;
      $j += $si;
      $k += $sj;

    } elsif ($digit == 3) {
      ($i,$j,$k) = ($k,-$i,-$j);
      $i += $si;
      $j += $sj;
      $k += $sk;

      $i -= $sk;
      $j += $si;
      $k += $sj;

    } elsif ($digit == 4) {
      $i += $si;
      $j += $sj;
      $k += $sk;

    } elsif ($digit == 5) {
      ($i,$j,$k) = (-$j,-$k,$i);   # rotate +120
      $i += 2*$si;
      $j += 2*$sj;
      $k += 2*$sk;

    } elsif ($digit == 6) {
      $i += $si;
      $j += $sj;
      $k += $sk;

      $i -= $sk;
      $j += $si;
      $k += $sj;
    }

    # $i += $digit_to_i[$digit];
    # $j += $digit_to_j[$digit];

    # multiple 2i+j
    ($si,$sj,$sk) = (2*$si - $sk,
                     2*$sj + $si,
                     2*$sk + $sj);
  }

  ### final: "$i,$j,$k   side $si,$sj,$sk"
  ### is: (2*$i + $j - $k).",".($j+$k)

  return (2*$i + $j - $k, $j+$k);
}


# all even points when arms==6
sub xy_is_visited {
  my ($self, $x, $y) = @_;
  # FIXME
  return 0;
  if ($self->{'arms'} == 6) {
    return xy_is_even($self,$x,$y);
  } else {
    return defined($self->xy_to_n($x,$y));
  }
}

# maximum extent -- no, not quite right
#
#          .----*
#           \
#       *----.
#
# Two triangle heights, so
#     rnext = 2 * r * sqrt(3)/2
#           = r * sqrt(3)
#     rsquared_next = 3 * rsquared
# Initial X=2,Y=0 is rsquared=4
# then X=3,Y=1 is 3*3+3*1*1 = 9+3 = 12 = 4*3
# then X=3,Y=3 is 3*3+3*3*3 = 9+3 = 36 = 4*3^2
#
my @try_dx = (2, 1, -1, -2, -1,  1);
my @try_dy = (0, 1,  1, 0,  -1, -1);

sub xy_to_n {
  return scalar((shift->xy_to_n_list(@_))[0]);
}
sub xy_to_n_list {
  my ($self, $x, $y) = @_;
  ### R7DragonCurve xy_to_n_list(): "$x, $y"

  # FIXME
  return;

  $x = round_nearest($x);
  $y = round_nearest($y);

  if (is_infinite($x)) {
    return $x;  # infinity
  }
  if (is_infinite($y)) {
    return $y;  # infinity
  }

  my @n_list;
  my $xm = 2*$x;  # doubled out
  my $ym = 2*$y;
  foreach my $i (0 .. $#try_dx) {
    my $t = $self->Math::PlanePath::R7DragonMidpoint::xy_to_n
      ($xm+$try_dx[$i], $ym+$try_dy[$i]);

    ### try: ($xm+$try_dx[$i]).",".($ym+$try_dy[$i])
    ### $t

    next unless defined $t;

    my ($tx,$ty) = n_to_xy($self,$t)  # not a method for R7DragonRounded
      or next;

    if ($tx == $x && $ty == $y) {
      ### found: $t
      if (@n_list && $t < $n_list[0]) {
        unshift @n_list, $t;
      } elsif (@n_list && $t < $n_list[-1]) {
        splice @n_list, -1,0, $t;
      } else {
        push @n_list, $t;
      }
      if (@n_list == 3) {
        return @n_list;
      }
    }
  }
  return @n_list;
}

# minimum  -- no, not quite right
#
#                *----------*
#                 \
#                  \   *
#               *   \
#                    \
#          *----------*
#
# width = side/2
# minimum = side*sqrt(3)/2 - width
#         = side*(sqrt(3)/2 - 1)
#
# minimum 4/9 * 2.9^level roughly
# h = 4/9 * 2.9^level
# 2.9^level = h*9/4
# level = log(h*9/4)/log(2.9)
# 3^level = 3^(log(h*9/4)/log(2.9))
#         = h*9/4, but big bigger for log
#
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### R7DragonCurve rect_to_n_range(): "$x1,$y1  $x2,$y2"
  my $xmax = int(max(abs($x1),abs($x2)));
  my $ymax = int(max(abs($y1),abs($y2)));
  return (0,
          ($xmax*$xmax + 3*$ymax*$ymax + 1)
          * 1/5
          * $self->{'arms'});
}

1;
__END__
