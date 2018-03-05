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



# points singles A052548 2^n + 2
# points doubles A000918 2^n - 2
# points triples A028243 3^(n-1) - 2*2^(n-1) + 1     cf A[k] = 2*3^(k-1) - 2*2^(k-1)

# T(3*N)   = (w+1)*T(N)                dir(N)=w^(2*count1digits)
# T(3*N+1) = (w+1)*T(N) + 1*dir(N)
# T(3*N+2) = (w+1)*T(N) + w*dir(N)

# T(0*3^k + N)  =             T(N)
# T(1*3^k + N)  = 2^k   + w^2*T(N)    # rotate and offset
# T(2*3^k + N)  = w*2^k +     T(N)    # offset only



package Math::PlanePath::TerdragonCurve;
use 5.004;
use strict;
use List::Util 'first';
use List::Util 'min'; # 'max'
*max = \&Math::PlanePath::_max;

use Math::PlanePath;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest',
  'xy_is_even';
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'digit_join_lowtohigh',
  'round_up_pow';

use vars '$VERSION', '@ISA';
$VERSION = 126;
@ISA = ('Math::PlanePath');

use Math::PlanePath::TerdragonMidpoint;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;
use constant parameter_info_array =>
  [ { name      => 'arms',
      share_key => 'arms_6',
      display   => 'Arms',
      type      => 'integer',
      minimum   => 1,
      maximum   => 6,
      default   => 1,
      width     => 1,
      description => 'Arms',
    } ];

{
  my @x_negative_at_n = (undef, 13, 5, 5, 6, 7, 8);
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n[$self->{'arms'}];
  }
}
{
  my @y_negative_at_n = (undef, 159, 75, 20, 11, 9, 10);
  sub y_negative_at_n {
    my ($self) = @_;
    return $y_negative_at_n[$self->{'arms'}];
  }
}
sub dx_minimum {
  my ($self) = @_;
  return ($self->{'arms'} == 1 ? -1 : -2);
}
use constant dx_maximum => 2;
use constant dy_minimum => -1;
use constant dy_maximum => 1;

sub _UNDOCUMENTED__dxdy_list {
  my ($self) = @_;
  return ($self->{'arms'} == 1
          ? Math::PlanePath::_UNDOCUMENTED__dxdy_list_three()
          : Math::PlanePath::_UNDOCUMENTED__dxdy_list_six());
}
{
  my @_UNDOCUMENTED__dxdy_list_at_n = (undef, 4, 9, 13, 7, 8, 5);
  sub _UNDOCUMENTED__dxdy_list_at_n {
    my ($self) = @_;
    return $_UNDOCUMENTED__dxdy_list_at_n[$self->{'arms'}];
  }
}
use constant absdx_minimum => 1;
use constant dsumxy_minimum => -2; # diagonals
use constant dsumxy_maximum => 2;
use constant ddiffxy_minimum => -2;
use constant ddiffxy_maximum => 2;

# arms=1 curve goes at 0,120,240 degrees
# arms=2 second +60 to 60,180,300 degrees
# so when arms==1 dir maximum is 240 degrees
sub dir_maximum_dxdy {
  my ($self) = @_;
  return ($self->{'arms'} == 1
          ? (-1,-1)    # 0,2,4 only           South-West
          : ( 1,-1));  # rotated to 1,3,5 too South-East
}

use constant turn_any_straight => 0; # never straight


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'arms'} = max(1, min(6, $self->{'arms'} || 1));
  return $self;
}

my @dir6_to_si = (1,0,0, -1,0,0);
my @dir6_to_sj = (0,1,0, 0,-1,0);
my @dir6_to_sk = (0,0,1, 0,0,-1);

sub n_to_xy {
  my ($self, $n) = @_;
  ### TerdragonCurve n_to_xy(): $n

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

  foreach my $digit (digit_split_lowtohigh($n,3)) {
    ### at: "$i,$j,$k   side $si,$sj,$sk"
    ### $digit

    if ($digit == 1) {
      ($i,$j,$k) = ($si-$j, $sj-$k, $sk+$i);  # rotate +120 and add
    } elsif ($digit == 2) {
      $i -= $sk;   # add rotated +60
      $j += $si;
      $k += $sj;
    }

    # add rotated +60
    ($si,$sj,$sk) = ($si - $sk,
                     $sj + $si,
                     $sk + $sj);
  }

  ### final: "$i,$j,$k   side $si,$sj,$sk"
  ### is: (2*$i + $j - $k).",".($j+$k)

  return (2*$i + $j - $k, $j+$k);
}


# all even points when arms==6
sub xy_is_visited {
  my ($self, $x, $y) = @_;
  if ($self->{'arms'} == 6) {
    return xy_is_even($self,$x,$y);
  } else {
    return defined($self->xy_to_n($x,$y));
  }
}

sub xy_to_n {
  return scalar((shift->xy_to_n_list(@_))[0]);
}
sub xy_to_n_list {
  my ($self, $x,$y) = @_;
  ### TerdragonCurve xy_to_n_list(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);
  {
    # nothing at an odd point, and trap overflows in $x+$y dividing out b
    my $sum = abs($x) + abs($y);
    if (is_infinite($sum)) { return $sum; }  # infinity
    if ($sum % 2) { return; }
  }

  if ($x==0 && $y==0) {
    return 0 .. $self->{'arms'}-1;
  }

  my $arms_count = $self->arms_count;
  my $zero = ($x * 0 * $y); # inherit bignum 0

  my @n_list;
  foreach my $d (0,1,2) {
    my ($ndigits,$arm) = _xy_d_to_ndigits_and_arm($x,$y,$d);
    next if $arm >= $arms_count;
    my $odd = ($arm & 1);
    if ($odd) {
      @$ndigits = (map {2-$_} @$ndigits);
      ### flip to: $ndigits
    }
    push @n_list,
      (digit_join_lowtohigh($ndigits, 3, $zero) + $odd) * $arms_count + $arm;
  }

  ### @n_list
  return sort {$a<=>$b} @n_list;
}

my @x_to_digit = (0, 2, 1);  # digit = -X mod 3
my @digit_to_x = ([0,2,1],  [0,-1,-2],  [0,-1, 1]);
my @digit_to_y = ([0,0,1],  [0, 1, 0],  [0,-1,-1]);

# $d = 0,1,2 for segment leaving $x,$y at direction $d*120 degrees.
# For odd arms the digits are 0<->2 reversals.
sub _xy_d_to_ndigits_and_arm {
  my ($x,$y, $d) = @_;
  my @ndigits;
  my $arm;
  for (;;) {
    ### at: "$x,$y d=$d"
    if ($x==0 && $y==0) { $arm = 2*$d; last; }
    if ($d==0 && $x==-2 && $y==0) { $arm = 3; last; }
    if ($d==2 && $x==1  && $y==1) { $arm = 1; last; }
    if ($d==1 && $x==1  && $y==-1) { $arm = 5; last; }

    my $digit = $x_to_digit[$x%3];
    push @ndigits, $digit;

    if ($digit == 1) { $d = ($d-1) % 3; }
    $x -= $digit_to_x[$d]->[$digit];
    $y -= $digit_to_y[$d]->[$digit];

    ### $digit
    ### new d: $d
    ### subtract: "$digit_to_x[$d]->[$digit],$digit_to_y[$d]->[$digit] to $x,$y"

    # ### assert: ($x+$y) % 2 == 0
    # ### assert: $x % 3 == 0
    # ### assert: ($y-$x/3) % 2 == 0
    ($x,$y) = (($x+$y)/2,    # divide b = w6+1
               ($y-$x/3)/2);
  }
  ### $arm
  ### @ndigits
  return (\@ndigits, $arm);
}
# x+y*w3
# (x-y)+y*w3
# x/2 + y*sqrt3i/2
# sqrt3i/2 = w3+1/2
# x/2 + y*(w3+1/2) == 1/2*(x+y) + y*w3
# a = x+y = (x+3*y)/2
# GP-Test  my(x=0,y=0); (-x)%3 == 0
# GP-Test  my(x=2,y=0); (-x)%3 == 1
# GP-Test  my(x=1,y=1); (-x)%3 == 2

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
  ### TerdragonCurve rect_to_n_range(): "$x1,$y1  $x2,$y2"
  my $xmax = int(max(abs($x1),abs($x2)));
  my $ymax = int(max(abs($y1),abs($y2)));
  return (0,
          ($xmax*$xmax + 3*$ymax*$ymax + 1)
          * 2
          * $self->{'arms'});
}

# direction
#
my @dir6_to_dx   = (2, 1,-1,-2, -1, 1);
my @dir6_to_dy   = (0, 1, 1, 0, -1,-1);
my @digit_to_nextturn = (2,-2);
sub n_to_dxdy {
  my ($self, $n) = @_;
  ### n_to_dxdy(): $n

  if ($n < 0) {
    return;  # first direction at N=0
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  my $int = int($n);  # integer part
  $n -= $int;         # fraction part

  # initial direction from arm
  my $dir6 = _divrem_mutate ($int, $self->{'arms'});

  my @ndigits = digit_split_lowtohigh($int,3);
  $dir6 += 2 * scalar(grep {$_==1} @ndigits);  # count 1s for total turn
  $dir6 %= 6;
  my $dx = $dir6_to_dx[$dir6];
  my $dy = $dir6_to_dy[$dir6];

  if ($n) {
    # fraction part

    # find lowest non-2 digit, or zero if all 2s or no digits at all
    $dir6 += $digit_to_nextturn[ first {$_!=2} @ndigits, 0];
    $dir6 %= 6;
    $dx += $n*($dir6_to_dx[$dir6] - $dx);
    $dy += $n*($dir6_to_dy[$dir6] - $dy);
  }
  return ($dx, $dy);
}


#-----------------------------------------------------------------------------
# eg. arms=5 0 .. 5*3^k    step by 5s
#            1 .. 5*3^k+1  step by 5s
#            4 .. 5*3^k+4  step by 5s
#
sub level_to_n_range {
  my ($self, $level) = @_;
  return (0,  (3**$level + 1) * $self->{'arms'} - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  _divrem_mutate ($n, $self->{'arms'});
  my ($pow, $exp) = round_up_pow ($n, 3);
  return $exp;
}

#-----------------------------------------------------------------------------
# right boundary N

# mixed radix binary, ternary
# no 11, 12, 20
# 11 -> 21, including low digit
# run of 11111 becomes 22221
# low to high 1 or 0 <- 0   cannot 20 can 10 00
#             2 or 0 <- 1   cannot 11 can 21 01
#             2 or 0 <- 2   cannot 12 can 02 22
sub _UNDOCUMENTED__right_boundary_i_to_n {
  my ($self, $i) = @_;
  my @digits = _digit_split_mix23_lowtohigh($i);
  for ($i = $#digits; $i >= 1; $i--) {   # high to low
    if ($digits[$i] == 1 && $digits[$i-1] != 0) {
      $digits[$i] = 2;
    }
  }
  return digit_join_lowtohigh(\@digits, 3, $i*0);

  # {
  #   for (my $i = 0; $i < $#digits; $i++) {   # low to high
  #     if ($digits[$i+1] == 1 && ($digits[$i] == 1 || $digits[$i] == 2)) {
  #       $digits[$i+1] = 2;
  #     }
  #   }
  #   return digit_join_lowtohigh(\@digits,3);
  # }
}

# Return a list of digits, low to high, which is a mixed radix
# representation low digit ternary and the rest binary.
sub _digit_split_mix23_lowtohigh {
  my ($n) = @_;
  if ($n == 0) {
    return ();
  }
  my $low = _divrem_mutate($n,3);
  return ($low, digit_split_lowtohigh($n,2));
}

{
  # disallowed digit pairs $disallowed[high][low]
  my @disallowed;
  $disallowed[1][1] = 1;
  $disallowed[1][2] = 1;
  $disallowed[2][0] = 1;

  sub _UNDOCUMENTED__n_segment_is_right_boundary {
    my ($self, $n) = @_;
    if (is_infinite($n)) { return 0; }
    unless ($n >= 0) { return 0; }
    $n = int($n);

    # no boundary when arms=6, right boundary is only in arm 0
    {
      my $arms = $self->{'arms'};
      if ($arms == 6) { return 0; }
      if (_divrem_mutate($n,$arms)) { return 0; }
    }

    my $prev = _divrem_mutate($n,3);
    while ($n) {
      my $digit = _divrem_mutate($n,3);
      if ($disallowed[$digit][$prev]) {
        return 0;
      }
      $prev = $digit;
    }
    return 1;
  }
}

#-----------------------------------------------------------------------------
# left boundary N


# mixed 0,1, 2, 10, 11, 12, 100, 101, 102, 110, 111, 112, 1000, 1001, 1002, 1010, 1011, 1012, 1100, 1101, 1102,
# vals  0,1,12,120,121,122,1200,1201,1212,1220,1221,1222,12000,12001,12012,12120,12121,12122,12200,12201,12212,
{
  my @_UNDOCUMENTED__left_boundary_i_to_n = ([0,2],  # 0
                                             [0,2],  # 1
                                             [1,2]); # 2
  sub _UNDOCUMENTED__left_boundary_i_to_n {
    my ($self, $i, $level) = @_;
    ### _UNDOCUMENTED__left_boundary_i_to_n(): $i
    ### $level

    if (defined $level && $level < 0) {
      if ($i <= 2) {
        return $i;
      }
      $i += 2;
    }

    my @digits = _digit_split_mix23_lowtohigh($i);
    ### @digits

    if (defined $level) {
      if ($level >= 0) {
        if (@digits > $level) {
          ### beyond given level ...
          return undef;
        }
        # pad for $level, total $level many digits
        push @digits, (0) x ($level - scalar(@digits));
      } else {
        ### union all levels ...
        pop @digits;
        if ($digits[-1]) {
          push @digits, 0;     # high 0,1  or 0,2 when i=3
        } else {
          $digits[-1] = 1;     # high   1
        }
      }
    } else {
      ### infinite curve, an extra high 0 ...
      push @digits, 0;
    }
    ### @digits

    my $prev = $digits[0];
    foreach my $i (1 .. $#digits) {
      $prev = $digits[$i] = $_UNDOCUMENTED__left_boundary_i_to_n[$prev][$digits[$i]];
    }
    ### ternary: @digits
    return digit_join_lowtohigh(\@digits, 3, $i*0);
  }
}

{
  # disallowed digit pairs $disallowed[high][low]
  my @disallowed;
  $disallowed[0][2] = 1;
  $disallowed[1][0] = 1;
  $disallowed[1][1] = 1;

  sub _UNDOCUMENTED__n_segment_is_left_boundary {
    my ($self, $n, $level) = @_;
    ### _UNDOCUMENTED__n_segment_is_left_boundary(): $n
    ### $level

    if (is_infinite($n)) { return 0; }
    unless ($n >= 0) { return 0; }
    $n = int($n);

    if (defined $level && $level == 0) {
      ### level 0 curve, N=0 is only segment: ($n == 0)
      return ($n == 0);
    }

    {
      my $arms = $self->{'arms'};
      if ($arms == 6) {
        return 0;
      }
      my $arm = _divrem_mutate($n,$arms);
      if ($arm != $arms-1) {
        return 0;
      }
    }

    my $prev = _divrem_mutate($n,3);
    if (defined $level) { $level -= 1; }

    for (;;) {
      if (defined $level && $level == 0) {
        ### end of level many digits, must be N < 3**$level
        return ($n == 0);
      }
      last unless $n;

      my $digit = _divrem_mutate($n,3);
      if ($disallowed[$digit][$prev]) {
        return 0;
      }
      if (defined $level) { $level -= 1; }
      $prev = $digit;
    }

    return ((defined $level && $level < 0)   # union all levels
            || ($prev != 2));                # not high 2 otherwise
  }

  sub _UNDOCUMENTED__n_segment_is_any_left_boundary {
    my ($self, $n) = @_;
    my $prev = _divrem_mutate($n,3);
    while ($n) {
      my $digit = _divrem_mutate($n,3);
      if ($disallowed[$digit][$prev]) {
        return 0;
      }
      $prev = $digit;
    }
    return 1;
  }

  # sub left_boundary_n_pred {
  #   my ($n) = @_;
  #   my $n3 = '0' . Math::BaseCnv::cnv($n,10,3);
  #   return ($n3 =~ /02|10|11/ ? 0 : 1);
  # }
}
sub _UNDOCUMENTED__n_segment_is_boundary {
  my ($self, $n, $level) = @_;
  return $self->_UNDOCUMENTED__n_segment_is_right_boundary($n)
    || $self->_UNDOCUMENTED__n_segment_is_left_boundary($n,$level);
}

1;
__END__


# old n_to_xy()
#
# # initial rotation from arm number
# my $arms = $self->{'arms'};
# my $rot = $n % $arms;
# $n = int($n/$arms);

# my @digits;
# my (@si, @sj, @sk);  # vectors
# {
#   my $si = $zero + 1; # inherit bignum 1
#   my $sj = $zero;     # inherit bignum 0
#   my $sk = $zero;     # inherit bignum 0
#
#   for (;;) {
#     push @digits, ($n % 3);
#     push @si, $si;
#     push @sj, $sj;
#     push @sk, $sk;
#     ### push: "digit $digits[-1]   $si,$sj,$sk"
#
#     $n = int($n/3) || last;
#
#     # straight + rot120 + straight
#     ($si,$sj,$sk) = (2*$si - $sj,
#                      2*$sj - $sk,
#                      2*$sk + $si);
#   }
# }
# ### @digits
#
# my $i = $zero;
# my $j = $zero;
# my $k = $zero;
# while (defined (my $digit = pop @digits)) {  # digits high to low
#   my $si = pop @si;
#   my $sj = pop @sj;
#   my $sk = pop @sk;
#   ### at: "$i,$j,$k  $digit   side $si,$sj,$sk"
#   ### $rot
#
#   $rot %= 6;
#   if ($rot == 1)    { ($si,$sj,$sk) = (-$sk,$si,$sj); }
#   elsif ($rot == 2) { ($si,$sj,$sk) = (-$sj,-$sk,$si); }
#   elsif ($rot == 3) { ($si,$sj,$sk) = (-$si,-$sj,-$sk); }
#   elsif ($rot == 4) { ($si,$sj,$sk) = ($sk,-$si,-$sj); }
#   elsif ($rot == 5) { ($si,$sj,$sk) = ($sj,$sk,-$si); }
#
#   if ($digit) {
#     $i += $si;  # digit=1 or digit=2
#     $j += $sj;
#     $k += $sk;
#     if ($digit == 2) {
#       $i -= $sj;  # digit=2, straight+rot120
#       $j -= $sk;
#       $k += $si;
#     } else {
#       $rot += 2;  # digit=1
#     }
#   }
# }
#
# $rot %= 6;
# $i = $frac * $dir6_to_si[$rot] + $i;
# $j = $frac * $dir6_to_sj[$rot] + $j;
# $k = $frac * $dir6_to_sk[$rot] + $k;
#
# ### final: "$i,$j,$k"
# return (2*$i + $j - $k, $j+$k);


=for stopwords eg Ryde Dragon Math-PlanePath Nlevel Knuth et al vertices doublings OEIS terdragon ie morphism si,sj,sk dX,dY Pari rhombi dX si Ns unexpand unpoint

=head1 NAME

Math::PlanePath::TerdragonCurve -- triangular dragon curve

=head1 SYNOPSIS

 use Math::PlanePath::TerdragonCurve;
 my $path = Math::PlanePath::TerdragonCurve->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Davis>X<Knuth, Donald>This is the terdragon curve by Davis and Knuth,

=over

Chandler Davis and Donald Knuth, "Number Representations and Dragon Curves
-- I", Journal Recreational Mathematics, volume 3, number 2 (April 1970),
pages 66-81 and "Number Representations and Dragon Curves -- II", volume 3,
number 3 (July 1970), pages 133-149.

Reprinted with addendum in Knuth "Selected Papers on Fun and Games", 2010,
pages 571--614.  L<http://www-cs-faculty.stanford.edu/~uno/fg.html>

=back

Points are a triangular grid using every second integer X,Y as per
L<Math::PlanePath/Triangular Lattice>, beginning

              \         /       \
           --- 26,29,32 ---------- 27                          6
              /         \
      \      /           \
   -- 24,33,42 ---------- 22,25                                5
      /      \           /     \
              \         /       \
           --- 20,23,44 -------- 12,21            10           4
              /        \        /      \        /     \
      \      /          \      /        \      /       \
        18,45 --------- 13,16,19 ------ 8,11,14 -------- 9     3
             \          /       \      /       \
              \        /         \    /         \
                  17              6,15 --------- 4,7           2
                                       \        /    \
                                        \      /      \
                                          2,5 ---------- 3     1
                                              \
                                               \
                                    0 ----------- 1         <-Y=0

          ^        ^        ^       ^      ^      ^      ^
         -3       -2       -1      X=0     1      2      3

The base figure is an "S" shape

       2-----3
        \
         \
    0-----1

which then repeats in self-similar style, so N=3 to N=6 is a copy rotated
+120 degrees, which is the angle of the N=1 to N=2 edge,

    6      4          base figure repeats
     \   / \          as N=3 to N=6,
      \/    \         rotated +120 degrees
      5 2----3
        \
         \
    0-----1

Then N=6 to N=9 is a plain horizontal, which is the angle of N=2 to N=3,

          8-----9       base figure repeats
           \            as N=6 to N=9,
            \           no rotation
       6----7,4
        \   / \
         \ /   \
         5,2----3
           \
            \
       0-----1

Notice X=1,Y=1 is visited twice as N=2 and N=5.  Similarly X=2,Y=2 as N=4
and N=7.  Each point can repeat up to 3 times.  "Inner" points are 3 times
and on the edges up to 2 times.  The first tripled point is X=1,Y=3 which as
shown above is N=8, N=11 and N=14.

The curve never crosses itself.  The vertices touch as triangular corners
and no edges repeat.

The curve turns are the same as the C<GosperSide>, but here the turns are by
120 degrees each whereas C<GosperSide> is 60 degrees each.  The extra angle
here tightens up the shape.

=head2 Spiralling

The first step N=1 is to the right along the X axis and the path then slowly
spirals anti-clockwise and progressively fatter.  The end of each
replication is

    Nlevel = 3^level

That point is at level*30 degrees around (as reckoned with Y*sqrt(3) for a
triangular grid).

    Nlevel      X, Y     Angle (degrees)
    ------    -------    -----
       1        1, 0        0
       3        3, 1       30
       9        3, 3       60
      27        0, 6       90
      81       -9, 9      120
     243      -27, 9      150
     729      -54, 0      180

The following is points N=0 to N=3^6=729 going half-circle around to 180
degrees.  The N=0 origin is marked "0" and the N=729 end is marked "E".

=cut

# the following generated by
#   math-image --path=TerdragonCurve --expression='i<=729?i:0' --text --size=132x40

=pod

                               * *               * *
                            * * * *           * * * *
                           * * * *           * * * *
                            * * * * *   * *   * * * * *   * *
                         * * * * * * * * * * * * * * * * * * *
                        * * * * * * * * * * * * * * * * * * *
                         * * * * * * * * * * * * * * * * * * * *
                            * * * * * * * * * * * * * * * * * * *
                           * * * * * * * * * * * *   * *   * * *
                      * *   * * * * * * * * * * * *           * *
     * E           * * * * * * * * * * * * * * * *           0 *
    * *           * * * * * * * * * * * *   * *
     * * *   * *   * * * * * * * * * * * *
    * * * * * * * * * * * * * * * * * * *
     * * * * * * * * * * * * * * * * * * * *
        * * * * * * * * * * * * * * * * * * *
       * * * * * * * * * * * * * * * * * * *
        * *   * * * * *   * *   * * * * *
                 * * * *           * * * *
                * * * *           * * * *
                 * *               * *

=head2 Tiling

The little "S" shapes of the base figure N=0 to N=3 can be thought of as a
rhombus

       2-----3
      .     .
     .     .
    0-----1

The "S" shapes of each 3 points make a tiling of the plane with those rhombi

        \     \ /     /   \     \ /     /
         *-----*-----*     *-----*-----*
        /     / \     \   /     / \     \
     \ /     /   \     \ /     /   \     \ /
    --*-----*     *-----*-----*     *-----*--
     / \     \   /     / \     \   /     / \
        \     \ /     /   \     \ /     /
         *-----*-----*     *-----*-----*
        /     / \     \   /     / \     \
     \ /     /   \     \ /     /   \     \ /
    --*-----*     *-----o-----*     *-----*--
     / \     \   /     / \     \   /     / \
        \     \ /     /   \     \ /     /
         *-----*-----*     *-----*-----*
        /     / \     \   /     / \     \

Which is an ancient pattern,

=over

L<http://tilingsearch.org/HTML/data23/C07A.html>

=back

=head2 Arms

The curve fills a sixth of the plane and six copies rotated by 60, 120, 180,
240 and 300 degrees mesh together perfectly.  The C<arms> parameter can
choose 1 to 6 such curve arms successively advancing.

For example C<arms =E<gt> 6> begins as follows.  N=0,6,12,18,etc is the
first arm (the same shape as the plain curve above), then N=1,7,13,19 the
second, N=2,8,14,20 the third, etc.

=cut

# generated by code in devel/terdragon.pl

=pod

                  \         /             \           /
                   \       /               \         /
                --- 8,13,31 ---------------- 7,12,30 ---
                  /        \               /         \
     \           /          \             /           \          /
      \         /            \           /             \        /
    --- 9,14,32 ------------- 0,1,2,3,4,5 -------------- 6,17,35 ---
      /         \            /           \             /        \
     /           \          /             \           /          \
                  \        /               \         /
               --- 10,15,33 ---------------- 11,16,34 ---
                  /        \               /         \
                 /          \             /           \

With six arms every X,Y point is visited three times, except the origin 0,0
where all six begin.  Every edge between points is traversed once.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::TerdragonCurve-E<gt>new ()>

=item C<$path = Math::PlanePath::TerdragonCurve-E<gt>new (arms =E<gt> 6)>

Create and return a new path object.

The optional C<arms> parameter can make 1 to 6 copies of the curve, each arm
successively advancing.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional positions give an X,Y position along a straight line between the
integer positions.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  If there's nothing at
C<$x,$y> then return C<undef>.

The curve can visit an C<$x,$y> up to three times.  C<xy_to_n()> returns the
smallest of the these N values.

=item C<@n_list = $path-E<gt>xy_to_n_list ($x,$y)>

Return a list of N point numbers for coordinates C<$x,$y>.

The origin 0,0 has C<arms_count()> many N since it's the starting point for
each arm.  Other points have up to 3 Ns for a given C<$x,$y>.  If arms=6
then every even C<$x,$y> except the origin has exactly 3 Ns.

=back

=head2 Descriptive Methods

=over

=item C<$n = $path-E<gt>n_start()>

Return 0, the first N in the path.

=item C<$dx = $path-E<gt>dx_minimum()>

=item C<$dx = $path-E<gt>dx_maximum()>

=item C<$dy = $path-E<gt>dy_minimum()>

=item C<$dy = $path-E<gt>dy_maximum()>

The dX,dY values on the first arm take three possible combinations, being
120 degree angles.

    dX,dY   for arms=1
    -----
     2, 0        dX minimum = -1, maximum = +2
    -1, 1        dY minimum = -1, maximum = +1
     1,-1

For 2 or more arms the second arm is rotated by 60 degrees so giving the
following additional combinations, for a total six.  This changes the dX
minimum.

    dX,dY   for arms=2 or more
    -----
    -2, 0        dX minimum = -2, maximum = +2
     1, 1        dY minimum = -1, maximum = +1
    -1,-1

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 3**$level)>, or for multiple arms return C<(0, $arms *
3**$level + ($arms-1))>.

There are 3^level segments in a curve level, so 3^level+1 points numbered
from 0.  For multiple arms there are arms*(3^level+1) points, numbered from
0 so n_hi = arms*(3^level+1)-1.

=back

=head1 FORMULAS

Various formulas for boundary length, area and more can be found in the
author's mathematical write-up

=over

L<http://user42.tuxfamily.org/terdragon/index.html>

=back

=head2 N to X,Y

There's no reversals or reflections in the curve so C<n_to_xy()> can take
the digits of N either low to high or high to low and apply what is
effectively powers of the N=3 position.  The current code goes low to high
using i,j,k coordinates as described in L<Math::PlanePath/Triangular
Calculations>.

    si = 1    # position of endpoint N=3^level
    sj = 0    #    where level=number of digits processed
    sk = 0

    i = 0     # position of N for digits so far processed
    j = 0
    k = 0

    loop base 3 digits of N low to high
       if digit == 0
          i,j,k no change
       if digit == 1
          (i,j,k) = (si-j, sj-k, sk+i)  # rotate +120, add si,sj,sk
       if digit == 2
          i -= sk      # add (si,sj,sk) rotated +60
          j += si
          k += sj

       (si,sj,sk) = (si - sk,      # add rotated +60
                     sj + si,
                     sk + sj)

The digit handling is a combination of rotate and offset,

    digit==1                   digit 2
    rotate and offset          offset at si,sj,sk rotated

         ^                          2------>
          \
           \                          \
    *---  --1                  *--   --*

The calculation can also be thought of in term of w=1/2+I*sqrt(3)/2, a
complex number sixth root of unity.  i is the real part, j in the w
direction (60 degrees), and k in the w^2 direction (120 degrees).  si,sj,sk
increase as if multiplied by w+1.

=head2 Turn

At each point N the curve always turns 120 degrees either to the left or
right, it never goes straight ahead.  If N is written in ternary then the
lowest non-zero digit gives the turn

   ternary lowest
   non-zero digit     turn
   --------------     -----
         1            left
         2            right

At N=3^level or N=2*3^level the turn follows the shape at that 1 or 2 point.
The first and last unit step in each level are in the same direction, so the
next level shape gives the turn.

       2*3^k-------3*3^k
          \
           \
    0-------1*3^k

=head2 Next Turn

The next turn, ie. the turn at position N+1, can be calculated from the
ternary digits of N similarly.  The lowest non-2 digit gives the turn.

   ternary lowest
     non-2 digit       turn
   --------------      -----
          0            left
          1            right

If N is all 2s then the lowest non-2 is taken to be a 0 above the high end.
For example N=8 is 22 ternary so considered 022 for lowest non-2 digit=0 and
turn left after the segment at N=8, ie. at point N=9 turn left.

This rule works for the same reason as the plain turn above.  The next turn
of N is the plain turn of N+1 and adding +1 turns trailing 2s into trailing
0s and increments the 0 or 1 digit above them to be 1 or 2.

=head2 Total Turn

The direction at N, ie. the total cumulative turn, is given by the number of
1 digits when N is written in ternary,

    direction = (count 1s in ternary N) * 120 degrees

For example N=12 is ternary 110 which has two 1s so the cumulative turn at
that point is 2*120=240 degrees, ie. the segment N=16 to N=17 is at angle
240.

The segments for digit 0 or 2 are in the "current" direction unchanged.  The
segment for digit 1 is rotated +120 degrees.

=head2 X,Y to N

The current code find digits of N low to high by a remainder on X,Y to get
the lowest then subtract and divide to unexpand.  See "unpoint" in the
author's mathematical write-up for details.

=head2 X,Y Visited

When arms=6 all "even" points of the plane are visited.  As per the
triangular representation of X,Y this means

    X+Y mod 2 == 0        "even" points

=head1 OEIS

The terdragon is in Sloane's Online Encyclopedia of Integer Sequences as,

=over

L<http://oeis.org/A080846> (etc)

=back

    A080846   next turn 0=left,1=right, by 120 degrees
                (n=0 is turn at N=1)

    A060236   turn 1=left,2=right, by 120 degrees
                (lowest non-zero ternary digit)
    A137893   turn 1=left,0=right (morphism)
    A189673   turn 1=left,0=right (morphism, extra initial 0)
    A189640   turn 0=left,1=right (morphism, extra initial 0)
    A038502   strip trailing ternary 0s,
                taken mod 3 is turn 1=left,2=right
    A133162   1=segment, 2=right turn between

A189673 and A026179 start with extra initial values arising from their
morphism definition.  That can be skipped to consider the turns starting
with a left turn at N=1.

    A026225   N positions of left turns,
                being (3*i+1)*3^j so lowest non-zero digit is a 1
    A026179   N positions of right turns (except initial 1)
    A060032   bignum turns 1=left,2=right to 3^level
    A189674   num left turns 1 to N
    A189641   num right turns 1 to N
    A189672     same

    A026141   \ dN increment between left turns N
    A026171   /
    A026181   \ dN increment between left turns N
    A131989   /

    A062756   total turn, count ternary 1s
    A005823   N positions where net turn == 0, ternary no 1s

    A111286   boundary length, N=0 to N=3^k, skip initial 1
    A003945   boundary/2
    A002023   boundary odd levels N=0 to N=3^(2k+1),
              or even levels one side N=0 to N=3^(2k),
                being 6*4^k
    A164346   boundary even levels N=0 to N=3^(2k),
              or one side, odd levels, N=0 to N=3^(2k+1),
                being 3*4^k
    A042950   V[k] boundary length

    A056182   area enclosed N=0 to N=3^k, being 2*(3^k-2^k)
    A081956     same
    A118004   1/2 area N=0 to N=3^(2k+1), odd levels, 9^n-4^n
    A155559   join area, being 0 then 2^k

    A099754   1/2 count distinct visited points N=0 to N=3^k

    A092236   count East segments N=0 to N=3^k-1
    A135254   count North-West segments N=0 to N=3^k-1, extra 0
    A133474   count South-West segments N=0 to N=3^k-1
    A057083   count segments diff from 3^(k-1)
    A101990   count segments same dir as middle N=0 to N=3^k-1

    A097038   num runs of 12 consecutive segments within N=0 to 3^k-1
                each segment enclosing a new unit triangle

    A057682   level X, at N=3^level
                also arms=2 level Y, at N=2*3^level
    A057083   level Y, at N=3^level
                also arms=6 level X at N=6*3^level

    A057681   arms=2 level X, at N=2*3^level
                also arms=3 level Y at 3*3^level
    A103312   same

=head1 HOUSE OF GRAPHS

House of Graphs entries for the terdragon as a graph include

=over

=item level=2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=21138>

=item level=3, L<https://hog.grinvin.org/ViewGraphInfo.action?id=21140>

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::TerdragonRounded>,
L<Math::PlanePath::TerdragonMidpoint>,
L<Math::PlanePath::GosperSide>

L<Math::PlanePath::DragonCurve>,
L<Math::PlanePath::R5DragonCurve>

Larry Riddle's Terdragon page, for boundary and area calculations of the
terdragon as an infinite fractal
L<http://ecademy.agnesscott.edu/~lriddle/ifs/heighway/terdragon.htm>

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
