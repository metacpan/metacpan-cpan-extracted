# Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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


# math-image --path=CubicBase --all --output=numbers --size=60x20
# math-image --path=CubicBase --values=Multiples,multiples=27 --output=numbers --size=60x20

# math-image --path=CubicBase --expression='i<128?i:0' --output=numbers --size=132x20
#

package Math::PlanePath::CubicBase;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 128;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'parameter_info_array',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;
*xy_is_visited = \&Math::PlanePath::Base::Generic::xy_is_even;

# use constant parameter_info_array =>
#   [ Math::PlanePath::Base::Digits::parameter_info_radix2(),
#
#    # Experimental ...
#    # { name      => 'skewed',
#    #   type      => 'boolean',
#    #   default   => 0,
#    # },
# ];

sub x_negative_at_n {
  my ($self) = @_;
  return $self->{'radix'};
}
sub y_negative_at_n {
  my ($self) = @_;
  return $self->{'radix'}**2;
}
use constant absdx_minimum => 2;
use constant dir_maximum_dxdy => (-1, -3);   # supremum

sub turn_any_straight {
  my ($self) = @_;
  return $self->{'radix'} > 2;   # never straight in radix=2
}
sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  return $self->{'radix'} - 1;
}
sub _UNDOCUMENTED__turn_any_right_at_n {
  my ($self) = @_;
  return $self->{'radix'};
}


#------------------------------------------------------------------------------
sub new {
  my $self = shift->SUPER::new(@_);

  my $radix = $self->{'radix'};
  if (! defined $radix || $radix <= 2) { $radix = 2; }
  $self->{'radix'} = $radix;

  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### CubicBase n_to_xy(): "$n"

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  # is this sort of midpoint worthwhile? not documented yet
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

  my $x = 0;
  my $y = 0;

  my $radix = $self->{'radix'};
  if (my @digits = digit_split_lowtohigh($n,$radix)) {
    my $len = ($n * 0) + 1;  # inherit bignum 1
    my $ext = 1;
    for (;;) {
      { # 0 degrees
        $x += (2*(shift @digits)) * $len;    # low to high
      }
      @digits || last;

      if ($ext ^= 1) {
        $len *= $radix;
      }

      { # +120 degrees
        my $dlen = (shift @digits) * $len;   # low to high
        $x -= $dlen;
        $y += $dlen;
      }
      @digits || last;

      if ($ext ^= 1) {
        $len *= $radix;
      }

      { # +240 degrees
        my $dlen = (shift @digits) * $len;   # low to high
        $x -= $dlen;
        $y -= $dlen;
      }
      @digits || last;

      if ($ext ^= 1) {
        $len *= $radix;
      }
    }

    if ($self->{'skewed'}) {
      $x = ($x + $y) / 2;
    }
  }

  ### result: "$x,$y"
  return ($x,$y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### CubicBase xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if (is_infinite($x)) { return ($x); }
  if (is_infinite($y)) { return ($y); }

  if ($self->{'skewed'}) {
    $x = 2*$x - $y;
  } else {
    if (($x + $y) % 2) {
      # nothing on odd squares, only A2 even squares
      return undef;
    }
  }
  # $x = ($x-$y)/2;  # into i,j coordinates

  foreach my $overflow ($x+$y, $x-$y) {
    if (is_infinite($overflow)) { return $overflow; }
  }

  my $radix = $self->{'radix'};
  my $zero = ($x * 0 * $y);  # inherit bignum 0
  my @n; # digits low to high

  if ($x || $y) {
    my $ext = 1;

    for (;;) {
      ### at: "x=$x y=$y"

      {
        my $digit = (($x+$y)/2) % $radix;
        push @n, $digit;
        $x -= 2*$digit;

        ### 0deg digit: $digit
        ### subtract to: "x=$x y=$y"
      }

      last unless $x || $y;
      if ($ext ^= 1) {
        ### assert: ($x % $radix) == 0
        ### assert: ($y % $radix) == 0
        $x = int($x/$radix);
        $y = int($y/$radix);
        ### divide out to: "x=$x y=$y"
      }

      {
        my $digit = (($y-$x)/2) % $radix;
        push @n, $digit;
        $x += $digit;
        $y -= $digit;

        ### 120deg digit: $digit
        ### subtract to: "x=$x y=$y"
      }

      last unless $x || $y;
      if ($ext ^= 1) {
        ### assert: ($x % $radix) == 0
        ### assert: ($y % $radix) == 0
        $x = int($x/$radix);
        $y = int($y/$radix);
        ### divide out to: "x=$x y=$y"
      }

      {
        my $digit = (-$y) % $radix;
        push @n, $digit;
        $x += $digit;
        $y += $digit;

        ### 240deg digit: $digit
        ### subtract to: "x=$x y=$y"
      }

      last unless $x || $y;
      if ($ext ^= 1) {
        ### assert: ($x % $radix) == 0
        ### assert: ($y % $radix) == 0
        $x = int($x/$radix);
        $y = int($y/$radix);
        ### divide out to: "x=$x y=$y"
      }
    }
  }

  return digit_join_lowtohigh (\@n, $radix, $zero);
}

# ENHANCE-ME: Can probably do better by measuring extents in 3 directions
# for a hexagonal boundary.
#
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### CubicBase rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  my $radix = $self->{'radix'};
  my $xm = max(abs($x1),abs($x2)) * $radix*$radix*$radix;
  my $ym = max(abs($y1),abs($y2)) * $radix*$radix*$radix;

  return (0,
          $xm*$xm+$ym*$ym);
}

#------------------------------------------------------------------------------
# levels

use Math::PlanePath::ImaginaryBase;
*level_to_n_range = \&Math::PlanePath::ImaginaryBase::level_to_n_range;
*n_to_level = \&Math::PlanePath::ImaginaryBase::n_to_level;


#------------------------------------------------------------------------------
1;
__END__

# xy_to_n() high to low
#
# use Math::PlanePath::Base::Digits
#   'round_down_pow';
#
# my ($len, $level) = round_down_pow(abs($x)+abs($y), $radix);
# $len *= $radix;
# $level++;
# $len *= $radix;
# ### $level
# ### $len
#
# for (;;) {
#   ### at: "x=$x y=$y"
#
#   {
#     my $k = -$y;
#     my $digit = ($k >= 0
#                  ? int($k/$len)
#                  : -int(-$k/$len));
#     $n = $n*$radix + $digit;
#     $x += $digit*$len;
#     $y += $digit*$len;
#
#     ### 240deg digit: $digit
#     ### add to: "x=$x y=$y"
#   }
#
#   $len = int($len/$radix);
#   ### $len
#
#   {
#     my $k = $y;
#     my $digit = int($k/$len) % $radix;
#     $n = $n*$radix + $digit;
#     $x += $digit*$len;
#     $y -= $digit*$len;
#
#     ### 120deg digit: $digit
#     ### subtract to: "x=$x y=$y"
#   }
#
#   {
#     my $digit = ($x >= 0
#                  ? int($x/(2*$len))
#                  : -int(-$x/(2*$len)));
#     $n = $n*$radix + $digit;
#     $x -= 2*$digit;
#
#     ### 0deg digit: $digit
#     ### subtract to: "x=$x y=$y"
#   }
#
#   last unless $level-- > 0;
#
# }


=for stopwords eg Ryde Math-PlanePath Radix ie radix

=head1 NAME

Math::PlanePath::CubicBase -- replications in three directions

=head1 SYNOPSIS

 use Math::PlanePath::CubicBase;
 my $path = Math::PlanePath::CubicBase->new (radix => 4);
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is a pattern of replications in three directions 0, 120 and 240 degrees.

=cut

# these numbers generated with
#   math-image --path=CubicBase --expression='i<64?i:0' --output=numbers --size=132x20

=pod

                       18    19    26    27                      5
                          16    17    24    25                   4
                 22    23    30    31                            3
                    20    21    28    29                         2
           50    51    58    59     2     3    10    11          1
              48    49    56    57     0     1     8     9   <- Y=0
     54    55    62    63     6     7    14    15               -1
        52    53    60    61     4     5    12    13            -2
                       34    35    42    43                     -3
                          32    33    40    41                  -4
                 38    39    46    47                           -5
                    36    37    44    45                        -6

                                       ^
    -11-10 -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6

The points are on a triangular grid by using every second integer X,Y, as
per L<Math::PlanePath/Triangular Lattice>.  All points on that triangular
grid are visited.

The initial N=0,N=1 is replicated at +120 degrees.  Then that trapezoid at
+240 degrees

    +-----------+                       +-----------+
     \  2     3  \                       \  2     3  \
      +-----------+                       \           \
        \  0     1  \                       \  0     1  \
         +-----------+             ---------  -----------+
                                   \  6     7  \
      replicate +120deg              \          \    rep +240deg
                                      \  4     5 \
                                       +----------+

Then that bow-tie N=0to7 is replicated at 0 degrees again.  Each replication
is 1/3 of the circle around, 0, 120, 240 degrees repeating.  The relative
layout within a replication is unchanged.

                      -----------------------
                      \ 18    19    26    27 \
                       \                       \
                        \  16    17    24    25 \
               ----------              ----------
                \ 22    23    30    31 \
                  \                      \
                   \ 20    21    28    29  \
          --------- ------------ +----------- -----------
          \ 50    51    58    59  \  2     3  \ 10    11 \
            \                      +-----------+           \
             \ 48    49    56    57  \  0     1  \  8     9 \
    ----------              --------- +-----------  ---------+
    \ 54    55    62    63  \  6     7  \ 14    15  \
     \                        \          \            \
       \ 52    53    60    61  \  4     5 \  12    13  \
        --------------          +----------+------------
                      \ 34    35    42    43 \
                       \                       \
                        \  32    33    40    41 \
                ---------+            -----------
                \ 38    39    46    47 \
                 \                       \
                   \ 36    37    44    45 \
                    -----------------------

The radial distance doubles on every second replication, so N=1 and N=2 are
at 1 unit from the origin, then N=4 and N=8 at 2 units, then N=16 and N=32
at 4 units.  N=64 is not shown but is then at 8 units away (X=8,Y=0).

This is similar to the C<ImaginaryBase>, but where that path repeats in 4
directions based on i=squareroot(-1), here it's 3 directions based on
w=cuberoot(1) = -1/2+i*sqrt(3)/2.

=head2 Radix

The C<radix> parameter controls the "r" used to break N into X,Y.  For
example radix 4 gives 4x4 blocks, with r-1 replications of the preceding
level at each stage.

=cut

# math-image --path=CubicBase,radix=4 --expression='i<64?i:0' --output=numbers --size=150x30

=pod

       3         radix => 4              12    13    14    15
       2                                     8     9    10    11
       1                                        4     5     6     7
     Y=0 ->                                        0     1     2     3
      -1                     28    29    30    31
      -2                        24    25    26    27
      -3                           20    21    22    23
      -4                              16    17    18    19
      -5         44    45    46    47
      ...           40    41    42    43
                       36    37    38    39
                          32    33    34    35
     60    61    62    63
        56    57    58    59
           52    53    54    55
              48    49    50    51

                                                   ^
    -15-14-13-12-11-10 -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6

Notice the parts always replicate away from the origin, so the block N=16 to
N=31 is near the origin at X=-4, then N=32,48,64 are further away.

In this layout the replications still mesh together perfectly and all points
on the triangular grid are visited.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::CubicBase-E<gt>new ()>

=item C<$path = Math::PlanePath::CubicBase-E<gt>new (radix =E<gt> $r)>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, $radix**$level - 1)>.

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::ImaginaryBase>,
L<Math::PlanePath::ImaginaryHalf>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
