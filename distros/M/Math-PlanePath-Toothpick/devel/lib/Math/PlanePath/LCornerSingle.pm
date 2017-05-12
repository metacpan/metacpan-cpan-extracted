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


# A160414 starting from one cell
# A161415   added
# http://www.polprimos.com/imagenespub/polca025.jpg
#
#     9...............9
#     .888.888.888.888.
#     .878.878.878.878.
#     .8866688.8866688.
#     ...656.....656...
#     .8866444.4446688.
#     .878.434.434.878.
#     .888.4422244.888.
#     .......212.......
#     .888.4422244.888.
#     .878.434.434.878.
#     .8866444.4446688.
#     ...656.....656...
#     .8866688.8866688.
#     .878.878.878.878.
#     .888.888.888.888.
#     9...............9

package Math::PlanePath::LCornerSingle;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 18;
use Math::PlanePath;
@ISA = ('Math::PlanePath');



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






use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'bit_split_lowtohigh',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

use Math::PlanePath::UlamWarburtonQuarter;

# uncomment this to run the ### lines
#use Smart::Comments;

use constant n_start => 0;

sub new {
  my $self = shift->SUPER::new(@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

my @next_state = (0,12,0,4, 4,0,4,8, 8,4,8,12, 12,8,12,0);
my @digit_to_x = (0,1,1,0, 1,1,0,0, 1,0,0,1, 0,0,1,1);
my @digit_to_y = (0,0,1,1, 0,1,1,0, 1,1,0,0, 1,0,0,1);

sub n_to_xy {
  my ($self, $n) = @_;
  ### LCornerSingle n_to_xy(): $n

  if ($n < $self->{'n_start'}) { return; }
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

  $n = $n - $self->{'n_start'};  # N=0 basis
  if ($n == 0 || is_infinite($n)) { return ($n,$n); }

  my $zero = ($n * 0); # inherit bignum 0
  my ($depthbits, $ndepth, $nwidth) = _n0_to_depthbits($n);

  ### $n
  ### $ndepth
  ### $nwidth
  ### $depthbits

  $n -= $ndepth;  # N remainder offset into row
  ### assert: $n >= 0
  ### assert: $n < $nwidth

  # like a mixed-radix high digit radix 4 then rest radix 3
  $nwidth /= 4;
  (my $quad, $n) = _divrem($n,$nwidth);
  ### $quad
  ### assert: $quad >= 0
  ### assert: $quad < 4

  my $all_ones = ! scalar(grep{$_==0}@$depthbits);
  die if $n >= $nwidth;
  if ($all_ones) {
    my $end = 2 * 2 ** ($#$depthbits-2);
    if ($n >= $nwidth - $end) {
      $n += $end + 2**($#$depthbits-2);
      # return;
    }
  }

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
  my $x = digit_join_lowtohigh (\@xbits, 2, $zero);
  my $y = digit_join_lowtohigh (\@ybits, 2, $zero);

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
  ### LCornerSingle xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  my $quad = 0;
  if ($y < 0) {
    $x = -$x; # rotate +180
    $y = -$y;
    $quad = 2;
  }
  if ($x < 0) {
    ($x,$y) = ($y,-$x); # rotate +90 and offset
    $quad++;
  }
  ### $quad
  ### quad rotated xy: "$x,$y"

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
  my $n = $zero;
  my $ndigits = $zero;

  foreach my $i (reverse 0 .. $exp) {
    ### at: "x=$x,y=$y  n=$n len=$len"

    ### assert: $x >= 0
    ### assert: $y >= 0
    ### assert: $x < 2 * $len
    ### assert: $y < 2 * $len
    ### assert: $len == int($len)

    if ($depthbits[$i] = ($x >= $len || $y >= $len ? 1 : 0)) {
      # one of the three parts away from the origin
      $n *= 3;
      $ndigits++;

      if ($y < $len) {
        ### lower right, digit 0 ...
        ($x,$y) = ($len-1-$y,$x-$len);  # rotate +90 and offset
      } elsif ($x >= $len) {
        ### diagonal, digit 1 ...
        ### right, digit 1 ...
        $x -= $len;
        $y -= $len;
        $n += 1;
      } else {
        ### top left, digit 2 ...
        ($x,$y) = ($y-$len,$len-1-$x);  # rotate -90 and offset
        $n += 2;
      }
    }

    $len /= 2;
  }

  my $depth = digit_join_lowtohigh(\@depthbits,2,$zero);

  ### $n
  ### @depthbits
  ### $depth
  ### $ndigits
  ### npower: 3**$ndigits
  ### $quad
  ### quad powered: $quad*3**$ndigits
  ### result: $n + $quad*3**$ndigits + $self->tree_depth_to_n($depth)

  return $n + $quad*3**$ndigits + $self->tree_depth_to_n($depth);
}

#use Smart::Comments;

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### LCornerSingle rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);

  my $depth_hi = max($x1, $x2,
                     $y1, $y2);
  ### $depth_hi
  ($depth_hi) = round_down_pow($depth_hi,2);
  ### $depth_hi
  ### depth_to_n: $self->tree_depth_to_n($depth_hi+1)
  return ($self->{'n_start'},
          32*$self->tree_depth_to_n(2*$depth_hi) - 1);
}

sub tree_depth_to_n {
  my ($self, $depth) = @_;
  ### tree_depth_to_n(): "depth=$depth"

  if (is_infinite($depth)) {
    return $depth;
  }
  unless ($depth >= 0) {
    return undef;
  }
  my $n = ($depth*0);    # bignum 0
  my $pow3 = $n + 4; # bignum 4

  foreach my $bit (reverse bit_split_lowtohigh($depth)) {  # high to low
    $n *= 4;
    if ($bit) {
      $n += $pow3;
      $pow3 *= 3;
    }
  }
  return $n + $self->{'n_start'};
}

sub tree_n_to_depth {
  my ($self, $n) = @_;
  ### LCornerSingle n_to_xy(): $n

  if ($n < $self->{'n_start'}) { return undef; }
  $n = int($n) - $self->{'n_start'};  # N=0 basis
  if (is_infinite($n)) { return $n; }
  if ($n == 0) {
    return $n; # depth=0
  }

  my ($depthbits) = _n0_to_depthbits ($n);
  return digit_join_lowtohigh ($depthbits, 2, $n*0);
}


# depth=2^k
# total=(2d-1)^2
# d=2 total=3^2=9
# d=4 total=7^2=49
# N=(2*2^d-1)^2
# 2*2^d-1 = sqrt(N)
# 2*2^d = sqrt(N)+1

# 4  49
# 5  61  +12
# 6  97  +36     12+36=48=3*16
# 7  133 +36
# 8  225 +92 = 108 - 16         36+92=144
#

sub _n0_to_depthbits {
  my ($n) = @_;
  ### _n0_to_depthbits(): $n

  if ($n < 1) {
    ### initial point ...
    return ([], 0, 1);
  }
  if ($n < 9) {
    ### second ...
    return ([1], 1, 8);
  }

  my ($ndepth, $bitpos) = round_down_pow (sqrt($n)+1, 2);
  my $nwidth = 3*$ndepth*$ndepth/4;
  $ndepth = ($ndepth-1)**2;
  my @depthbits;
  $bitpos--;
  $depthbits[$bitpos--] = 1;
  my $all_ones = 1;

  ### $ndepth
  ### $nwidth
  ### $bitpos

  for (;;) {
    ### at: "n=$n ndepth=$ndepth nwidth=$nwidth bitpos=$bitpos depthbits=".join(',',map{$_//'_'}@depthbits)
    if ($n >= $ndepth + $nwidth) {
      $depthbits[$bitpos] = 1;
      $ndepth += $nwidth;
      $nwidth *= 3;
    } else {
      $depthbits[$bitpos] = 0;
      $all_ones = 0;
    }
    $bitpos--;
    last unless $bitpos >= 0;
    $nwidth /= 4;
  }

  if ($all_ones) {
        $nwidth -= 2 ** ($#depthbits+2);
  }

  ### return ...
  ### @depthbits
  ### $ndepth
  ### $nwidth

  return (\@depthbits, $ndepth, $nwidth);
}

# ENHANCE-ME: step by the bits, not by X,Y
# ENHANCE-ME: tree_n_to_depth() by probe
my @surround8_dx = (1, 0, -1, 0, 1, -1, 1, -1);
my @surround8_dy = (0, 1, 0, -1, 1, 1, -1, -1);
sub tree_n_children {
  my ($self, $n) = @_;
  ### LCornerSingle tree_n_children(): $n

  if ($n < $self->{'n_start'}) {
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
  ### LCornerSingle tree_n_parent(): $n

  if ($n < $self->{'n_start'} + 1) {
    return undef;
  }
  my $want_depth = $self->tree_n_to_depth($n) - 1;
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

1;
__END__

=for stopwords eg Ryde Math-PlanePath-Toothpick Nstart OEIS ie

=head1 NAME

Math::PlanePath::LCornerSingle -- growth of a 2-D cellular automaton

=head1 SYNOPSIS

 use Math::PlanePath::LCornerSingle;
 my $path = Math::PlanePath::LCornerSingle->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is the pattern of a cellular automaton growing by 3 cells from an
exposed corner at each growth level, starting from a single cell at the
origin.

    68  67                          66  65      4
    69  41  40  39  38  35  34  33  32  64      3
        42  20  19  12      11  10  31  ...     2
        43  21   8   4   3   2   9  30          1
        44  45   9   5   0   1  28  29     <- Y=0
        47  46  10   6   7   8  63  62         -1
        48  22  11  12  13  14  27  61         -2
        49  23  24  54  55  25  26  60         -3
    70  50  51  52  53  56  57  58  59  75     -4
    71  72                          73  74     -5
                         ^
    -5  -4  -3  -2  -1  X=0  1   2   3   4

        +-----+              +-----+
        |     |              |     |
        |  +--------------------+  |
        |  |     |     |  |     |  |
        +--|  +-----+  +-----+  |--+
           |  |     |  |     |  |
           |--|  +--+-----+  |--|
           |  |  |        |  |  |
           |-----|  +--+  |--+  |
           |     |  |  |  |     |
           |  +--|  +--+  |-----|
           |  |  |        |  |  |
           |--|  +--+-----+  |--|
           |  |     |  |     |  |
        +--|  +-----|  +-----+  |--+
        |  |     |  |     |     |  |
        |  +--------------------+  |
        |     |              |     |
        +-----+              +-----+

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::LCornerSingle-E<gt>new ()>

Create and return a new path object.

=back

=head2 Tree Methods

=over

=item C<@n_children = $path-E<gt>tree_n_children($n)>

Return the children of C<$n>, or an empty list if C<$n> has no children
(including when C<$n E<lt> 1>, ie. before the start of the path).

The children of a corner C<$n> are the three cells adjacent to it turned on
at the next depth.  A non-corner has no children.

=back

=head1 OEIS

This cellular automaton is in Sloane's Online Encyclopedia of Integer
Sequences as

=over

L<http://oeis.org/A160414> (etc)

=back

    A160414   total cells at given depth (Ndepth)
    A161415   added cells at given depth, 4*3^count1bits(n)

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::LCornerReplicate>,
L<Math::PlanePath::UlamWarburton>

C<http://www.polprimos.com/imagenespub/polca025.jpg>, drawing of growth
levels by Omar Pol.

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
