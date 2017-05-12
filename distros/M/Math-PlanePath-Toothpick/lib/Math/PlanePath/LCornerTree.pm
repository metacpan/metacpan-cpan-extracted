# Copyright 2012, 2013, 2014, 2015 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.


# parts=2 row total X = 3^count1bits(depth) = A048883
# parts=wedge row total X = (3^count1bits(depth) + 1) / 2


# A147562 U-W
# A160410
# A151920

#------------------------------------------------------------------------------
# cf A183126 triplet around each exposed end, starting from length=1 two ends
#    A183127 added  0,1,6,16,16,40,16,40,40,112,16
#    http://www.math.vt.edu/people/layman/sequences/A183126.htm
# added = 4 * 3^count1bits(depth) or thereabouts
# two diagonal halves
#
#------------------------------------------------------------------------------
# wedge odd/even

#     1  1
#  2  0  1
#  2  2

#  3  3        3  3
#  3  2  2  2  2  3
#  3  2  1  1  2
#  3  3  0  1  2
#        3  2  2  3
#        3  3  3  3

#  4  4  4  4  4  4  4  4
#  4  3  3  4  4  3  3  4
#     3  2  2  2  2  3  4
#     3  2  1  1  2  4  4
#  4  3  3  0  1  2  4  4
#  4  4     3  2  2  3  4
#        4  3  3  3  3  4
#        4  4        4  4
#

#------------------------------------------------------------------------------


package Math::PlanePath::LCornerTree;
use 5.004;
use strict;
use Carp 'croak';
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 18;
use Math::PlanePath;
@ISA = ('Math::PlanePath');


use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits 119  # v.119 for round_up_pow()
  'round_up_pow',
  'round_down_pow',
  'bit_split_lowtohigh',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;
use constant parameter_info_array =>
  [ { name            => 'parts',
      share_key       => 'parts_lcornertree',
      display         => 'Parts',
      type            => 'enum',
      default         => '4',
      choices         => ['4','3','2','1',
                          'octant','octant+1','octant_up','octant_up+1',
                          'wedge','wedge+1','diagonal','diagonal-1',
                         ],
      choices_display => ['4','3','2','1',
                          'Octant','Octant+1','Octant Up','Octant Up+1',
                          'Wedge','Wedge+1','Diagonal','Diagonal 1',
                         ],
      description     => 'Which parts of the plane to fill.',
    },
  ];

{
  my %x_negative = (4             => 1,
                    3             => 1,
                    2             => 1,
                    1             => 0,
                    octant        => 0,
                    'octant+1'    => 0,
                    octant_up     => 0,
                    'octant_up+1' => 0,
                    wedge         => 1,
                    'wedge+1'     => 1,
                    diagonal      => 1,
                    'diagonal-1'  => 1,
                   );
  sub x_negative {
    my ($self) = @_;
    return $x_negative{$self->{'parts'}};
  }
}
{
  my %y_negative = (4             => 1,
                    3             => 1,
                    2             => 0,
                    1             => 0,
                    octant        => 0,
                    'octant+1'    => 0,
                    octant_up     => 0,
                    'octant_up+1' => 0,
                    wedge         => 0,
                    'wedge+1'     => 0,
                    diagonal      => 1,
                    'diagonal-1'  => 1,
                   );
  sub y_negative {
    my ($self) = @_;
    return $y_negative{$self->{'parts'}};
  }
}

{
  my %x_negative_at_n = (4             => 1,
                         3             => 2,
                         2             => 1,
                         1             => undef,
                         octant        => undef,
                         'octant+1'    => undef,
                         octant_up     => undef,
                         'octant_up+1' => undef,
                         wedge         => 1,
                         'wedge+1'     => 1,
                         diagonal      => 2,
                         'diagonal-1'  => 11,
                        );
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n{$self->{'parts'}};
  }
}
{
  my %y_negative_at_n = (4             => 2,
                         3             => 1,
                         2             => undef,
                         1             => undef,
                         octant        => undef,
                         'octant+1'    => undef,
                         octant_up     => undef,
                         'octant_up+1' => undef,
                         wedge         => undef,
                         'wedge+1'     => undef,
                         diagonal      => 0,
                         'diagonal-1'  => 4,
                        );
  sub y_negative_at_n {
    my ($self) = @_;
    return $y_negative_at_n{$self->{'parts'}};
  }
}

{
  my %sumxy_minimum = (1             => 0,
                       octant        => 0,
                       'octant+1'    => 0,
                       octant_up     => 0,
                       'octant_up+1' => 0,
                       wedge         => -1,  # X>=-Y-1 so X+Y>=-1
                       'wedge+1'     => -2,  # X>=-Y-2 so X+Y>=-2
                       diagonal      => -1,
                       'diagonal-1'  => 0,   # X>=-Y
                      );
  sub sumxy_minimum {
    my ($self) = @_;
    return $sumxy_minimum{$self->{'parts'}};
  }
}
{
  my %diffxy_minimum = (octant     => 0,   # octant X>=Y so X-Y>=0
                        'octant+1' => -1,  # octant X>=Y-1 so X-Y>=-1
                       );
  sub diffxy_minimum {
    my ($self) = @_;
    return $diffxy_minimum{$self->{'parts'}};
  }
}
{
  my %diffxy_maximum = (octant_up     => 0,  # octant_up   X<=Y so X-Y<=0
                        'octant_up+1' => 1,  # octant_up+1 X<=Y+1 so X-Y<=1
                        wedge         => 0,  # wedge X<=Y so X-Y<=0
                       'wedge+1'      => 1,  # wedge+1 X>=Y+1 so X-Y>=1
                       );
  sub diffxy_maximum {
    my ($self) = @_;
    return $diffxy_maximum{$self->{'parts'}};
  }
}

# parts=1 Dir4 max 12,-11
#                 121,-110
#                 303,-213
#                1212,-1031
#               12121,-10310      -> 12,-10
#               30303,-21213      -> 3,-2
# parts=2  dX=big,dY=-1
# parts=3  dX=big,dY=-1
# parts=4  dx=0,dy=-1 at N=1
{
  my %dir_maximum_dxdy = (1             => [3,-2],  # supremum
                          2             => [0,0],   # supremum
                          3             => [0,0],   # supremum
                          4             => [0,-1],  # N=1  dX=0,dY=-1 South
                          octant        => [0,-2],  # N=4  dX=0,dY=-2 South
                          'octant+1'    => [1,-2],  # N=6  dX=1,dY=-2 SSE
                          octant_up     => [0,-1],  # N=8  dX=0,dY=-1 South
                          'octant_up+1' => [0,-1],  # N=11 dX=0,dY=-1 South
                          wedge         => [0,-1],  # N=13 dX=0,dY=-1 South
                          'wedge+1'     => [0,-1],  # N=6  dX=0,dY=-1 South
                          diagonal      => [2,-2],  # N=2  South-East
                          'diagonal-1'  => [3,-3],  # N=12 South-East
                         );
  sub dir_maximum_dxdy {
    my ($self) = @_;
    return @{$dir_maximum_dxdy{$self->{'parts'}}};
  }
}

{
  my %_UNDOCUMENTED__turn_any_right_at_n
    = (1             => 37,
       2             => 22,
       3             => 1,
       4             => 15,
       octant        => 2,
       'octant+1'    => 36,
       octant_up     => 2,
       'octant_up+1' => 33,
       wedge         => 1,
       'wedge+1'     => 19,
       diagonal      => 21,
       'diagonal-1'  => 27,
      );
  sub _UNDOCUMENTED__turn_any_right_at_n {
    my ($self) = @_;
    return $_UNDOCUMENTED__turn_any_right_at_n{$self->{'parts'}};
  }
}

{
  my %any_num_children_2
    = (octant        => 1,
       octant_up     => 1,
       wedge         => 1,
       diagonal      => 1,
      );
  sub tree_num_children_list {
    my ($self) = @_;
    return (0,
            ($any_num_children_2{$self->{'parts'}} ? (2) : ()),
            3);
  }
}

#------------------------------------------------------------------------------

# how many toplevel root nodes in the tree of given $parts
my %parts_to_numroots = (4             => 4,
                         3             => 3,
                         2             => 2,
                         1             => 1,
                         octant        => 1,
                         'octant+1'    => 1,
                         octant_up     => 1,
                         'octant_up+1' => 1,
                         wedge         => 2,
                         'wedge+1'     => 2,
                         diagonal      => 3,
                         'diagonal-1'  => 1,
                        );
sub tree_num_roots {
  my ($self) = @_;
  return $parts_to_numroots{$self->{'parts'}};
}

sub new {
  my $self = shift->SUPER::new(@_);
  my $parts = ($self->{'parts'} ||= 4);
  if (! exists $parts_to_numroots{$parts}) {
    croak "Unrecognised parts: ",$parts;
  }
  return $self;
}

my @next_state = (0,12,0,4, 4,0,4,8, 8,4,8,12, 12,8,12,0);
my @digit_to_x = (0,1,1,0, 1,1,0,0, 1,0,0,1, 0,0,1,1);
my @digit_to_y = (0,0,1,1, 0,1,1,0, 1,1,0,0, 1,0,0,1);

my @diagonal1_n_to_xy = ([0,0],
                         [1,0],
                         [1,1],
                         [0,1]);

sub n_to_xy {
  my ($self, $n) = @_;
  ### LCornerTree n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }
  {
    my $int = int($n);
    ### $int
    ### $n
    if ($n != $int) {
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $frac = $n - $int;  # inherit possible BigFloat
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int;       # BigFloat int() gives BigInt, use that
  }

  if (is_infinite($n)) { return ($n,$n); }
  my $zero = ($n * 0); # inherit bignum 0
  my $parts = $self->{'parts'};

  if ($parts eq 'diagonal-1') {
    if ($n <= 3) {
      return @{$diagonal1_n_to_xy[$n]};
    }
  }

  my ($depthbits, $ndepth, $nwidth) = _n0_to_depthbits($n, $parts);

  ### $n
  ### $ndepth
  ### $nwidth
  ### $parts
  ### $depthbits
  ### assert: $nwidth == $self->tree_depth_to_n(1+digit_join_lowtohigh($depthbits,2,$n*0)) - $self->tree_depth_to_n(digit_join_lowtohigh($depthbits,2,$n*0))

  $n -= $ndepth;
  ### N remainder offset into row: $n
  ### assert: $n >= 0
  ### assert: $n < $nwidth

  my $quad;
  my $x = 0;
  my $y = 0;
  if ($parts eq 'wedge') {
    ### assert: $nwidth % 2 == 0
    my $noct = $nwidth/2;
    if ($n < $noct) {
      $n += $noct - 1;
      $quad = 0;
    } else {
      $n -= $noct;
      $quad = 1;
    }
  } elsif ($parts eq 'wedge+1') {
    ### assert: $nwidth % 2 == 0
    my $noct = $nwidth/2;
    if ($n < $noct) {
      ### first half, add to N: $noct - 3
      $n += $noct - 3;
      $quad = 0;
    } else {
      ### second half ...
      $n -= $noct;
      $quad = 1;
    }

  } elsif ($parts eq 'diagonal') {
    ### assert: ($nwidth+1)%4 == 0
    my $noct = ($nwidth+1)/4;
    ### $noct
    if ($n < $noct) {
      ### first oct is quad=3 ...
      $n += $noct - 1;
      $quad = 3;
    } elsif ($n >= $nwidth - $noct) {
      ### last oct is quad=1 ...
      $n -= ($nwidth - $noct);
      $quad = 1;
    } else {
      $n -= $noct;
      $quad = 0;
    }

  } elsif ($parts eq 'diagonal-1') {
    ### assert: ($nwidth+3) % 4 == 0
    my $noct = ($nwidth+3)/4;
    ### $noct
    if ($n < $noct) {
      ### first oct is quad=3 ...
      $n += $noct - 3;
      $quad = 3;
      $x = -1;
      $y = 1;
    } elsif ($n >= $nwidth - $noct) {
      ### last oct is quad=1 ...
      $n -= ($nwidth - $noct);
      $quad = 1;
      $x = 1;
      $y = -1;
    } else {
      $n -= $noct;
      $quad = 0;
      $x = 1;
      $y = 1;
    }

  } elsif ((my $numroots = $parts_to_numroots{$parts}) > 1) {
    # like a mixed-radix high digit radix $numroots then rest radix 3
    $nwidth /= $numroots;
    ($quad, $n) = _divrem($n,$nwidth);
    ### $quad
    ### assert: $quad >= 0
    ### assert: $quad < $numroots
    if ($parts eq '3') {
      if ($quad == 1) { $quad = 3; }   # quad=1 -> 3
      if ($quad == 2) { $quad = 1; }   # quad=2 -> 1
    }
  } else {
    $quad = 0;
    if ($parts eq 'octant_up') {
      $n += $nwidth - 1;
    } elsif ($parts eq 'octant_up+1') {
      $n += $nwidth - 3;
    }
  }
  ### $quad
  ### $n

  my @nternary = digit_split_lowtohigh($n, 3);
  ### @nternary

  # Ternary digits for triple parts of Noffset mapped out to base4 digits in
  # the style of LCornerReplicate.
  # Where there's a 0-bit in the depth is a 0-digit for Nbase4.
  # Where there's a 1-bit in the depth takes a ternary+1 for Nbase4.
  # Small Noffset has less trits than the depth 1s, hence "nternary || 0".
  #
  my @nbase4 = map {$_ && (1 + (shift @nternary || 0))} @$depthbits;
  ### @nbase4

  my $state = 0;
  my (@xbits, @ybits);
  foreach my $i (reverse 0 .. $#nbase4) {    # digits high to low
    $state += $nbase4[$i];
    $xbits[$i] = $digit_to_x[$state];
    $ybits[$i] = $digit_to_y[$state];
    $state = $next_state[$state];
  }

  ### xbits join: digit_join_lowtohigh (\@xbits, 2, $zero)
  ### ybits join: digit_join_lowtohigh (\@ybits, 2, $zero)
  $x += digit_join_lowtohigh (\@xbits, 2, $zero);
  $y += digit_join_lowtohigh (\@ybits, 2, $zero);

  if ($quad & 1) {
    ($x,$y) = (-1-$y,$x); # rotate +90
  }
  if ($quad & 2) {
    $x = -1-$x; # rotate +180
    $y = -1-$y;
  }
  ### final: "$x,$y"
  return $x,$y;
}

# my @next_state = (0, 1, 3, 2,
# my @yx_to_digit = (0, 1, 3, 2,
#                    0, 1, 3, 2,     # rot +90
#                   );

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### LCornerTree xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  my $parts = $self->{'parts'};
  my $quad = 0;

  if ($parts eq '3') {
    if ($x < 0) {
      if ($y < 0) {
        return undef;
      }
      ($x,$y) = ($y,-1-$x); # rotate -90 and offset
      $quad = 2;
    } else {
      if ($y < 0) {
        ($x,$y) = (-1-$y,$x); # rotate +90 and offset
        $quad = 1;
      }
    }

  } elsif ($parts eq 'octant') {
    if ($y < 0 || $y > $x) { return undef; }
  } elsif ($parts eq 'octant+1') {
    if ($x < 0 || $y < 0 || $y > $x+1) { return undef; }

  } elsif ($parts eq 'octant_up') {
    if ($x < 0 || $x > $y) { return undef; }
  } elsif ($parts eq 'octant_up+1') {
    if ($y < 0 || $x < 0 || $x > $y+1) { return undef; }

  } elsif ($parts eq 'wedge') {
    if ($x < -1-$y || $x > $y) { return undef; }
    if ($x < 0) {
      ($x,$y) = ($y,-1-$x); # rotate -90 and offset
      $quad = 1;
    }
  } elsif ($parts eq 'wedge+1') {
    if ($y < 0 || $x < -2-$y || $x > $y+1) { return undef; }
    if ($x < 0) {
      ($x,$y) = ($y,-1-$x); # rotate -90 and offset
      $quad = 1;
    }

  } elsif ($parts eq 'diagonal') {
    if ($x < -1-$y) { return undef; }  # must have X+Y>=-1
    if ($y < 0) {
      ### lower triangular Y neg ...
      ($x,$y) = (-1-$y,$x); # rotate +90 and offset
    } elsif ($x < 0) {
      ### left triangular X neg ...
      ($x,$y) = ($y,-1-$x); # rotate -90 and offset
      $quad = 2;
    } else {
      ### first quad ...
      $quad = 1;
    }

  } elsif ($parts eq 'diagonal-1') {
    if ($x == 0 && $y == 0) {
      return 0;
    }
    if ($x < -$y) { return undef; }  # must have X+Y>=0
    if ($y <= 0) {
      ### lower triangular Y<=0 ...
      ($x,$y) = (-$y,$x-1); # rotate +90 and offset
    } elsif ($x <= 0) {
      ### left triangular X<=0 ...
      ($x,$y) = ($y-1,-$x); # rotate -90 and offset
      $quad = 2;
    } else {
      ### first quad ...
      $x -= 1;
      $y -= 1;
      $quad = 1;
    }

  } else {
    # parts=1,2,4

    if ($y < 0) {
      if ($parts ne '4') {
        return undef;
      }
      $x = -1-$x; # rotate +180
      $y = -1-$y;
      $quad = 2;
    }

    if ($x < 0) {
      if ($parts eq '1') {
        return undef;
      }
      ($x,$y) = ($y,-1-$x); # rotate +90 and offset
      $quad++;
    }
  }
  ### $quad
  ### xy rotated into first quad: "$x,$y"

  if (is_infinite($x)) {
    return $x;
  }
  if (is_infinite($y)) {
    return $y;
  }

  my $zero = ($x * 0 * $y); # inherit bignum 0
  # my @xbits = bit_split_lowtohigh($x);
  # my @ybits = bit_split_lowtohigh($y);
  # my $exp = max($#xbits, $#ybits);
  # my $len = 2**$exp;

  my ($len,$exp) = round_down_pow(max($x,$y), 2);
  my @depthbits;
  my @ndigits;  # high to low

  foreach my $i (reverse 0 .. $exp) {
    ### at: "x=$x,y=$y  ndigits=".join(',',@ndigits)." len=$len"

    ### assert: $x >= 0
    ### assert: $y >= 0
    ### assert: $x < 2 * $len
    ### assert: $y < 2 * $len
    ### assert: $len == int($len)

    if ($depthbits[$i] = ($x >= $len || $y >= $len ? 1 : 0)) {
      # one of the three parts away from the origin

      if ($y < $len) {
        ### lower right, digit 0 ...
        ($x,$y) = ($len-1-$y,$x-$len);  # rotate +90 and offset
        push @ndigits, 0;
      } elsif ($x >= $len) {
        ### diagonal, digit 1 ...
        ### right, digit 1 ...
        $x -= $len;
        $y -= $len;
        push @ndigits, 1;
      } else {
        ### top left, digit 2 ...
        ($x,$y) = ($y-$len,$len-1-$x);  # rotate -90 and offset
        push @ndigits, 2;
      }
    }

    $len /= 2;
  }

  @ndigits = reverse @ndigits;
  my $n = digit_join_lowtohigh(\@ndigits,3,$zero);
  ### $n
  ### $quad

  if ($quad) {
    ### npower: 3**scalar(@ndigits)
    ### quad npower: $quad * 3**scalar(@ndigits)
    $n += $quad * 3**scalar(@ndigits);
  }
  if ($parts eq 'octant_up' || $parts eq 'octant_up+1'
      || $parts eq 'wedge' || $parts eq 'wedge+1'
      || $parts eq 'diagonal' || $parts eq 'diagonal-1') {
    $n -= (3**scalar(@ndigits) - 1) / 2;
  }

  my $depth = digit_join_lowtohigh(\@depthbits,2,$zero);
  if ($parts eq 'diagonal-1') {
    if ($depth) { $n += 1; }
    $depth += 1;
  }
  if ($parts eq 'octant_up+1') {
    if ($depth) { $n += 1; }
  } elsif ($parts eq 'wedge+1') {
    if ($depth) { $n += 1; }
  }

  ### @depthbits
  ### $depth
  $n += $self->tree_depth_to_n($depth);

  ### final n: $n
  return $n;
}


# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### LCornerTree rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  my $parts = $self->{'parts'};
  my $xymax;
  if ($parts eq 'octant') {
    if ($y2 < 0 || $x2 < $y1) { return (1,0); }
    $xymax = $x2;
  } elsif ($parts eq 'octant+1') {
    if ($x2 < 0 || $y2 < 0 || $y1 > $x2+1) { return (1,0); }
    $xymax = $x2+1;

  } elsif ($parts eq 'octant_up') {
    if ($x2 < 0 || $y2 < $x1) { return (1,0); }
    $xymax = $y2;
  } elsif ($parts eq 'octant_up+1') {
    if ($x2 < 0 || $y2 < 0 || $x1 > $y2+1) { return (1,0); }
    $xymax = $y2+1;

  } elsif ($parts eq 'wedge') {
    if ($x2 < -1-$y2 || $x1 > $y2) { return (1,0); }
    $xymax = $y2;
  } elsif ($parts eq 'wedge+1') {
    if ($x2 < -2-$y2 || $x1 > $y2+1) { return (1,0); }
    $xymax = $y2+1;

  } else {
    $xymax = max($x2,$y2);
    if ($parts eq 'diagonal') {
      if ($x2 < -1-$y2) { return (1,0); }

    } elsif ($parts eq 'diagonal-1') {
      if ($x2 < -$y2) { return (1,0); }

    } elsif ($parts eq '1') {
      if ($x2 < 0 || $y2 < 0) { return (1,0); }

    } else {
      # parts=2,3,4
      $xymax = max($xymax, -1-$x1);

      if ($parts eq '2') {
        if ($y2 < 0) { return (1,0); }
      } else {
        # parts=3,4
        $xymax = max($xymax, -1-$y1);

        if ($parts eq '3') {
          if ($x2 < 0 && $y2 < 0)  { return (1,0); }
        }
      }
    }
  }
  ### $xymax

  my ($depth) = round_down_pow($xymax,2);
  $depth *= 2;
  if ($parts eq 'diagonal-1') {
    $depth += 1;
  }
  ### depth: 2*$xymax
  return (0,
          $self->tree_depth_to_n($depth));
}

#------------------------------------------------------------------------------

# quad(d) = sum i=0tod 3^count1bits(i)
# quad(d) = 2*oct(d) + d
# oct(d) = (quad(d) + d) / 2
# oct(d) = sum i=0tod (3^count1bits(d) + 1)/2
# quad add   1,3,3, 9, 3, 9, 9,27, 3, 9, 9,27,9,27,27,81   A048883
# oct add    1,2,2, 5, 2, 5, 5,14, 2, 5, 5,14,5,14,14,41,  A162784
# oct total  1,3,5,10,12,17,22,36,38,43,48,
#
sub tree_depth_to_n {
  my ($self, $depth) = @_;
  ### tree_depth_to_n(): "depth=$depth"

  if ($depth < 0) {          return undef; }
  if (is_infinite($depth)) { return $depth; }

  my $parts = $self->{'parts'};
  if ($parts eq 'diagonal-1') {
    if ($depth <= 1) {
      return $depth;
    }
    $depth -= 1;
  }

  # pow3 = 3^count1bits(depth)
  my $n = ($depth*0);   # inherit bignum 0
  my $pow3 = $n + 1;    # inherit bignum 1

  foreach my $bit (reverse bit_split_lowtohigh($depth)) {  # high to low
    $n *= 4;
    if ($bit) {
      $n += $pow3;
      $pow3 *= 3;
    }
  }

  if ($parts eq 'octant' || $parts eq 'octant_up') {
    $n = ($n + $depth) / 2;
  } elsif ($parts eq 'octant+1' || $parts eq 'octant_up+1') {
    $n = ($n + 3*$depth) / 2;
    if ($depth) { $n -= 1; }
  } elsif ($parts eq 'wedge') {
    $n += $depth;
  } elsif ($parts eq 'wedge+1') {
    $n += 3*$depth;
    if ($depth) { $n -= 2; }
  } elsif ($parts eq 'diagonal') {
    $n = 2*$n + $depth;
  } elsif ($parts eq 'diagonal-1') {
    $n = 2*$n + 3*$depth - 1;
  } else {
    $n *= $parts;
  }

  return $n;
}

sub tree_n_to_depth {
  my ($self, $n) = @_;
  ### LCornerTree n_to_xy(): $n

  if ($n < 0) { return undef; }
  $n = int($n);
  if (is_infinite($n)) {
    return $n;
  }

  if ($self->{'parts'} eq 'diagonal-1') {
    if ($n == 0) { return 0; }
  }

  my ($depthbits) = _n0_to_depthbits ($n, $self->{'parts'});
  my $depth = digit_join_lowtohigh ($depthbits, 2, $n*0);
  if ($self->{'parts'} eq 'diagonal-1') {
    $depth += 1;
  }
  return $depth;
}

# nwidth = 4^k next 4^(k-1) or to 3*4^(k-1)
#
# octant nwidth = (4^k + 2^k)/2
#               = 2^k*(2^k+1)/2
# next (4^(k-1) + 2^(k-1))/2
#      = 2^(k-1)*(2^(k-1) + 1)/2
#
#       0 1 2   4      6     8          12            16
# oct   0,1,4,7,13,16,22,28,43,46,52,58,73,79,94,109,151,154,160,166,
# oct+1 0,1,3,5,10,12,17,22,36,38,43,48,62,67,81, 95,136,138,143,148,
#
# wedge+1 0,2,8,14,26,32,44,56,86,92,104,116,146,158,188,218,302,308,320,332,
#
sub _n0_to_depthbits {
  my ($n, $parts) = @_;
  ### _n0_to_depthbits(): $n
  ### $parts

  my $numroots = $parts_to_numroots{$parts};
  if ($n < $numroots) {
    ### root point, depth=0 ...
    return ([], 0, $numroots); # $n is in row depth=0
  }

  my $ndepth = 0;
  my ($nmore, $nhalf, $bitpos);
  if ($parts eq 'octant' || $parts eq 'octant_up') {
    ($nmore, $bitpos) = round_down_pow (2*$n, 4);
    $nhalf = 2**$bitpos;
  } elsif ($parts eq 'octant+1' || $parts eq 'octant_up+1') {
    ($nmore, $bitpos) = round_down_pow (2*$n, 4);
    $nhalf = 2**$bitpos;
    $ndepth = -1;

  } elsif ($parts eq 'wedge') {
    ($nmore, $bitpos) = round_down_pow ($n, 4);
    $nhalf = 2**$bitpos;
  } elsif ($parts eq 'wedge+1') {
    ($nmore, $bitpos) = round_down_pow ($n, 4);
    $nhalf = 2**$bitpos;
    $ndepth = -2;

  } elsif ($parts eq 'diagonal') {
    ($nmore, $bitpos) = round_down_pow ($n/2, 4);
    $nmore *= 2;
    $nhalf = 2**$bitpos;

  } elsif ($parts eq 'diagonal-1') {
    if ($n <= 3) {
      ### n in row depth=1 points ...
      return ([], 1, 3);
    }
    ($nmore, $bitpos) = round_down_pow ($n, 4);
    $nmore *= 2;
    $nhalf = 2**$bitpos;
    $ndepth = -1;

  } else {
    ($nmore, $bitpos) = round_down_pow ($n/$numroots, 4);
    $nmore *= $parts;
    $nhalf = 0;
  }
  ### $nmore
  ### $nhalf
  ### $bitpos

  my @depthbits;
  for (;;) {
    ### at: "n=$n ndepth=$ndepth nmore=$nmore nhalf=$nhalf bitpos=$bitpos depthbits=".join(',',map{$_||0}@depthbits)

    my $ncmp;
    if ($parts eq 'wedge' || $parts eq 'diagonal') {
      $ncmp = $ndepth + $nmore + $nhalf;
    } elsif ($parts eq 'wedge+1') {
      $ncmp = $ndepth + $nmore + 3*$nhalf;
    } elsif ($parts eq 'diagonal-1') {
      $ncmp = $ndepth + $nmore + 3*$nhalf;
    } elsif ($nhalf) { # octant, octant_up
      $ncmp = $ndepth + ($nmore + $nhalf)/2;
      if ($parts eq 'octant+1' || $parts eq 'octant_up+1') {
        $ncmp += $nhalf;
      }
    } else {
      $ncmp = $ndepth + $nmore;
    }
    ### $ncmp

    if ($n >= $ncmp) {
      ### use this depthbit ...
      $depthbits[$bitpos] = 1;
      $ndepth = $ncmp;
      $nmore *= 3;
    } else {
      $depthbits[$bitpos] = 0;
    }
    $bitpos--;
    last unless $bitpos >= 0;

    $nmore /= 4;
    $nhalf /= 2;
  }

  # Nwidth = 3**count1bits(depth)
  ### final ...
  ### $nmore
  ### $nhalf
  ### @depthbits
  # except for parts=diagonal
  # ### assert: $nmore == $numroots * 3 ** (scalar(grep{$_}@depthbits))

  if ($parts eq 'wedge' || $parts eq 'diagonal') {
    $nmore += 1;
  } elsif ($parts eq 'wedge+1') {
    $nmore += 3;
  } elsif ($parts eq 'diagonal-1') {
    $nmore += 3;
  } elsif ($parts eq 'octant+1' || $parts eq 'octant_up+1') {
    $nmore = ($nmore + 3) / 2;
  } elsif ($nhalf) {
    ### assert: $nmore % 2 == 1
    $nmore = ($nmore + 1) / 2;
  }

  return (\@depthbits, $ndepth, $nmore);
}

# ENHANCE-ME: step by the bits, not by X,Y
# ENHANCE-ME: tree_n_to_depth() by probe?
my @surround8_dx = (1, 0, -1, 0, 1, -1, 1, -1);
my @surround8_dy = (0, 1, 0, -1, 1, 1, -1, -1);
sub tree_n_children {
  my ($self, $n) = @_;
  ### LCornerTree tree_n_children(): $n

  if ($n < 0) {
    ### before n_start ...
    return;
  }
  my ($x,$y) = $self->n_to_xy($n);
  my @n_children;
  foreach my $i (0 .. 7) {
    if (defined (my $n_surround = $self->xy_to_n($x + $surround8_dx[$i],
                                                 $y + $surround8_dy[$i]))) {
      ### $n_surround
      if ($n_surround > $n) {
        my $n_parent = $self->tree_n_parent($n_surround);
        ### $n_parent
        if (defined $n_parent && $n_parent == $n) {
          push @n_children, $n_surround;
        }
      }
    }
  }
  ### @n_children
  # ### assert: scalar(@n_children) == 0 || scalar(@n_children) == 3
  return sort {$a<=>$b} @n_children;
}

sub tree_n_parent {
  my ($self, $n) = @_;
  ### LCornerTree tree_n_parent(): $n

  my $want_depth = $self->tree_n_to_depth($n);
  if (! defined $want_depth || ($want_depth -= 1) < 0) {
    return undef;
  }
  my ($x,$y) = $self->n_to_xy($n);
  ### $want_depth

  foreach my $i (0 .. 7) {
    if (defined (my $n_surround = $self->xy_to_n($x + $surround8_dx[$i],
                                                 $y + $surround8_dy[$i]))) {
      my $depth_surround = $self->tree_n_to_depth($n_surround);
      ### $n_surround
      ### $depth_surround
      if ($depth_surround == $want_depth) {
        return $n_surround;
      }
    }
  }
  ### no parent ...
  return undef;
}

sub tree_n_to_subheight {
  my ($self, $n) = @_;
  ### LCornerTree tree_n_to_subheight(): $n

  if ($n < 0)          { return undef; }
  if (is_infinite($n)) { return $n; }

  my ($depthbits, $ndepth, $nwidth) = _n0_to_depthbits($n, $self->{'parts'});
  $n -= $ndepth;      # remaining offset into row

  my $parts = $self->{'parts'};
  if ($parts eq 'octant+1') {
    if ($ndepth > 0 && $n == $nwidth-1) {
      return 0;  # last point in each row doesn't grow, except N=0
    }

  } elsif ($parts eq 'octant_up') {
    $n += $nwidth - 1;   # add to be second half of parts=1 row

  } elsif ($parts eq 'octant_up+1') {
    if ($n == 0) {
      return ($ndepth == 0
              ? undef  # N=0 is infinite
              : 0);    # first of any other row doesn't grow at all
    }
    $n += $nwidth - 3;    # add to be second half of parts=1 row

  } elsif ($parts eq 'wedge') {
    # swap row halves into style of parts=1
    my $noct = $nwidth/2;
    if ($n < $noct) {
      $n += $noct-1;
    } else {
      $n -= $noct;
    }

  } elsif ($parts eq 'wedge+1') {
    if ($ndepth > 0 && ($n == 0 || $n == $nwidth-1)) {
      return 0;  # first and last points don't grow, except N=0,N=1
    }
    # swap row halves into style of parts=1
    my $noct = $nwidth/2;
    if ($n < $noct) {
      $n += $noct-3;
    } else {
      $n -= $noct;
    }

  } elsif ($parts eq 'diagonal') {
    # swap row ends into style of parts=1
    my $noct = ($nwidth+1)/4;
    if ($n < $noct) {
      $n += $noct-1;
    } elsif ($n >= $nwidth - $noct) {
      $n -= ($nwidth - $noct);
    } else {
      $n -= $noct;
    }

  } elsif ($parts eq 'diagonal-1') {
    # swap row ends into style of parts=1
    if (@$depthbits < 2) {
      # N=0to3 depth=0,depth=1 on diagonals so infinite subtree
      return undef;
    }
    if ($n == 0 || $n == $nwidth-1) {
      # first and last of row are extras which never grow
      return 0;
    }
    my $noct = ($nwidth+3)/4;
    if ($n < $noct) {
      $n += $noct - 3;
    } elsif ($n >= $nwidth - $noct) {
      $n -= ($nwidth - $noct);
    } else {
      $n -= $noct;
    }

  } elsif ((my $numroots = $parts_to_numroots{$parts}) > 1) {
    # parts=2,3,4 reduce to parts=1 style
    ### assert: $nwidth % $numroots == 0
    $nwidth /= $numroots;
    $n %= $nwidth;    # Nrem in level, as per n_to_xy()
  }

  ### $depthbits
  ### $n

  foreach my $i (0 .. $#$depthbits) {
    ### $i
    ### N ternary digit: $n%3
    unless ($depthbits->[$i] ^= 1) {  # invert, taken Nrem digit at bit=1
      if (_divrem_mutate($n,3) != 1) {  # stop at lowest non-"1" ternary digit
        $#$depthbits = $i;  # truncate
        return digit_join_lowtohigh($depthbits, 2, $n*0);
      }
    }
  }
  return undef;  # Nrem all 1-digits, so on central infinite spine
}

# return ($quotient, $remainder)
sub _divrem {
  my ($n, $d) = @_;
  if (ref $n && $n->isa('Math::BigInt')) {
    my ($quot,$rem) = $n->copy->bdiv($d);
    if (! ref $d || $d < 1_000_000) {
      $rem = $rem->numify;  # plain remainder if fits
    }
    return ($quot, $rem);
  }
  my $rem = $n % $d;
  return (int(($n-$rem)/$d), # exact division stays in UV
          $rem);
}

# return $remainder, modify $n
# the scalar $_[0] is modified, but if it's a BigInt then a new BigInt is made
# and stored there, the bigint value is not changed
sub _divrem_mutate {
  my $d = $_[1];
  my $rem;
  if (ref $_[0] && $_[0]->isa('Math::BigInt')) {
    ($_[0], $rem) = $_[0]->copy->bdiv($d);  # quot,rem in array context
    if (! ref $d || $d < 1_000_000) {
      return $rem->numify;  # plain remainder if fits
    }
  } else {
    $rem = $_[0] % $d;
    $_[0] = int(($_[0]-$rem)/$d); # exact division stays in UV
  }
  return $rem;
}

#------------------------------------------------------------------------------
# levels

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0, $self->tree_depth_to_n_end(2**$level-1));
}
sub n_to_level {
  my ($self, $n) = @_;
  my $depth = $self->tree_n_to_depth($n);
  if (! defined $depth) { return undef; }
  my ($pow, $exp) = round_up_pow ($depth+1, 2);
  return $exp;
}

#------------------------------------------------------------------------------
1;
__END__

# sub _NOTWORKING__tree_n_children {
#   my ($self, $n) = @_;
#   my ($power, $exp) = round_down_pow (3*$n-2, 4);
#   $exp -= 1;
#   $power /= 4;
#
#   ### $power
#   ### $exp
#   ### pow base: 2 + 4*(4**$exp - 1)/3
#
#   $n -= ($power - 1)/3 * 4 + 2;
#   ### n less pow base: $n
#
#   my @levelbits = (2**$exp);
#   $power = 3**$exp;
#
#   # find the cumulative levelpoints total <= $n, being the start of the
#   # level containing $n
#   #
#   my $factor = 4;
#   while (--$exp >= 0) {
#     $power /= 3;
#     my $sub = 4**$exp * $factor;
#     ### $sub
#     # $power*$factor;
#     my $rem = $n - $sub;
#
#     ### $n
#     ### $power
#     ### $factor
#     ### consider subtract: $sub
#     ### $rem
#
#     if ($rem >= 0) {
#       $n = $rem;
#       push @levelbits, 2**$exp;
#       $factor *= 3;
#     }
#   }
#
#   $n += $factor;
#   if (1) {
#     return ($n,$n+1,$n+2);
#   } else {
#     return $n,$n+1,$n+2;
#   }
# }


# n_to_xy() by len.
#
# my $x = $zero;
# my $y = $zero;
# my $len = 1 + $zero;
# my $state = 0;
# my (@xbits, @ybits);
# foreach my $depthbit (reverse @$depthbits) { # low to high
#   my $ndigit = $depthbit && (shift @ndigits || 0);  # low to high
#   ### $ndigit
#
#   if ($ndigit == 0) {
#     ($x,$y) = ($len+$y,$len-1-$x);   # rotate +90
#   } elsif ($ndigit == 1) {
#     $x += $len;
#     $y += $len;
#   } else { # $ndigit == 3
#     ($x,$y) = ($len-1-$y,$len+$x);   # rotate -90
#   }
#   $len *= 2;
# }
# ### assert: @ndigits == 0
#
# if ($quad & 1) {
#   ($x,$y) = (-1-$y,$x); # rotate +90
# }
# if ($quad & 2) {
#   $x = -1-$x; # rotate +180
#   $y = -1-$y;
# }
#
# ### final: "$x,$y"
# return $x,$y;

#          18 17
# 14 13 12 11 16
# 15  6  5 10
#  3  2  4  9
#  0  1  7  8

=for stopwords eg Ryde Math-PlanePath-Toothpick Ulam Warburton Ulam-Warburton Nstart OEIS ie Octant octants

=head1 NAME

Math::PlanePath::LCornerTree -- cellular automaton growing at exposed corners

=head1 SYNOPSIS

 use Math::PlanePath::LCornerTree;
 my $path = Math::PlanePath::LCornerTree->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is the pattern of a cellular automaton growing by 3 cells at exposed
corners.  Points are numbered by a breadth-first tree traversal and
anti-clockwise at each node.  The default is four quadrants starting from
four initial cells N=0 to N=3,

    68  67                          66  65      4
    69  41  40  39  38  35  34  33  32  64      3
        42  20  19  37  36  18  17  31  ...     2
        43  21   8   7   6   5  16  30          1
        44  45   9   1   0   4  28  29     <- Y=0
        47  46  10   2   3  15  63  62         -1
        48  22  11  12  13  14  27  61         -2
        49  23  24  54  55  25  26  60         -3
    70  50  51  52  53  56  57  58  59  75     -4
    71  72                          73  74     -5
                         ^
    -5  -4  -3  -2  -1  X=0  1   2   3   4

The growth rule is a cell which is an exposed corner grows by the three
cells surrounding that corner.  So

    depth=0   depth=1         depth=2             depth=3

                                              d d d d d d d d
                                               \| |/   \| |/
                            c c     c c       d-c c-d d-c c-d
                             \|     |/           \|     |/
              b b b b       c-b b b b-c       d-c-b b b b-c-d
               \| |/           \| |/           /|  \| |/  |\
    a a       b-a a-b         b-a a-b         d d b-a a-b d d
         ->             ->               ->
    a a       b-a a-b         b-a a-b         d d b-a a-b d d
               /| |\           /| |\               /| |\  |/
              b b b b       c-b b b b-c       d c-b b b b-c-d
                             /|     |\           /|     |\
                            c c       c       d-c c-d d-c c-d
                                               /| |\   /| |\
                                              d d d d d d d d

"a" is the first cell in each quadrant and grows into the three "b" around
each.  Then for the "b" cells only the corner ones are exposed corners and
they grow to the "c" cells.  Those "c" cells are then all exposed corners
and give a set of 36 "d" cells.  Of those "d"s only the corners are exposed
corners for the next "e" row.

Grouping the three children of each corner shows the pattern

=cut

# this image generated by tools/lcorner-tree-bricks.pl

=pod

    +-----------------------+
    |     |     |     |     |
    |  +-----+  |  +-----+  |
    |  |     |  |  |     |  |
    |--|  +-----+-----+  |--|
    |  |  |     |     |  |  |
    |  +--|  +--+--+  |--+  |
    |     |  |  |  |  |     |
    |-----+--+--+--+--+-----|
    |     |  |  |  |  |     |
    |  +--|  +--+--+  |--+  |
    |  |  |     |     |  |  |
    |--|  +-----+-----+  |--|
    |  |     |  |  |     |  |
    |  +-----+  |  +-----+  |
    |     |     |     |     |
    +-----------------------+

In general the number of cells gained in each row is

    Nwidth = 4 * 3^count1bits(depth)

So for example depth=3 binary "11" has 2 1-bits so cells=4*3^2=36.  Adding
such powers-of-3 up to a depth=2^k gives a power-of-4 total square area.

Each side part turns by 90 degrees at its corner, so the plane is filled in
a self-similar style turning into each side quarter.  This is an attractive
way to fill the plane by a tree structure.

    +----------------+
    |       |        |
    |  ^    |    ^   |
    |   \   |   /    |
    |    \  |  /     |
    |       |        |
    |-------+--------|
    |       |        |
    |    ^  |  \     |
    |   /   |   \    |
    |  /    |    v   |
    | /     |        |
    +----------------+

See also L<Math::PlanePath::LCornerReplicate> for a digit-based approach to
the replication.

=head2 Toothpicks

The points can be regarded as the centres of toothpicks oriented diagonally
and growing at exposed endpoints.

            ..       ..
        |     \     /
      2 |      6   5         parts=1 (per below) as toothpicks
        |       \ /
        |        .
        | \     / \
      1 |  3   2   4
        |   \ /     \
        |    .       ..
        |   / \
    Y=0 |  0   1
        | /     \
        +-------------
         X=0   1   2

Point N=0 is reckoned as a diagonal toothpick and the three N=1,2,3 grow
from its exposed end.  At the next row another three grow from the exposed
end of N=2.  Only an exposed end grows.  If two toothpick ends touch then
they don't grow.

The toothpicks are oriented on the leading diagonal for "even" X=Y mod 2 and
on the opposite diagonal for "odd" points X!=Y mod 2.  A rotation by 45
degrees can be applied to make them horizontal and vertical instead.

=head2 One Quadrant

Option C<parts =E<gt> '1'> confines the pattern to the first quadrant.  This
is a single copy of the repeating part which is in each of the four
quadrants of the full pattern.

=cut

# math-image --path=LCornerTree,parts=1, --all --output=numbers --size=50x5

=pod

    parts => "1"

     4  |              18  17
     3  |  14  13  12  11  16
     2  |  15   6   5  10
     1  |   3   2   4   9
    Y=0 |   0   1   7   8
        +---------------------
          X=0   1   2   3   4

=head2 Half Plane

Option C<parts =E<gt> '2'> confines the tree to the upper half plane
C<YE<gt>=0>, giving two symmetric parts above the X axis.

=cut

# math-image --path=LCornerTree,parts=2, --all --output=numbers --size=50x5

=pod

    parts => "2"

    36  35                          34  33        4
    37  27  26  25  24  21  20  19  18  32        3
        28  12  11  23  22  10   9  17            2
        29  13   6   5   4   3   8  16            1
        30  31   7   1   0   2  14  15        <- Y=0
    --------------------------------------
    -5  -4  -3  -2  -1  X=0  1   2   3   4

=head2 Three Parts

Option C<parts =E<gt> '3'> is three replications arranged in a corner down and
left.

=cut

# math-image --path=LCornerTree,parts=3, --all --output=numbers --size=50x10

=pod

    parts => "3"

    55  54                          50  49        4
    56  43  42  41  40  28  27  26  25  48        3
        44  19  18  39  29  14  13  24            2
        45  20  10   9   5   4  12  23            1
        46  47  11   2   0   3  21  22        <- Y=0
    ------------------+  1   8  38  37           -1
                      |  6   7  17  36           -2
                      | 30  15  16  35
                      | 31  32  33  34  53
                      |             51  52
                         ^
    -5  -4  -3  -2  -1  X=0  1   2   3   4

This is similar to the way the tree grows from a power-of-2 corner
X=2^k,Y=2^k, but here the numbering is the centre quadrant first, then the
lower, then the left.  (Whereas at a corner it would be clockwise around.)

=head2 One Octant

Option C<parts =E<gt> 'octant'> confines the pattern to the first eighth of
the plane.  This is a single side of the eight-way symmetry in the full
pattern.

=cut

# math-image --path=LCornerTree,parts=octant --all --output=numbers --size=40x8

=pod

    parts => "octant"

     7  |                       35
     6  |                    21 34
     5  |                 16 20 33
     4  |              11 15 31 32
     3  |            9 10 14 30 29
     2  |         4  8 12 13 19 28
     1  |      2  3  7 22 17 18 27
    Y=0 |   0  1  5  6 23 24 25 26
        +--------------------------
          X=0  1  2  3  4  5  6  7

The points are numbered in the same sequence as the parts=1 quadrant, but
with those above the X=Y diagonal omitted.  This means each N on the X=Y
diagonal is the last of the row.

=head2 One Octant Plus One

Option C<parts =E<gt> 'octant+1'> confines the pattern to the first eighth
plus an additional diagonal above the eighth.  This means each point on the
diagonal has 3 children but the children above the diagonal don't grow any
further.

=cut

# math-image --path=LCornerTree,parts=octant+1 --all --output=numbers --size=36x9

=pod

    parts => "octant+1"

     7  |                    42 41
     6  |                 27 26 40
     5  |              21 20 25 39
     4  |           15 14 19 37 38
     3  |        12 11 13 18 36 35
     2  |      6  5 10 16 17 24 34
     1  |   3  2  4  9 28 22 23 33
    Y=0 |   0  1  7  8 29 30 31 32
        +--------------------------
          X=0  1  2  3  4  5  6  7

=head2 Upper Octant

Option C<parts =E<gt> 'octant_up'> confines the pattern to the upper eighth
of the first quadrant.

=cut

# math-image --path=LCornerTree,parts=octant_up --all --output=numbers --size=50x8

=pod

    parts => "octant_up"

     7  |  31 30 29 28 25 24 23 22
     6  |  32 20 19 27 26 18 17
     5  |  33 21 15 14 13 12
     4  |  34 35 16 11 10
     3  |   8  7  6  5
     2  |   9  4  3
     1  |   2  1
    Y=0 |   0
        +--------------------------
          X=0  1  2  3  4  5  6  7

The points are numbered in the same sequence as the parts=1 quadrant, but
with those below the X=Y diagonal omitted.  This means each N on the X=Y
diagonal is the first of the row.

=head2 Upper Octant Plus One

Option C<parts =E<gt> 'octant_up+1'> confines the pattern to the upper
eighth of the first quadrant, plus an extra diagonal below.

=cut

# math-image --path=LCornerTree,parts=octant_up+1 --all --output=numbers --size=35x8

=pod

    parts => "octant_up+1"

     7  |  38 37 36 35 32 31 30 29
     6  |  39 26 25 34 33 24 23 28
     5  |  40 27 20 19 18 17 22
     4  |  41 42 21 15 14 16
     3  |  11 10  9  8 13
     2  |  12  6  5  7
     1  |   3  2  4
    Y=0 |   0  1
        +--------------------------
          X=0  1  2  3  4  5  6  7

This corresponds to the parts=octant+1 above, but the numbering is still
clockwise so goes from the diagonal to the axis whereas parts=octant+1 goes
from the axis to the diagonal.

=head2 Wedge

Option C<parts =E<gt> 'wedge'> confines the pattern to a wedge -Y-1 E<lt>= X
E<lt>= Y and YE<gt>=0.

=cut

# math-image --path=LCornerTree,parts=wedge --all --output=numbers --size=80x8

=pod

    parts => "wedge"

    71 70 69 68 65 64 63 62 53 52 51 50 47 46 45 44       7
       43 42 67 66 41 40 61 54 37 36 49 48 35 34          6
          33 32 31 30 39 60 55 38 27 26 25 24             5
             23 22 29 58 59 56 57 28 21 20                4
                19 18 17 16 13 12 11 10                   3
                    9  8 15 14  7  6                      2
                       5  4  3  2                         1
                          1  0                           Y=0
    -----------------------------------------------
    -8 -7 -6 -5 -4 -3 -2 -1  0  1  2  3  4  5  6  7

The points are numbered in the same sequence as the full parts=4 pattern,
but restricted to the wedge portion.  This means each N on the right-hand
X=Y diagonal is the first of the row and each N on the X=-1-Y left-hand
diagonal is the last of the row.

In this arrangement even N falls on "even" points X=Y mod 2.  Odd N falls on
"odd" points X!=Y mod 2.

     O  E  O  E  O  E  O  E           3
        O  E  O  E  O  E              2
           O  E  O  E                 1
              O  E               <-  Y=0

                 ^
    -4 -3 -2 -1 X=0 1  2  3

The odd/even is true of N=0 and N=1 and then for further points it's true
due to the way the pattern repeats in 2^k rows.

    --------------   \  Y=2*2^k-1
     \ 3 /  \ 1 /    |
      \ /  2 \ /     /  Y=2^k
       --------      \  Y=2^k-1
        \base/       |
         \  /        /  Y=0

The base part Y=0 to Y=2^k-1 repeats in block 1 and block 3.  The middle
block 2 is also a repeat, less 2 points on the diagonals, but the right half
of the base is rotated +90 degrees and the left half of the base rotated -90
degrees to make the upside-down wedge.

parts=2 and parts=4 forms also have an even number of points in each row but
they don't have N even on X,Y even the way the wedge does.  That's because
the numbering of parts=2 and parts=4 means each row begins on the "ragged"
edge of the pattern which may be X,Y odd or even, whereas each wedge row
begins on the X=Y diagonal which is always X,Y even.

In terms of toothpick triplets described above (L</Toothpicks>), the wedge
corresponds to an initial two toothpicks at right angles then growing into a
single quadrant, when rotated -45 degrees to have the toothpicks vertical
and horizontal.  Toothpicks on the edges of the quadrant are restricted to 2
children and all other open ends have 3.

    |              parts => "wedge"
    5              as toothpicks
    |
    .--4--
    |     |
    1     3
    |     |
    +--0--.--2--

=head2 Wedge Plus One

Option C<parts =E<gt> 'wedge+1'> confines the pattern to a wedge -Y-2 E<lt>=
X E<lt>= Y+1 and YE<gt>=0.  This is the parts=wedge above with an extra
diagonal on each side.

=cut

# math-image --path=LCornerTree,parts=wedge+1 --all --output=numbers --size=80x8

=pod

    parts => "wedge"

    84 83 82 81 78 77 76 75 66 65 64 63 60 59 58 57        7
    85 54 53 80 79 52 51 74 67 48 47 62 61 46 45 56        6
       55 42 41 40 39 50 73 68 49 36 35 34 33 44           5
          43 30 29 38 71 72 69 70 37 28 27 32              4
             31 24 23 22 21 18 17 16 15 26                 3
                25 12 11 20 19 10  9 14                    2
                   13  6  5  4  3  8                       1
                       7  1  0  2                         Y=0
    -----------------------------------------------
    -8 -7 -6 -5 -4 -3 -2 -1  0  1  2  3  4  5  6  7

As per parts=wedge each tree row has an even number of points and like that
form odd/even N falls on even/odd X,Y.  Here the first N of each tree row is
an "odd" point X=Y+1 so it's even N on odd X,Y and odd N on even X,Y.  The
initial N=0 and N=1 are exceptions to this rule.

=head2 Diagonal

Option C<parts =E<gt> 'diagonal'> confines the pattern to a diagonal
half-plane XE<gt>=Y-1,

=cut

# math-image --path=LCornerTree,parts=diagonal --all --output=numbers --size=80x10

=pod

    parts => "diagonal"

    35  34  33  32  29  28  27  26         3
      \  |   | /      \  |   | /
        16  15--31  30--14  13--25         2
          \  |           | /
             9   8   7   6--12--24         1
               \ |   | /     | \
                 2   1---5  22  23        Y=0

                     0 - 4  21  20        -1
                       \     | /
                         3--11--19        -2
                           \
                            10--18        -3
                              \
                                17        -4
                     ^
    -4  -3  -2  -1  X=0  1  2  3  4  5  6  7

=head2 Diagonal One

Option C<parts =E<gt> 'diagonal-1'> starts from a single point and is
confined to a diagonal half-plane XE<gt>=Y,

=cut

# math-image --path=LCornerTree,parts=diagonal-1 --all --output=numbers --size=80x10

=pod

    parts => "diagonal"

    41  40  39  38  35  34  33  32         4
      \  |   | /      \  |   | /
    42--20  19--37  36--18  17--31         3
          \  |           | /
        21--11  10   9   8--16--30         2
               \ |   | /    | \
            12---3   2---7  28  29         1
                 | /
                 0---1---6  27  26     <- Y=0
                     |  \     | /
                     4   5--15--25        -1
                         | \
                        13  14--24        -2
                             | \
                            22  23        -3
                 ^
    -3  -2  -1  X=0  1   2   3   4

In this pattern the edge points such as N=1,5,14 all have 3 children, so
there's always 0 or 3 children as per the full pattern.  The square section
beginning N=2 corresponds to the origin in the full pattern, so the initial
single point here makes it one row later.

As toothpicks this pattern is OEIS A183148 half-plane of toothpick triplets
by Omar Pol.

=over

L<http://oeis.org/A183148>

=back

Turning the pattern +45 degrees and drawing toothpicks per L</Toothpicks>
above gives

                   |
                   8
                   |
            ---8---.---7---
           |       |       |
           9       3       6
           |       |       |
    --10---.---2---.---1---.---5---
           |       |       |
          11       0       4
           |       |       |

    --------------------------------

=cut

#              .
#              4
#          . 4 . 4 .
#              3
#      .   . 3 . 3 .   .
#      4   3   2   3   4
#  . 4 . 3 . 2 . 2 . 3 . 4 .
#      4   3   1   3   4
#  -----------------------

=pod

=head2 Ulam Warburton

Taking just the non-leaf nodes gives the pattern of the Ulam-Warburton
cellular automaton oriented at 45-degrees as per
L<Math::PlanePath::UlamWarburtonQuarter> and using 2x2 blocks for each cell.

=cut

# math-image --path=LCornerTree --values=PlanePathCoord,coordinate_type=NumChildren,planepath=LCornerTree  --text --size=30x31
#
# math-image --path=LCornerTree,parts=1 --values='PlanePathCoord,coordinate_type=NumChildren,planepath="LCornerTree,parts=1"' --text --size=17x17

=pod

    |  **  **  **  **        parts=>1  non-leaf cells
    |  **  **  **  **
    |    **      **
    |    **      **
    |  **  **  **  **
    |  **  **  **  **
    |        **
    |        **
    |  **  **  **  **
    |  **  **  **  **
    |    **      **
    |    **      **
    |  **  **  **  **
    |  **  **  **  **
    | *
    +----------------

parts=4 gives the pattern of L<Math::PlanePath::UlamWarburton> but again
turned 45 degrees and in 2x2 blocks.

=pod

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::LCornerTree-E<gt>new ()>

=item C<$path = Math::PlanePath::LCornerTree-E<gt>new (parts =E<gt> $str)>

Create and return a new path object.  The C<parts> option (a string) can be

    "4"         the default
    "3"
    "2"
    "1"
    "octant"
    "octant+1"
    "octant_up"
    "octant_up+1"
    "wedge"
    "wedge+1"
    "diagonal"
    "diagonal-1"

=back

=head2 Tree Descriptive Methods

=over

=item C<@nums = $path-E<gt>tree_num_children_list()>

Return a list of the possible number of children at the nodes of C<$path>.
This is the set of possible return values from C<tree_n_num_children()>.
This varies with the C<parts> option,

           parts               tree_num_children_list()
           -----               ------------------------
    4, 3, 2, 1             \
    octant+1, octant_up+1,  |         0,    3
    wedge+1, diagonal-1    /

    octant, octant_up      \          0, 2, 3
    wedge, diagonal        /

X<3-tree>For parts=4,3,2,etc each point has either 0 or 3 children.  Such a
tree is sometimes called a "3-tree".  For a corner cell the children are the
three cells adjacent to it turned "on" at the next depth.  A non-corner has
no children.

For parts=octant etc the points on the X=Y diagonal have only 2 children
since the pattern is confined to on or below that diagonal.  All other
points have either 0 or 3 as per the full patterns.

=item C<$num = $path-E<gt>tree_num_roots ()>

Return the number of root nodes in C<$path>.  This varies with the C<parts>
option,

    parts                                     num_roots()
    -----                                     -----------
      4                                           4
      3                                           3
      2                                           2
      1                                           1
    octant, octant+1, octant_up, octant_up+1      1
    wedge, wedge+1                                2
    diagonal                                      3
    diagonal-1                                    1

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, tree_depth_to_n_end(2**$level - 1)>.

=back

=head1 OEIS

This cellular automaton is in Sloane's Online Encyclopedia of Integer
Sequences as follows, and drawings by Omar Pol.

=over

L<http://oeis.org/A160410> (etc)

=back

    parts=4 (the default)
      A160410   total cells at given depth, tree_depth_to_n()
      A161411   added cells at given depth, 4*3^count1bits(n)

      http://www.polprimos.com/imagenespub/polca023.jpg
      http://www.polprimos.com/imagenespub/polca024.jpg

    parts=3
      A160412   total cells at given depth, tree_depth_to_n()
      A162349   added cells at given depth, 3*3^count1bits(n)

      http://www.polprimos.com/imagenespub/polca013.jpg
      http://www.polprimos.com/imagenespub/polca027.jpg
      http://www.polprimos.com/imagenespub/polca029.jpg

    parts=1
      A130665   total cells at given depth, from depth=1 onwards
                  cumulative 3^count1bits, tree_depth_to_n(d+1)
      A048883   added cells at given depth, 3^count1bits(n)

      http://www.polprimos.com/imagenespub/polca011.jpg
      http://www.polprimos.com/imagenespub/polca012.jpg
      http://www.polprimos.com/imagenespub/polca014.jpg

    parts=octant,octant_up
      A162784   added cells at given depth, (3^count1bits(n) + 1)/2

    parts=wedge
      A151712   added cells at given depth, 3^count1bits(n) + 1

      http://www.polprimos.com/imagenespub/polca032.jpg

    parts=diagonal-1
      A183148   total cells at given depth, tree_depth_to_n()
      A183149   added cells at given depth

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::LCornerReplicate>,
L<Math::PlanePath::UlamWarburton>,
L<Math::PlanePath::ToothpickTree>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2015 Kevin Ryde

This file is part of Math-PlanePath-Toothpick.

Math-PlanePath-Toothpick is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Math-PlanePath-Toothpick is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.

=cut
