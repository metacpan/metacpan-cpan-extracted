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


package Math::PlanePath::ImaginaryHalf;
use 5.004;
use strict;
use Carp 'croak';
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 126;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

use Math::PlanePath::ImaginaryBase;
*_negaradix_range_digits_lowtohigh
  = \&Math::PlanePath::ImaginaryBase::_negaradix_range_digits_lowtohigh;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;
use constant class_y_negative => 0;
*xy_is_visited = \&Math::PlanePath::Base::Generic::xy_is_visited_quad12;

use constant parameter_info_array =>
  [ Math::PlanePath::Base::Digits::parameter_info_radix2(),
    {
     name      => 'digit_order',
     share_key => 'digit_order_XYX',
     display   => 'Digit Order',
     type      => 'enum',
     default   => 'XYX',
     choices   => ['XYX',
                   'XXY',
                   'YXX',
                   'XnYX',
                   'XnXY',
                   'YXnX',
                  ],
    },
  ];

{
  my %x_negative_at_n = (XYX => 2,
                         XXY => 1,
                         YXX => 2,
                         XnYX => 0,
                         XnXY => 0,
                         YXnX => 1,
                        );
  sub x_negative_at_n {
    my ($self) = @_;
    return $self->{'radix'} ** $x_negative_at_n{$self->{'digit_order'}};
  }
}

# ENHANCE-ME: prove dY range
use constant dy_maximum => 1;

{
  my %absdx_minimum = (XYX => 1,
                       XXY => 1,
                       YXX => 0,   # dX=0 at N=0
                       XnYX => 2,  # dX=-2 at N=0
                       XnXY => 1,
                       YXnX => 0,  # dX=0 at N=0
                      );
  sub absdx_minimum {
    my ($self) = @_;
    return $absdx_minimum{$self->{'digit_order'}};
  }
}
{
  my %absdy_minimum = (XYX => 0,   # dY=0 at N=0
                       XXY => 0,   # dY=0 at N=0
                       YXX => 1,
                       XnYX => 0,   # dY=0 at N=0
                       XnXY => 0,   # dY=0 at N=0
                       YXnX => 1,
                      );
  sub absdy_minimum {
    my ($self) = @_;
    return $absdy_minimum{$self->{'digit_order'}};
  }
}

# was this anything?
#
# sub dir4_minimum {
#   my ($self) = @_;
#   if ($self->{'digit_order'} eq 'zzXYX') {
#     return Math::NumSeq::PlanePathDelta::_delta_func_Dir4
#       ($self->{'radix'}-1,-2);
#   } else {
#     return 0;
#   }
# }

{
  # radix>2 has a straight somewhere
  # radix=2 only has straight in XXY, XnXY
  my %turn_any_straight = (# XYX    => 0,
                           XXY  => 1,
                           # YXX    => 0,
                           XnXY => 1,
                           # XnYX   => 0,
                           # YXnX   => 0,
                          );
  sub turn_any_straight {
    my ($self) = @_;
    return ($self->{'radix'} > 2
            || $turn_any_straight{$self->{'digit_order'}});
  }
}

sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  my $digit_order = $self->{'digit_order'};
  my $radix = $self->{'radix'};
  if ($digit_order eq 'XXY') {
    return $radix*$radix - 1;
  }
  if ($digit_order eq 'YXX' || $digit_order eq 'XnYX') {
    return $radix;
  }
  if ($digit_order eq 'XnXY') {
    return $radix*$radix ;
  }
  return $radix - 1;
}
sub _UNDOCUMENTED__turn_any_right_at_n {
  my ($self) = @_;
  my $digit_order = $self->{'digit_order'};
  my $radix = $self->{'radix'};
  if ($digit_order eq 'XXY') {
    return $radix*$radix;
  }
  if ($digit_order eq 'XnXY') {
    return $radix*$radix - 1;
  }
  if ($digit_order eq 'YXX' || $digit_order eq 'XnYX') {
    return $radix - 1;
  }
  return $radix;
}


#------------------------------------------------------------------------------
my %digit_permutation = (XYX => [0,2,1],
                         YXX => [2,0,1],
                         XXY => [0,1,2],

                         XnYX => [1,2,0],
                         YXnX => [2,1,0],
                         XnXY => [1,0,2],
                        );

sub new {
  my $self = shift->SUPER::new(@_);

  my $radix = $self->{'radix'};
  if (! defined $radix || $radix <= 2) { $radix = 2; }
  $self->{'radix'} = $radix;

  my $digit_order = ($self->{'digit_order'} ||= 'XYX');
  $self->{'digit_permutation'} = $digit_permutation{$digit_order}
    || croak "Unrecognised digit_order: ",$digit_order;

  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### ImaginaryHalf n_to_xy(): $n

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

  my $radix = $self->{'radix'};
  my $zero = ($n*0); # inherit bignum 0

  my @xydigits = ([],[0],[]);
  my $digit_permutation = $digit_permutation{$self->{'digit_order'}};
  my @ndigits = digit_split_lowtohigh($n, $radix);
  foreach my $i (0 .. $#ndigits) {
    my $p = $digit_permutation->[$i%3];
    push @{$xydigits[$p]}, $ndigits[$i], ($p < 2 ? (0) : ());
  }

  return (digit_join_lowtohigh ($xydigits[0], $radix, $zero)
          - digit_join_lowtohigh ($xydigits[1], $radix, $zero),
          digit_join_lowtohigh ($xydigits[2], $radix, $zero));
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### ImaginaryHalf xy_to_n(): "$x, $y"

  $y = round_nearest ($y);
  if (is_infinite($y)) { return $y; }
  if ($y < 0) { return undef; }

  $x = round_nearest ($x);
  if (is_infinite($x)) { return $x; }

  my $zero = ($x * 0 * $y);  # inherit bignum 0
  my $radix = $self->{'radix'};
  my @ydigits = digit_split_lowtohigh($y, $radix);
  my $digit_permutation = $digit_permutation{$self->{'digit_order'}};

  my @ndigits; # digits low to high
  my @nd;
  while ($x || @ydigits) {
    $nd[0] = _divrem_mutate ($x, $radix);
    $x = -$x;
    $nd[1] = _divrem_mutate ($x, $radix);
    $x = -$x;
    $nd[2] = shift @ydigits || 0;

    push @ndigits,
      $nd[$digit_permutation->[0]],
        $nd[$digit_permutation->[1]],
          $nd[$digit_permutation->[2]];
  }
  return digit_join_lowtohigh (\@ndigits, $radix, $zero);
}

# Nlevel=2^level-1
#    66666666 55 55 5555 7.[16].7
#    66666666 55 55 5555 7.[16].7
#    66666666 33 22 4444 7.[16].7
#  9 66666666 33 01 4444 7.[16].7
#  ^        ^  ^  ^ ^    ^        ^
# -11      -3 -1  1 2    6       22
#
# X=1     when level=1
# X=1+1=2 when level=4
# X=2+4=6 when level=7
# X=6+16=22 when level=10
#
# X=0-2=-2 when level=3
# X=-2-8=-10  when level=6
# X=-10-32=-42 when level=9
#
# Y=1 k=0 want level=2
# Y=2 k=1 want level=5
# Y=4 k=2 want level=8
#
# X = 1 + 1 + 4 + 16 + 4^k
#   = 1 + (4^(k+1) - 1) / (4-1)
# X*(R2-1) = (R2-1) + R2^(k+1) - 1
# X*(R2-1) + 1 - (R2-1) = R2^(k+1)
# R2^(k+1) = (X-1)*(R2-1) + 1
# k+1 = round down pow (X-1)*(R2-1) + 1
# (1-1)*3+1=1    k+1=0   want level=1
# (2-1)*3+1=4    k+1=1   want level=4
# (6-1)*3+1=16   k+1=2   want level=7
# (22-1)*3+1=64  k+1=3   want level=10
#
# X = 1 + 2 + 8 + 32 + ... 2*4^k
#   = 1 + 2*(4^(k+1) - 1) / (4-1)
# X = 1 + R*(R2^(k+1) - 1) / (R2-1)
# R*(R2^(k+1) - 1) / (R2-1) = X-1
# R2^(k+1) - 1 = (X-1)*(R2-1)/R
# R2^(k+2) - R2 = (X-1)*(R2-1)*R
# R2^(k+2) = (X-1)*(R2-1)*R + R2
# (1-1)*3*2+4=4   k+2=1 want level=3
# (3-1)*3*2+4=16  k+2=2 want level=6
# (11-1)*3*2+4=64 k+2=3 want level=9

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### ImaginaryBase rect_to_n_range(): "$x1,$y1  $x2,$y2"

  my $zero = $x1 * 0 * $x2 * $y1 * $y2;

  $y1 = round_nearest($y1);
  $y2 = round_nearest($y2);
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
  if ($y2 < 0) {
    ### rectangle all Y negative, no points ...
    return (1, 0);
  }
  if (is_infinite($y2)) {
    return (0, $y2);
  }
  if ($y1 < 0) { $y1 *= 0; }   # "*=" to preserve bigint y1

  $x1 = round_nearest($x1);
  $x2 = round_nearest($x2);

  my $radix = $self->{'radix'};

  my ($min_xdigits, $max_xdigits)
    = _negaradix_range_digits_lowtohigh($x1,$x2, $radix);
  unless (defined $min_xdigits) {
    return (0, $max_xdigits); # infinity
  }

  my @min_ydigits = digit_split_lowtohigh ($y1, $radix);
  my @max_ydigits = digit_split_lowtohigh ($y2, $radix);

  my $digit_permutation = $digit_permutation{$self->{'digit_order'}};
  my @min_ndigits
    = _digit_permutation_interleave ($digit_permutation,
                                     $min_xdigits, \@min_ydigits);
  my @max_ndigits
    = _digit_permutation_interleave ($digit_permutation,
                                     $max_xdigits, \@max_ydigits);

  return (digit_join_lowtohigh (\@min_ndigits, $radix, $zero),
          digit_join_lowtohigh (\@max_ndigits, $radix, $zero));
}

sub _digit_permutation_interleave {
  my ($digit_permutation, $xaref, $yaref) = @_;
  my @ret;
  my @d;
  foreach (0 .. max($#$xaref,2*$#$yaref)) {
    $d[0] = shift @$xaref || 0;
    $d[1] = shift @$xaref || 0;
    $d[2] = shift @$yaref || 0;
    push @ret,
      $d[$digit_permutation->[0]],
        $d[$digit_permutation->[1]],
          $d[$digit_permutation->[2]];
  }
  return @ret;
}

#------------------------------------------------------------------------------
# levels

*level_to_n_range = \&Math::PlanePath::ImaginaryBase::level_to_n_range;
*n_to_level = \&Math::PlanePath::ImaginaryBase::n_to_level;

#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Math-PlanePath quater-imaginary radix Radix ie radix-1 Proth XYX XXY Xn

=head1 NAME

Math::PlanePath::ImaginaryHalf -- half-plane replications in three directions

=head1 SYNOPSIS

 use Math::PlanePath::ImaginaryBase;
 my $path = Math::PlanePath::ImaginaryBase->new (radix => 4);
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is a half-plane variation on the C<ImaginaryBase> path.

=cut

# math-image --path=ImaginaryHalf --all --output=numbers_dash --size=85x10

=pod

     54-55 50-51 62-63 58-59 22-23 18-19 30-31 26-27       3
       \     \     \     \     \     \     \     \
     52-53 48-49 60-61 56-57 20-21 16-17 28-29 24-25       2

     38-39 34-35 46-47 42-43  6--7  2--3 14-15 10-11       1
       \     \     \     \     \     \     \     \
     36-37 32-33 44-45 40-41  4--5  0--1 12-13  8--9   <- Y=0

    -------------------------------------------------
    -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5

The pattern can be seen by dividing into blocks,

    +---------------------------------+
    | 22  23  18  19   30  31  26  27 |
    |                                 |
    | 20  21  16  17   28  29  24  25 |
    +--------+-------+----------------+
    |  6   7 | 2   3 | 14  15  10  11 |
    |        +---+---+                |
    |  4   5 | 0 | 1 | 12  13   8   9 |  <- Y=0
    +--------+---+---+----------------+
               ^
              X=0

N=0 is at the origin, then N=1 replicates it to the right.  Those two repeat
above as N=2 and N=3.  Then that 2x2 repeats to the left as N=4 to N=7, then
4x2 repeats to the right as N=8 to N=15, and 8x2 above as N=16 to N=31, etc.
The replications are successively to the right, above, left.  The relative
layout within a replication is unchanged.

This is similar to the C<ImaginaryBase>, but where it repeats in 4
directions there's just 3 directions here.  The C<ZOrderCurve> is a 2
direction replication.

=head2 Radix

The C<radix> parameter controls the radix used to break N into X,Y.  For
example C<radix =E<gt> 4> gives 4x4 blocks, with radix-1 replications of the
preceding level at each stage.

     radix => 4  

     60 61 62 63 44 45 46 47 28 29 30 31 12 13 14 15      3
     56 57 58 59 40 41 42 43 24 25 26 27  8  9 10 11      2
     52 53 54 55 36 37 38 39 20 21 22 23  4  5  6  7      1
     48 49 50 51 32 33 34 35 16 17 18 19  0  1  2  3  <- Y=0

    --------------------------------------^-----------
    -12-11-10 -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3

Notice for X negative the parts replicate successively towards -infinity, so
the block N=16 to N=31 is first at X=-4, then N=32 at X=-8, N=48 at X=-12,
and N=64 at X=-16 (not shown).

=head2 Digit Order

The C<digit_order> parameter controls the order digits from N are applied to
X and Y.  The default above is "XYX" so the replications go X then Y then
negative X.

"XXY" goes to negative X before Y, so N=2,N=3 goes to negative X before
repeating N=4 to N=7 in the Y direction.

=cut

# math-image --path=ImaginaryHalf,digit_order=XXY --all --output=numbers --size=55x4

=pod

    digit_order => "XXY"

    38  39  36  37  46  47  44  45
    34  35  32  33  42  43  40  41
     6   7   4   5  14  15  12  13
     2   3   0   1  10  11   8   9
    ---------^--------------------
    -2  -1  X=0  1   2   3   4   5

The further options are as follows, for six permutations of each 3 digits
from N.

=cut

# math-image --path=ImaginaryHalf,digit_order=YXX --all --output=numbers --size=55x4

=pod

    digit_order => "YXX"               digit_order => "XnYX"   
    38 39 36 37 46 47 44 45            19 23 18 22 51 55 50 54
    34 35 32 33 42 43 40 41            17 21 16 20 49 53 48 52
     6  7  4  5 14 15 12 13             3  7  2  6 35 39 34 38
     2  3  0  1 10 11  8  9             1  5  0  4 33 37 32 36

    digit_order => "XnXY"              digit_order => "YXnX"   
    37 39 36 38 53 55 52 54            11 15  9 13 43 47 41 45
    33 35 32 34 49 51 48 50            10 14  8 12 42 46 40 44
     5  7  4  6 21 23 20 22             3  7  1  5 35 39 33 37
     1  3  0  2 17 19 16 18             2  6  0  4 34 38 32 36

"Xn" means the X negative direction.  It's still spaced 2 apart (or whatever
radix), so the result is not simply a -X,Y.

=head2 Axis Values

N=0,1,4,5,8,9,etc on the X axis (positive and negative) are those integers
with a 0 at every third bit starting from the second least significant bit.
This is simply demanding that the bits going to the Y coordinate must be 0.

    X axis Ns = binary ...__0__0__0_     with _ either 0 or 1
    in octal, digits 0,1,4,5 only

N=0,1,8,9,etc on the X positive axis have the highest 1-bit in the first
slot of a 3-bit group.  Or N=0,4,5,etc on the X negative axis have the high
1 bit in the third slot,

    X pos Ns = binary    1_0__0__0...0__0__0_
    X neg Ns = binary  10__0__0__0...0__0__0_
                       ^^^
                       three bit group

    X pos Ns in octal have high octal digit 1
    X neg Ns in octal high octal digit 4 or 5

N=0,2,16,18,etc on the Y axis are conversely those integers with a 0 in two
of each three bits, demanding the bits going to the X coordinate must be 0.

    Y axis Ns = binary ..._00_00_00_0    with _ either 0 or 1
    in octal has digits 0,2 only

For a radix other than binary the pattern is the same.  Each "_" is any
digit of the given radix, and each 0 must be 0.  The high 1 bit for X
positive and negative become a high non-zero digit.

=head2 Level Ranges

Because the X direction replicates twice for each once in the Y direction
the width grows at twice the rate, so after each 3 replications

    width = height*height

For this reason N values for a given Y grow quite rapidly.

=head2 Proth Numbers

The Proth numbers, k*2^n+1 for S<kE<lt>2^n>, fall in columns on the path.

=cut

# math-image --path=ImaginaryHalf --values=ProthNumbers --text --size=70x25

=pod

    *                               *                               *



    *                               *                               *



    *                               *                               *



    *               *               *               *               *



    *               *               *               *               *

                            *       *       *       *

    *       *       *       *       *       *       *       *       *

                            *   *   *   *   *       *
                                    *
    *       *       *       *   * *   * *   *       *       *       *

    -----------------------------------------------------------------
    -31    -23     -15     -7  -3-1 0 3 5   9      17       25     33

The height of the column is from the zeros in X ending binary ...1000..0001
since this limits the "k" part of the Proth numbers which can have N ending
suitably.  Or for X negative ending ...10111...11.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::ImaginaryBase-E<gt>new ()>

=item C<$path = Math::PlanePath::ImaginaryBase-E<gt>new (radix =E<gt> $r, digit_order =E<gt> $str)>

Create and return a new path object.  The choices for C<digit_order> are

    "XYX"
    "XXY"
    "YXX"
    "XnYX"
    "XnXY"
    "YXnX"

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

Return C<(0, $radix**$level - 1)>.

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::ImaginaryBase>,
L<Math::PlanePath::ZOrderCurve>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
