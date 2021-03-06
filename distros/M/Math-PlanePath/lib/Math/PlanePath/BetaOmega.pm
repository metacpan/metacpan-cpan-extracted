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


# math-image --path=BetaOmega --lines --scale=20
#
# math-image --path=BetaOmega --all --output=numbers_dash

# http://www.upb.de/pc2/papers/files/pdfps399main.toappear.ps   # gone
# http://www.uni-paderborn.de/pc2/papers/files/pdfps399main.toappear.ps
# http://wwwcs.upb.de/pc2/papers/files/399.ps   # gone
#
# copy ?
# http://www.cs.uleth.ca/~wismath/cccg/papers/27l.ps


package Math::PlanePath::BetaOmega;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 129;
use Math::PlanePath;
use Math::PlanePath::Base::NSEW;
@ISA = ('Math::PlanePath::Base::NSEW',
        'Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'bit_split_lowtohigh',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
#use Smart::Comments;




use constant n_start => 0;
use constant class_x_negative => 0;
use constant y_negative_at_n => 4;
*xy_is_visited = \&Math::PlanePath::Base::Generic::_xy_is_visited_x_positive;
use constant 1.02 _UNDOCUMENTED__dxdy_list_at_n => 4;


#------------------------------------------------------------------------------

# tables generated by tools/beta-omega-table.pl
#
my @next_state = (28, 8,36,88,  8,28,32,76,  4,16,44,64, 16, 4,40,84,
                  12,24,52,72, 24,12,48,92, 20, 0,60,80,  0,20,56,68,
                  68, 4,40,60, 64, 0,60,40, 76,12,48,36, 72, 8,36,48,
                  84,20,56,44, 80,16,44,56, 92,28,32,52, 88,24,52,32,
                  28, 8,36,48,  8,28,32,52,  4,16,44,56, 16, 4,40,60,
                  12,24,52,32, 24,12,48,36, 20, 0,60,40,  0,20,56,44);
my @digit_to_x = (0,0,1,1, 0,1,1,0, 1,0,0,1, 1,1,0,0,
                  1,1,0,0, 1,0,0,1, 0,1,1,0, 0,0,1,1,
                  1,1,0,0, 0,1,1,0, 1,0,0,1, 0,0,1,1,
                  0,0,1,1, 1,0,0,1, 0,1,1,0, 1,1,0,0,
                  0,0,1,1, 0,1,1,0, 1,0,0,1, 1,1,0,0,
                  1,1,0,0, 1,0,0,1, 0,1,1,0, 0,0,1,1);
my @digit_to_y = (0,1,1,0, 0,0,1,1, 0,0,1,1, 0,1,1,0,
                  1,0,0,1, 1,1,0,0, 1,1,0,0, 1,0,0,1,
                  0,1,1,0, 1,1,0,0, 1,1,0,0, 0,1,1,0,
                  1,0,0,1, 0,0,1,1, 0,0,1,1, 1,0,0,1,
                  0,1,1,0, 0,0,1,1, 0,0,1,1, 0,1,1,0,
                  1,0,0,1, 1,1,0,0, 1,1,0,0, 1,0,0,1);
my @xy_to_digit = (0,1,3,2, 0,3,1,2, 1,2,0,3, 3,2,0,1,
                   2,3,1,0, 2,1,3,0, 3,0,2,1, 1,0,2,3,
                   3,2,0,1, 3,0,2,1, 2,1,3,0, 0,1,3,2,
                   1,0,2,3, 1,2,0,3, 0,3,1,2, 2,3,1,0,
                   0,1,3,2, 0,3,1,2, 1,2,0,3, 3,2,0,1,
                   2,3,1,0, 2,1,3,0, 3,0,2,1, 1,0,2,3);
my @min_digit = (0,0,3,0, 0,2,1,1, 2,undef,undef,undef,
                 0,0,1,0, 0,1,3,2, 2,undef,undef,undef,
                 1,0,0,1, 0,0,2,2, 3,undef,undef,undef,
                 3,0,0,2, 0,0,2,1, 1,undef,undef,undef,
                 2,1,1,2, 0,0,3,0, 0,undef,undef,undef,
                 2,2,3,1, 0,0,1,0, 0,undef,undef,undef,
                 3,2,2,0, 0,1,0,0, 1,undef,undef,undef,
                 1,1,2,0, 0,2,0,0, 3,undef,undef,undef,
                 3,0,0,2, 0,0,2,1, 1,undef,undef,undef,
                 3,2,2,0, 0,1,0,0, 1,undef,undef,undef,
                 2,2,3,1, 0,0,1,0, 0,undef,undef,undef,
                 0,0,3,0, 0,2,1,1, 2,undef,undef,undef,
                 1,1,2,0, 0,2,0,0, 3,undef,undef,undef,
                 1,0,0,1, 0,0,2,2, 3,undef,undef,undef,
                 0,0,1,0, 0,1,3,2, 2,undef,undef,undef,
                 2,1,1,2, 0,0,3,0, 0,undef,undef,undef,
                 0,0,3,0, 0,2,1,1, 2,undef,undef,undef,
                 0,0,1,0, 0,1,3,2, 2,undef,undef,undef,
                 1,0,0,1, 0,0,2,2, 3,undef,undef,undef,
                 3,0,0,2, 0,0,2,1, 1,undef,undef,undef,
                 2,1,1,2, 0,0,3,0, 0,undef,undef,undef,
                 2,2,3,1, 0,0,1,0, 0,undef,undef,undef,
                 3,2,2,0, 0,1,0,0, 1,undef,undef,undef,
                 1,1,2,0, 0,2,0,0, 3);
my @max_digit = (0,3,3,1, 3,3,1,2, 2,undef,undef,undef,
                 0,1,1,3, 3,2,3,3, 2,undef,undef,undef,
                 1,1,0,2, 3,3,2,3, 3,undef,undef,undef,
                 3,3,0,3, 3,1,2,2, 1,undef,undef,undef,
                 2,2,1,3, 3,1,3,3, 0,undef,undef,undef,
                 2,3,3,2, 3,3,1,1, 0,undef,undef,undef,
                 3,3,2,3, 3,2,0,1, 1,undef,undef,undef,
                 1,2,2,1, 3,3,0,3, 3,undef,undef,undef,
                 3,3,0,3, 3,1,2,2, 1,undef,undef,undef,
                 3,3,2,3, 3,2,0,1, 1,undef,undef,undef,
                 2,3,3,2, 3,3,1,1, 0,undef,undef,undef,
                 0,3,3,1, 3,3,1,2, 2,undef,undef,undef,
                 1,2,2,1, 3,3,0,3, 3,undef,undef,undef,
                 1,1,0,2, 3,3,2,3, 3,undef,undef,undef,
                 0,1,1,3, 3,2,3,3, 2,undef,undef,undef,
                 2,2,1,3, 3,1,3,3, 0,undef,undef,undef,
                 0,3,3,1, 3,3,1,2, 2,undef,undef,undef,
                 0,1,1,3, 3,2,3,3, 2,undef,undef,undef,
                 1,1,0,2, 3,3,2,3, 3,undef,undef,undef,
                 3,3,0,3, 3,1,2,2, 1,undef,undef,undef,
                 2,2,1,3, 3,1,3,3, 0,undef,undef,undef,
                 2,3,3,2, 3,3,1,1, 0,undef,undef,undef,
                 3,3,2,3, 3,2,0,1, 1,undef,undef,undef,
                 1,2,2,1, 3,3,0,3, 3);

sub n_to_xy {
  my ($self, $n) = @_;
  ### BetaOmega n_to_xy(): $n
  ### hex: sprintf "%#X", $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  my $int = int($n);
  $n -= $int;  # remaining fraction, preserve possible BigFloat/BigRat

  my $zero = $int * 0;  # inherit bignum
  my @ndigits = digit_split_lowtohigh($int,4);
  ### ndigits: join(', ',@ndigits)."   count ".scalar(@ndigits)

  my $state = ($#ndigits & 1 ? 28 : 0);
  my $dirstate   = ($#ndigits & 1 ? 0 : 28); # default if all $ndigit==3
  my @xbits;
  my @ybits;

  foreach my $i (reverse 0 .. $#ndigits) {
    my $ndigit = $ndigits[$i];    # high to low
    $state += $ndigit;
    if ($ndigit != 3) {
      $dirstate = $state;  # lowest non-3 digit
    }

    ### $ndigit
    ### $state
    ### $dirstate
    ### digit_to_x: $digit_to_x[$state]
    ### digit_to_y: $digit_to_y[$state]
    ### next_state: $next_state[$state]

    $xbits[$i] = $digit_to_x[$state];
    $ybits[$i] = $digit_to_y[$state];
    $state = $next_state[$state];
  }

  ### $dirstate
  ### frac: $n
  ### Ymin: - (((4+$zero)**int($#ndigits/2) - 1) * 2 / 3)

  # with $n fractional part
  return ($n * ($digit_to_x[$dirstate+1] - $digit_to_x[$dirstate])
          + digit_join_lowtohigh(\@xbits, 2, $zero),

          $n * ($digit_to_y[$dirstate+1] - $digit_to_y[$dirstate])
          + (digit_join_lowtohigh(\@ybits, 2, $zero)

             # Ymin = - (4^floor(level/2) - 1) * 2 / 3
             - (((4+$zero)**int(scalar(@ndigits)/2) - 1) * 2 / 3)));
}


# ($len,$level) rounded down for $y ...
sub _y_round_down_len_level {
  my ($y) = @_;
  my $pos;
  if ($pos = ($y >= 0)) {
    # eg. 1 becomes 3, or 5 becomes 15, 2^k-1
    $y = 3 * $y;
  } else {
    # eg. -2 becomes 7, or -10 becomes 31, 2^k-1
    $y = 1 - 3*$y;
  }
  my ($len, $level) = round_down_pow($y,2);

  # Make positive y give even level, and negative y give odd level.
  # If positive and odd then reduce, or if negative and even then reduce.
  if (($level & 1) == $pos) {
    $level--;
    $len /= 2;
  }

  return ($len, $level);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### BetaOmega xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  if ($x < 0) {
    return undef;
  }
  if (is_infinite($x)) {
    return $x;
  }
  my @xbits = bit_split_lowtohigh($x);

  $y = round_nearest ($y);
  my $zero = ($x * 0 * $y);
  my ($len, $level) = _y_round_down_len_level ($y);
  ### y: "len=$len  level=$level"

  if ($#xbits > $level) {
    ### increase level to xbits ...
    $level = $#xbits;
    $len = (2+$zero) ** $level;
  }
  ### $len
  ### $level

  $y += (($level&1 ? 4 : 2) * $len - 2) / 3;
  ### offset y to: $y
  if (is_infinite($y)) {
    return $y;
  }
  my @ybits = bit_split_lowtohigh($y);
  my $state = ($level & 1 ? 28 : 0);

  my @ndigits;
  foreach my $i (reverse 0 .. $level) {   # high to low
    ### at: "i=$i state=$state  xbit=".($xbits[$i]||0)." ybit=".($ybits[$i]||0)

    my $ndigit = $xy_to_digit[$state + 2*($xbits[$i]||0) + ($ybits[$i]||0)];
    $ndigits[$i] = $ndigit;
    $state = $next_state[$state+$ndigit];
  }

  return digit_join_lowtohigh(\@ndigits, 4, $zero);
}

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### BetaOmega rect_to_n_range(): "$x1,$y1, $x2,$y2"

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;

  if ($x2 < 0) {
    return (1, 0);
  }

  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  my ($len, $level) = round_down_pow ($x2, 2);
  ### x len/level: "$len  $level"

  # If y1/y2 both positive or both negative then only look at the bigger of
  # the two.  If y1 negative and y2 positive then consider both.
  foreach my $y (($y2 > 0 ? ($y2) : ()),
                 ($y1 < 0 ? ($y1) : ())) {
    my ($ylen, $ylevel) = _y_round_down_len_level ($y);
    ### y len/level: "$ylen  $ylevel"
    if ($ylevel > $level) {
      $level = $ylevel;
      $len = $ylen;
    }
  }
  if (is_infinite($len)) {
    return (0, $len);
  }

  my $n_min = my $n_max = 0;
  my $y_min = my $y_max = - (4**int(($level+1)/2) - 1) * 2 / 3;
  my $x_min = my $x_max = 0;
  my $min_state = my $max_state = ($level & 1 ? 28 : 0);
  ### $x_min
  ### $y_min

  while ($level >= 0) {
    ### $level
    ### $len
    {
      my $x_cmp = $x_min + $len;
      my $y_cmp = $y_min + $len;
      my $digit = $min_digit[3*$min_state
                             + ($x1 >= $x_cmp ? 2 : $x2 >= $x_cmp ? 1 : 0)
                             + ($y1 >= $y_cmp ? 6 : $y2 >= $y_cmp ? 3 : 0)];

      # my $xr = ($x1 >= $x_cmp ? 2 : $x2 >= $x_cmp ? 1 : 0);
      # my $yr = ($y1 >= $y_cmp ? 6 : $y2 >= $y_cmp ? 3 : 0);
      # my $key = 3*$min_state + ($x1 >= $x_cmp ? 2 : $x2 >= $x_cmp ? 1 : 0) + ($y1 >= $y_cmp ? 6 : $y2 >= $y_cmp ? 3 : 0);
      # ### min at: "min_state=$min_state  $x_min,$y_min   cmp $x_cmp,$y_cmp"
      # ### min_state: state_string($min_state)
      # ### $xr
      # ### $yr
      # ### $key
      # ### min digit: $digit
      # ### min key: $key
      # ### y offset: $digit_to_y[$max_state+$digit]

      $n_min = 4*$n_min + $digit;
      $min_state += $digit;
      if ($digit_to_x[$min_state]) { $x_min += $len; }
      $y_min += $len * $digit_to_y[$min_state];
      $min_state = $next_state[$min_state];
    }
    {
      my $x_cmp = $x_max + $len;
      my $y_cmp = $y_max + $len;
      my $digit = $max_digit[3*$max_state
                             + ($x1 >= $x_cmp ? 2 : $x2 >= $x_cmp ? 1 : 0)
                             + ($y1 >= $y_cmp ? 6 : $y2 >= $y_cmp ? 3 : 0)];

      # my $xr = ($x1 >= $x_cmp ? 2 : $x2 >= $x_cmp ? 1 : 0);
      # my $yr = ($y1 >= $y_cmp ? 6 : $y2 >= $y_cmp ? 3 : 0);
      # my $key = 3*$min_state + ($x1 >= $x_cmp ? 2 : $x2 >= $x_cmp ? 1 : 0) + ($y1 >= $y_cmp ? 6 : $y2 >= $y_cmp ? 3 : 0);
      # ### max at: "max_state=$max_state  $x_max,$y_max   cmp $x_cmp,$y_cmp"
      # ### $x_cmp
      # ### $y_cmp
      # ### $xr
      # ### $yr
      # ### $key
      # ### max digit: $digit
      # ### x offset: $digit_to_x[$max_state+$digit]
      # ### y offset: $digit_to_y[$max_state+$digit]
      # ### y digit offset: $digit_to_y[$max_state+$digit]
      # ### y min shift part: - ($level&1)

      $n_max = 4*$n_max + $digit;
      $max_state += $digit;
      if ($digit_to_x[$max_state]) { $x_max += $len; }
      $y_max += $len * $digit_to_y[$max_state];
      $max_state = $next_state[$max_state];
    }

    $len = int($len/2);
    $level--;
  }

  return ($n_min, $n_max);
}

#------------------------------------------------------------------------------
# levels

use Math::PlanePath::HilbertCurve;
*level_to_n_range = \&Math::PlanePath::HilbertCurve::level_to_n_range;
*n_to_level       = \&Math::PlanePath::HilbertCurve::n_to_level;

#------------------------------------------------------------------------------
1;
__END__


    #                                                |
    #   5   25--26  29--30  33--34  37--38 249-250 255-254 233-232-231-230
    #        |   |   |   |   |   |   |   |   |   |       |   |           |
    #   4   24  27--28  31--32  35--36  39 248 251-252-253 234-235 228-229
    #        |                           |   |                   |   |
    #   3   23  20--19--18  45--44--43  40 247 244-243 240-239 236 227-226
    #        |   |       |   |       |   |   |   |   |   |   |   |       |
    #   2   22--21  16--17  46--47  42--41 246-245 242-241 238-237 224-225
    #                |           |                                   |
    #   1    1-- 2  15--14  49--48  53--54 201-202 205-206 209-210 223-222
    #        |   |       |   |       |   |   |   |   |   |   |   |       |
    # Y=0->  0   3  12--13  50--51--52  55 200 203-204 207-208 211 220-221
    #            |   |                   |   |                   |   |
    #  -1    5-- 4  11--10  61--60--59  56 199 196-195-194 213-212 219-218
    #        |           |   |       |   |   |   |       |   |           |
    #  -2    6-- 7-- 8-- 9  62--63  58--57 198-197 192-193 214-215-216-217
    #                            |                   |
    #  -3   89--88--87--86  65--64  69--70 185-186 191-190 169-168-167-166
    #        |           |   |       |   |   |   |       |   |           |
    #  -4   90--91  84--85  66--67--68  71 184 187-188-189 170-171 164-165
    #            |   |                   |   |                   |   |
    #  -5   93--92  83  80--79  76--75  72 183 180-179 176-175 172 163-162
    #        |       |   |   |   |   |   |   |   |   |   |   |   |       |
    #  -6   94--95  82--81  78--77  74--73 182-181 178-177 174-173 160-161
    #            |                                                   |
    #  -7   97--96 109-110 113-114 125-126 129-130 141-142 145-146 159-158
    #        |       |   |   |   |   |   |   |   |   |   |   |   |       |
    #  -8   98--99 108 111-112 115 124 127-128 131 140 143-144 147 156-157
    #            |   |           |   |           |   |           |   |
    #  -9  101-100 107-106 117-116 123-122 133-132 139-138 149-148 155-154
    #        |           |   |           |   |           |   |           |
    # -10  102-103-104-105 118-119-120-121 134-135-136-137 150-151-152-153
    #
    #       ^
    #      X=0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15




=for stopwords eg Ryde OEIS ie bignums prepending Math-PlanePath Jens-Michael Wierum Ymin Ymax Wierum's Paderborn CCCG'02 MERCHANTABILITY 14th ybit

=head1 NAME

Math::PlanePath::BetaOmega -- 2x2 half-plane traversal

=head1 SYNOPSIS

 use Math::PlanePath::BetaOmega;
 my $path = Math::PlanePath::BetaOmega->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Wierum, Jens-Michael>This is an integer version of the Beta-Omega curve

=over

Jens-Michael Wierum, "Definition of a New Circular Space-Filling Curve:
Beta-Omega-Indexing", Technical Report TR-001-02, Paderborn Centre for
Parallel Computing, March 2002.

=back

The curve form here makes a 2x2 self-similar traversal of the half plane
XE<gt>=0.

      5   25--26  29--30  33--34  37--38
           |   |   |   |   |   |   |   |
      4   24  27--28  31--32  35--36  39
           |                           |
      3   23  20--19--18  45--44--43  40
           |   |       |   |       |   |
      2   22--21  16--17  46--47  42--41
                   |           |
      1    1-- 2  15--14  49--48  53--54
           |   |       |   |       |   |
    Y=0->  0   3  12--13  50--51--52  55
               |   |                   |
     -1    5-- 4  11--10  61--60--59  56
           |           |   |       |   |
     -2    6-- 7-- 8-- 9  62--63  58--57
                               |
     -3                       ...

         X=0   1   2   3   4   5   6   7

Each level extends square parts 2^level x 2^level alternately up or down.
The initial N=0 to N=3 extends upwards from Y=0 and exits the block
downwards at N=3.  N=4 extends downwards and goes around back upwards to
exit N=15.  N=16 then extends upwards through to N=63 which exits downwards,
etc.

The curve is named for the two base shapes

         Beta                     Omega

           *---*                  *---*
           |   |                  |   |
         --*   *                --*   *--
               |

The beta is made from three betas and an omega sub-parts.  The omega is made
from four betas.  In each case the sub-parts are suitably rotated,
transposed or reversed, so expanding to

    Beta = 3*Beta+Omega      Omega = 4*Beta

      *---*---*---*            *---*---*---*
      |           |            |           |
      *---*   *---*            *---*   *---*
          |   |                    |   |
    --*   *   *---*          --*   *   *   *--
      |   |       |            |   |   |   |
      *---*   *---*            *---*   *---*
              |

The sub-parts represent successive ever-smaller substitutions.  They have
the effect of making the start a beta going alternately up or down.  For
this integer version the start direction is kept fixed as a beta going
upwards and the higher levels then alternate up and down from there.

=head2 Level Ranges

Reckoning the initial N=0 to N=3 as level 1, a replication level extends to

    Nlevel = 4^level - 1
    Xmin = 0
    Xmax = 2^level - 1

    Ymin = - (4^floor(level/2) - 1) * 2 / 3
         = binary 1010...10
    Ymax = (4^ceil(level/2) - 1) / 3
         = binary 10101...01

    height = Ymax - Ymin = 2^level - 1

The Y range increases alternately above and below by a power of 2, so the
result for Ymin and Ymax is a 1 bit going alternately to Ymax and Ymin,
starting with Ymax for level 1.

    level     Ymin    binary       Ymax   binary
    -----     --------------       -------------
      0         0                    0
      1         0          0         1 =       1
      2        -2 =      -10         1 =      01
      3        -2 =     -010         5 =     101
      4       -10 =    -1010         5 =    0101
      5       -10 =   -01010        21 =   10101
      6       -42 =  -101010        21 =  010101
      7       -42 = -0101010        85 = 1010101

The power of 4 divided by 3 formulas above for Ymin/Ymax have the effect of
producing alternating bit patterns like this.

For odd levels -Ymin/height approaches 1/3 and Ymax/height approaches 2/3,
ie. the start point is about 1/3 up the total extent.  For even levels it's
the other way around, with -Ymin/height approaching 2/3 and Ymax/height
approaching 1/3.

=head2 Closed Curve

Wierum's idea for the curve is a closed square made from four betas,

    *---*      *---*
    |   |      |   |
    *   *--  --*   *
    |              |

    |              |
    *   *--  --*   *
    |   |      |   |
    *---*      *---*

And at the next expansion level

    *---*---*---*       *---*---*---*
    |           |       |           |
    *---*   *---*       *---*   *---*
        |   |               |   |
    *---*   *   *--   --*   *   *---*
    |       |   |       |   |       |
    *---*   *---*       *---*   *---*
        |                       |

        |                       |
    *---*   *---*       *---*   *---*
    |       |   |       |   |       |
    *---*   *   *--   --*   *   *---*
        |   |               |   |
    *---*   *---*       *---*   *---*
    |           |       |           |
    *---*---*---*       *---*---*---*

The code here could be used for that by choosing a level and applying four
copies of the path suitably mirrored and offset in X and Y.

For an odd level, the path N=0 to N=4^level-1 here is the top-right quarter,
entering on the left and exiting downwards.  For an even level it's the
bottom-right shape instead, exiting upwards.  The difference arises because
when taking successively greater detail sub-parts the initial direction
alternates up or down, but in the code here it's kept fixed (as noted
above).

The start point here is also fixed at Y=0, so an offset Ymin must be applied
if say the centre of the sections is to be Y=0 instead of the side entry
point.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::BetaOmega-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 4**$level - 1)>.

=back

=head1 FORMULAS

=head2 N to X,Y

Each 2 bits of N become a bit each for X and Y in a "U" arrangement, but
which way around is determined by sub-part orientation and beta/omega type
per above,

    beta rotation     4 of
         transpose    2 of
         reverse      2 of
    omega rotation    4 of
          transpose   2 of
                    ----
    total states     24   = 4*2*2 + 4*2

The omega pattern is symmetric so its reverse is the same, hence only rotate
and transpose forms for it.  Omitting omega reverse reduces the states from
32 to 24, saving a little space in a table driven approach.  But if using
separate variables for rotate, transpose and reverse then the reverse can be
kept for both beta and omega without worrying that it makes no difference in
the omega.

Adding bits to Y produces a positive value measured up from Ymin(level),
where level is the number of base 4 digits in N.  That Ymin can be
incorporated by adding -(2^level) for each even level.  A table driven
calculation can work that in as for example

    digit = N base 4 digits from high to low

    xbit = digit_to_x[state,digit]
    ybit = digit_to_y[state,digit]
    state = next_state[state,digit]

    X += 2^level * xbit
    Y += 2^level * (ybit - !(level&1))

The (ybit-!(level&1)) means either 0,1 or -1,0.  Another possibility there
would be to have -!(level&1) in the digit_to_y[] table, doubling the states
so as to track the odd/even level within the state and having the
digit_to_y[] as -1,0 in the even and 0,1 in the odd.

=head2 N to X,Y Fraction

If N includes a fractional part, it can be put on a line towards the next
integer point by taking the direction as at the least significant non-3
digit.

If the least significant base 4 digit is 3 then the direction along the
curve is determined by the curve part above.  For example at N=7 (13 base 4)
it's rightwards as per the inverted beta which is the N=4 towards N=8 part
of the surrounding pattern.  Or likewise N=11 (23 base 4) in the N=8 to N=12
direction.

        |                 0    12--
    5---4                 |     |
    |                     |     |
    6---7-- ...           4-----8

If all digits are 3 base 4, which is N=3, N=15, N=63, etc, then the
direction is down for an odd number of digits, up for an even number.  So
N=3 downwards, N=15 upwards, N=63 downwards, etc.

This curve direction calculation might be of interest in its own right, not
merely to apply a fractional N as done in the code here.  There's nothing
offered for that in the C<PlanePath> modules as such.  For it the X,Y values
can be ignored just follow the state or orientations changes using the base
4 digits of N.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::HilbertCurve>,
L<Math::PlanePath::PeanoCurve>

=over

L<http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.18.3487> (cached
copy)

=back

Jens-Michael Wierum, "Logarithmic Path-Length in Space-Filling Curves", 14th
Canadian Conference on Computational Geometry (CCCG'02), 2002.

=over

L<http://www.cccg.ca/proceedings/2002/>,
L<http://www.cccg.ca/proceedings/2002/27.ps> (shorter),
L<http://www.cccg.ca/proceedings/2002/27l.ps> (longer)

=back

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
