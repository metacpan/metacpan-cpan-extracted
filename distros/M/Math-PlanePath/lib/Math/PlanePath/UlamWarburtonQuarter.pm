# Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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


package Math::PlanePath::UlamWarburtonQuarter;
use 5.004;
use strict;
use Carp 'croak';
use List::Util 'sum';

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'bit_split_lowtohigh',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant parameter_info_array =>
  [
   { name            => 'parts',
     share_key       => 'parts_ulamwarburton_quarter',
     display         => 'Parts',
     type            => 'enum',
     default         => '1',
     choices         => ['1','octant','octant_up' ],
     choices_display => ['1','Octant','Octant Up' ],
     description     => 'Which parts of the plane to fill.',
   },
   Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];

use constant class_x_negative => 0;
use constant class_y_negative => 0;

sub diffxy_minimum {
  my ($self) = @_;
  return ($self->{'parts'} eq 'octant' ? 0 : undef);
}
sub diffxy_maximum {
  my ($self) = @_;
  return ($self->{'parts'} eq 'octant_up' ? 0 : undef);
}

# Minimum dir=0 at N=13 dX=2,dY=0.
# Maximum dir seems dX=13,dY=-9 at N=149 going top-left part to new bottom
# right diagonal.
my %dir_maximum_dxdy = (1         => [13,-9],
                        octant    => [1,-1],  # South-East
                        octant_up => [0,-1],  # South
                       );
sub dir_maximum_dxdy {
  my ($self) = @_;
  return @{$dir_maximum_dxdy{$self->{'parts'}}};
}

sub tree_num_children_list {
  my ($self) = @_;
  return ($self->{'parts'} =~ /octant/
          ? (0, 1, 2, 3)
          : (0, 1,    3));
}

#------------------------------------------------------------------------------
sub new {
  my $self = shift->SUPER::new(@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  my $parts = ($self->{'parts'} ||= '1');
  if (! exists $dir_maximum_dxdy{$parts}) {
    croak "Unrecognised parts option: ", $parts;
  }
  return $self;
}

# 7   7   7   7
#   6       6
# 7   5   5   7
#       4
# 3   3   5   7
#   2       6
# 1   3   7   7
#
# 1+1+3=5
# 5+1+3*5=21
# 1+3 = 4
# 1+3+3+9 = 16
#
#       0
# 1  0 +1
# 2  1 +1       <- 1
# 3  2 +3
# 4  5 +1       <- 1 + 4 = 5
# 5  6 +3
# 6  9 +3
# 7  12 +9
# 8  21         <- 1 + 4 + 16 = 21

# 1+3 = 4  power 2
# 1+3+3+9 = 16    power 3
# 1+3+3+9+3+9+9+27 = 64    power 4
#
# (1+4+16+...+4^(l-1)) = (4^l-1)/3
#    l=1 total=(4-1)/3 = 1
#    l=2 total=(16-1)/3 = 5
#    l=3 total=(64-1)/3=63/3 = 21
#
# n = 1 + (4^l-1)/3
# n-1 = (4^l-1)/3
# 3n-3 = (4^l-1)
# 3n-2 = 4^l
#
# 3^0+3^1+3^1+3^2 = 1+3+3+9=16
# x+3x+3x+9x = 16x = 256
#
#               22
# 20  19  18  17
#   12      11
# 21   9   8  16
#        6
#  5   4   7  15
#    2      10
#  1   3  13  14
#

sub n_to_xy {
  my ($self, $n) = @_;
  ### UlamWarburtonQuarter n_to_xy(): $n

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

  $n = $n - $self->{'n_start'} + 1;  # N=1 basis
  if ($n == 1) { return (0,0); }

  my ($depthsum, $nrem, $rowwidth) = _n1_to_depthsum_rem_width($self,$n)
    or return ($n,$n); # N==nan or N==+inf

  ### assert: $nrem >= 0
  ### assert: $nrem < $width
  if ($self->{'parts'} eq 'octant_up') {
    $nrem += ($rowwidth-1)/2;
    ### assert: $nrem < $width
  }

  my @ndigits = digit_split_lowtohigh($nrem,3);
  my $dhigh = shift(@$depthsum) - 1;  # highest term
  my $x = 0;
  my $y = 0;
  foreach my $depthsum (reverse @$depthsum) { # depth terms low to high
    my $ndigit = shift @ndigits;              # N digits low to high
    ### $depthsum
    ### $ndigit

    $x += $depthsum;
    $y += $depthsum;
    ### depthsum to xy: "$x,$y"

    if ($ndigit) {
      if ($ndigit == 2) {
        ($x,$y) = (-$y,$x);   # rotate +90
      }
    } else {
      # digit==0 (or undef when run out of @ndigits)
      ($x,$y) = ($y,-$x);   # rotate -90
    }
    ### rotate to: "$x,$y"
  }

  ### final: "$x,$y"
  return ($dhigh + $x, $dhigh + $y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### UlamWarburtonQuarter xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  my $parts = $self->{'parts'};
  if ($y < 0
      || $x < ($parts eq 'octant' ? $y : 0)
      || ($parts eq 'octant_up' && $x > $y)) {
    return undef;
  }
  if ($x == 0 && $y == 0) {
    return $self->{'n_start'};
  }
  $x += 1;  # pushed away by 1 ...
  $y += 1;

  my ($len, $exp) = round_down_pow ($x + $y, 2);
  if (is_infinite($exp)) { return $exp; }

  my $depth
    = my $n
      = ($x * 0 * $y);  # inherit bignum 0
  my $rowwidth = $depth + 1;

  while ($exp-- >= 0) {
    ### at: "$x,$y  n=$n len=$len"

    # first quadrant square
    ### assert: $x >= 0
    ### assert: $y >= 0
    # ### assert: $x < 2*$len
    # ### assert: $y < 2*$len

    if ($x >= $len || $y >= $len) {
      # one of three quarters away from origin
      #     +---+---+
      #     | 2 | 1 |
      #     +---+---+
      #     |   | 0 |
      #     +---+---+

      $x -= $len;
      $y -= $len;
      ### shift to: "$x,$y"

      if ($x) {
        unless ($y) {
          return undef;  # x==0, y!=0, nothing
        }
      } else {
        if ($y) {
          return undef;  # x!=0, y-=0, nothing
        }
      }

      $depth += $len;
      if ($x || $y) {
        $rowwidth *= 3;
        $n *= 3;
        if ($y < 0) {
          ### bottom right, digit 0 ...
          ($x,$y) = (-$y,$x);  # rotate +90
        } elsif ($x >= 0) {
          ### top right, digit 1 ...
          $n += 1;
        } else {
          ### top left, digit 2 ...
          ($x,$y) = ($y,-$x);  # rotate -90
          $n += 2;
        }
      }
    }

    $len /= 2;
  }

  ### $n
  ### $depth

  if ($self->{'parts'} eq 'octant_up') {
    $n -= ($rowwidth-1)/2;
  }

  return $n + $self->tree_depth_to_n($depth-1);
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### UlamWarburtonQuarter rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  if ($x2 < 0 || $y2 < 0) {
    return (1, 0);  # all outside first quadrant
  }

  if ($x1 < 0) { $x1 *= 0; }
  if ($y1 < 0) { $y1 *= 0; }

  # level numbers
  my $dlo = ($x1 > $y1 ? $x1 : $y1)+1;
  my $dhi = ($x2 > $y2 ? $x2 : $y2);
  ### $dlo
  ### $dhi

  # round down to level=2^k numbers
  if ($dlo) {
    ($dlo) = round_down_pow ($dlo,2);
  }
  ($dhi) = round_down_pow ($dhi,2);

  ### rounded to pow2: "$dlo  ".(2*$dhi)

  return ($self->tree_depth_to_n($dlo-1),
          $self->tree_depth_to_n(2*$dhi-1));
}

#------------------------------------------------------------------------------
use constant tree_num_roots => 1;

# ENHANCE-ME: step by the bits, not by X,Y
sub tree_n_children {
  my ($self, $n) = @_;
  if ($n < $self->{'n_start'}) {
    return;
  }
  my ($x,$y) = $self->n_to_xy($n);
  my @ret;
  my $dx = 1;
  my $dy = 1;
  foreach (1 .. 4) {
    if (defined (my $n_child = $self->xy_to_n($x+$dx,$y+$dy))) {
      if ($n_child > $n) {
        push @ret, $n_child;
      }
    }
    ($dx,$dy) = (-$dy,$dx); # rotate +90
  }
  return sort {$a<=>$b} @ret;
}
sub tree_n_parent {
  my ($self, $n) = @_;
  if ($n <= $self->{'n_start'}) {
    return undef;
  }
  my ($x,$y) = $self->n_to_xy($n);
  my $dx = 1;
  my $dy = 1;
  foreach (1 .. 4) {
    if (defined (my $n_parent = $self->xy_to_n($x+$dx,$y+$dy))) {
      if ($n_parent < $n) {
        return $n_parent;
      }
    }
    ($dx,$dy) = (-$dy,$dx); # rotate +90
  }
  return undef;
}

# level = depth+1 = 2^a + 2^b + 2^c + 2^d ...       a>b>c>d...
# Ndepth = 1 + (-1
#               +       4^a
#               +   3 * 4^b
#               + 3^2 * 4^c
#               + 3^3 * 4^d + ...) / 3
sub tree_depth_to_n {
  my ($self, $depth) = @_;
  ### tree_depth_to_n(): $depth
  if (is_infinite($depth)) {
    return $depth;
  }
  unless ($depth >= 0) {
    return undef;
  }
  my $n = $depth*0;        # inherit bignum 0
  my $pow3 = 1 + $n;       # inherit bignum 1
  foreach my $bit (reverse bit_split_lowtohigh($depth+1)) {  # high to low
    $n *= 4;
    if ($bit) {
      $n += $pow3;
      $pow3 *= 3;
    }
  }
  if ($self->{'parts'} =~ /octant/) {
    $n = ($n + (3*$depth-1))/6;
  } else {
    $n = ($n-1)/3;
  }
  return $n + $self->{'n_start'};
}

sub tree_n_to_depth {
  my ($self, $n) = @_;

  $n = int($n - $self->{'n_start'} + 1);  # N=1 basis
  if ($n < 1) {
    return undef;
  }
  (my $depthsum, $n) = _n1_to_depthsum_rem_width($self,$n)
    or return $n;  # N==nan or N==+infinity
  return sum(-1, @$depthsum);
}

# Return ($aref, $remaining_n).
# sum(@$aref) = depth starting depth=1
#
# depth+1 = 2^k
# Ndepth(depth) = (4^k+2)/3
#   3N-2 = 4^k
# NdepthOct(depth) = ((4^k+2)/3 + 2^k)/2
#   6N-2 = 4^k + 3*2^k
#
sub _n1_to_depthsum_rem_width {
  my ($self, $n) = @_;
  ### _n1_to_depthsum_rem_width(): $n

  my $octant = ($self->{'parts'} =~ /octant/);
  my ($power, $exp) = round_down_pow (($octant ? 6 : 3)*$n - 2, 4);
  if (is_infinite($exp)) {
    return;
  }

  ### $power
  ### $exp
  ### pow base: ($power - 1)/3 + 1

  {
    my $sub = ($power + 2)/3;  # (power-1)/3 + 1
    if ($octant) {
      $sub = ($sub + 2**$exp) / 2;
      ### prospective sub: $sub
      ### assert: $sub == ($power + 3 * 2 ** $exp + 2)/6

      if ($sub > $n) {
        $exp -= 1;
        $power /= 4;
        $sub = ($power + 3*2**$exp + 2)/6;
      }
    }
    ### assert: $sub <= $n
    $n -= $sub;
  }
  ### n less pow base: $n

  my @depthsum = (2**$exp);

  # find the cumulative levelpoints total <= $n, being the start of the
  # level containing $n
  #
  my $factor = 1;
  while (--$exp >= 0) {
    $power /= 4;
    my $sub = $power * $factor;
    if ($octant) {
      $sub = ($sub + 2**$exp)/2;
    }
    ### $sub
    my $rem = $n - $sub;

    ### $n
    ### $power
    ### $factor
    ### consider subtract: $sub
    ### $rem

    if ($rem >= 0) {
      $n = $rem;
      push @depthsum, 2**$exp;
      $factor *= 3;
    }
  }

  ### _n1_to_depthsum_rem_width() result ...
  ### @depthsum
  ### remaining n: $n
  ### assert: $n >= 0
  ### assert: $n < $factor

  return (\@depthsum, $n, $factor);
}


# at 0,2 turn and new height limit
# at 1 keep existing depth limit
# N=30 rem=1 = 0,1 depth=11=8+2+1=1011 width=9
#
sub tree_n_to_subheight {
  my ($self, $n) = @_;
  ### tree_n_to_subheight(): $n

  $n = int($n - $self->{'n_start'} + 1);  # N=1 basis
  if ($n < 1) {
    return undef;
  }
  my ($depthsum, $nrem, $rowwidth) = _n1_to_depthsum_rem_width($self,$n)
    or return $n;  # N==nan or N==+infinity
  ### $depthsum
  ### $nrem

  if ($self->{'parts'} eq 'octant_up') {
    $nrem += ($rowwidth-1)/2;
  }

  my $sub = pop @$depthsum;
  while (@$depthsum && _divrem_mutate($nrem,3) == 1) {
    $sub += pop @$depthsum;
  }
  if (@$depthsum) {
    return $depthsum->[-1] - 1 - $sub;
  } else {
    return undef; # $nrem all 1-digits
  }
}

#------------------------------------------------------------------------------
# levels

sub level_to_n_range {
  my ($self, $level) = @_;
  return ($self->{'n_start'},
          $self->tree_depth_to_n_end(2**($level+1) - 2));
}
sub n_to_level {
  my ($self, $n) = @_;
  my $depth = $self->tree_n_to_depth($n);
  if (! defined $depth) { return undef; }
  my ($pow, $exp) = round_down_pow ($depth+1, 2);
  return $exp;
}

#------------------------------------------------------------------------------
1;
__END__

# Octant                    depth  0  1  1
#                 15               1  2  2
#              14                  2  3  3,4
#            9                     3  4  5
#          7   13                  4  5  6,7
#        5                         5  6  8,9
#      4   6   12                  6  7  10,11,12,13,14
#    2       8                     7  8  15
#  1   3  10   11
#
# Ndepth 2*oct-depth = quad
#        oct = (quad+depth)/2



=for stopwords eg Ryde Math-PlanePath Ulam Warburton Ndepth Nend ie OEIS Octant octant

=head1 NAME

Math::PlanePath::UlamWarburtonQuarter -- growth of a 2-D cellular automaton

=head1 SYNOPSIS

 use Math::PlanePath::UlamWarburtonQuarter;
 my $path = Math::PlanePath::UlamWarburtonQuarter->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Ulam, Stanislaw>X<Warburton>This is the pattern of a cellular automaton
studied by Ulam and Warburton, confined to a quarter of the plane and
oriented diagonally.  Cells are numbered by growth tree row and
anti-clockwise within the row.

=cut

# math-image --path=UlamWarburtonQuarter --all --output=numbers --size=70x15

=pod

    14 |  81    80    79    78    75    74    73    72
    13 |     57          56          55          54
    12 |  82    48    47    77    76    46    45    71
    11 |           40                      39
    10 |  83    49    36    35    34    33    44    70
     9 |     58          28          27          53
     8 |  84    85    37    25    24    32    68    69
     7 |                       22
     6 |  20    19    18    17    23    31    67    66
     5 |     12          11          26          52
     4 |  21     9     8    16    29    30    43    65
     3 |            6                      38
     2 |   5     4     7    15    59    41    42    64
     1 |      2          10          50          51
    Y=0|   1     3    13    14    60    61    62    63
       +----------------------------------------------
         X=0  1  2  3  4  5  6  7  8  9 10 11 12 13 14

The growth rule is a given cell grows diagonally NE, NW, SE and SW, but only
if the new cell has no neighbours and is within the first quadrant.  So the
initial cell "a" is N=1,


    |
    | a                    initial cell, depth=0
    +----

It's confined to the first quadrant so can only grow NE as "b",

    |   b
    | a                    "b" depth=1
    +------

Then the next row "c" cells can go in three directions SE, NE, NW.  These
cells are numbered anti-clockwise around from the SE as N=3,N=4,N=5.

    | c   c
    |   b
    | a   c                "c" depth=2
    +---------

The "d" cell is then only a single on the leading diagonal, since the other
diagonals all already have neighbours (the existing "c" cells).

    |       d
    | c   c                depth=3
    |   b
    | a   c
    +---------

    |     e   e
    |       d
    | c   c   e            depth=4
    |   b
    | a   c
    +-----------

    |   f       f
    |     e   e
    |       d
    | c   c   e            depth=5
    |   b       f
    | a   c
    +-------------

    | g   g   g   g
    |   f       f
    | g   e   e   g
    |       d
    | c   c   e   g        depth=6
    |   b       f
    | a   c   g   g
    +-------------

In general the pattern always always grows by 1 along the X=Y leading
diagonal.  The point on that diagonal is the middle of row depth=X.  The
pattern expands into the sides with a self-similar diamond shaped pattern
filling 6 of 16 cells in any 4x4 square block.

=head2 Tree Row Ranges

Counting depth=0 as the N=1 at the origin, depth=1 as the next N=2, etc, the
number of new cells added in the tree row is

    rowwidth(depth) = 3^(count_1_bits(depth+1) - 1)

=for GP-DEFINE  rowwidth(depth) = 3^(hammingweight(depth+1) - 1)

=for GP-Test  rowwidth(0) == 1   /* a */

=for GP-Test  rowwidth(1) == 1   /* b */

=for GP-Test  rowwidth(2) == 3   /* c */

=for GP-Test  rowwidth(3) == 1   /* d */

So depth=0 has 3^(1-1)=1 cells, as does depth=1 which is N=2.  Then depth=2
has 3^(2-1)=3 cells N=3,N=4,N=5 because depth+1=3=0b11 has two 1 bits in
binary.  The N row start and end is the cumulative total of those before it,

    Ndepth(depth) = 1 + rowwidth(0) + ... + rowwidth(depth-1)

    Nend(depth) = rowwidth(0) + ... + rowwidth(depth)

For example depth=2 ends at N=(1+1+3)=5.

=for GP-DEFINE  Ndepth(depth) = 1 + sum(i=0,depth-1, rowwidth(i))

=for GP-DEFINE  Nend(depth) = sum(i=0,depth, rowwidth(i))

=for GP-Test  Nend(2) == 5

    depth    Ndepth    rowwidth      Nend
      0          1         1           1
      1          2         1           2
      2          3         3           5
      3          6         1           6
      4          7         3           9
      5         10         3          12
      6         13         9          21
      7         22         1          22
      8         23         3          25

=for GP-Test  vector(9,depth,my(depth=depth-1); Ndepth(depth)) == [1,2,3,6,7,10,13,22,23]

=for GP-Test  vector(9,depth,my(depth=depth-1); rowwidth(depth)) == [1,1,3,1,3,3,9,1,3]

=for GP-Test  vector(9,depth,my(depth=depth-1); Nend(depth)) == [1,2,5,6,9,12,21,22,25]

At row depth+1 = power-of-2 the Ndepth sum is

    Ndepth(depth) = 1 + (4^a-1)/3       for depth+1 = 2^a

For example depth=3 is depth+1=2^2 starts at N=1+(4^2-1)/3=6, or depth=7 is
depth+1=2^3 starts N=1+(4^3-1)/3=22.

=for GP-Test  Ndepth(3) == 6

=for GP-Test  Ndepth(7) == 22

Further bits in the depth+1 contribute powers-of-4 with a tripling for each
bit above it.  So if depth+1 has bits a,b,c,d,etc from high to low then

    depth+1 = 2^a + 2^b + 2^c + 2^d ...       a>b>c>d...
    Ndepth = 1 + (-1
                  +       4^a
                  +   3 * 4^b
                  + 3^2 * 4^c
                  + 3^3 * 4^d + ...) / 3

For example depth=5 is depth+1=6 = 2^2+2^1 is Ndepth = 1+(4^2-1)/3 + 4^1 =
10.  Or depth=6 is depth+1=7 = 2^2+2^1+2^0 is Ndepth = 1+(4^2-1)/3 + 4^1 +
3*4^0 = 13.

=head2 Self-Similar Replication

The square shape growth to depth=2^level-2 repeats the pattern to the
preceding depth=2^(level-1)-2 three times.  For example,

    |  d   d   c   c             depth=6 = 2^3-2
    |    d       c               triplicates
    |  d   d   c   c             depth=2 = 2^2-2
    |        *
    |  a   a   b   b
    |    a       b
    |  a   a   b   b
    +--------------------

The 3x3 square "a" repeats, pointing SE, NE and NW as "b", "c" and "d".
This resulting 7x7 square then likewise repeats.  The points in the path
here are numbered by tree rows rather than by this sort of replication, but
the replication helps to see the structure of the pattern.

=head2 Octant

Option C<parts =E<gt> 'octant'> confines the pattern to the first eighth of
the plane 0E<lt>=YE<lt>=X.

=cut

# math-image --path=UlamWarburtonQuarter,parts=octant --all --output=numbers --size=75x15

=pod

    parts => "octant"

     14 |                                           50
     13 |                                        36
     12 |                                     31    49
     11 |                                  26
     10 |                               24    30    48
      9 |                            19          35
      8 |                         17    23    46    47
      7 |                      15
      6 |                   14    16    22    45    44
      5 |                 9          18          34
      4 |              7    13    20    21    29    43
      3 |           5                      25
      2 |        4     6    12    37    27    28    42
      1 |     2           8          32          33
    Y=0 |  1     3    10    11    38    39    40    41
        +-------------------------------------------------
         X=0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15

In this arrangement N=1,2,4,5,7,etc on the leading diagonal is the last N of
each row (C<tree_depth_to_n_end()>).

=head2 Upper Octant

Option C<parts =E<gt> 'octant_up'> confines the pattern to the upper octant
0E<lt>=XE<lt>=Y of the first quadrant.

=cut

# math-image --path=UlamWarburtonQuarter,parts=octant_up --all --output=numbers --size=75x15

=pod

    parts => "octant_up"

     14 | 46    45    44    43    40    39    38    37
     13 |    35          34          33          32
     12 | 47    30    29    42    41    28    27
     11 |          26                      25
     10 | 48    31    23    22    21    20
      9 |    36          19          18
      8 | 49    50    24    17    16
      7 |                      15
      6 | 13    12    11    10
      5 |     9           8
      4 | 14     7     6
      3 |           5
      2 |  4     3
      1 |     2
    Y=0 |  1
        +----------------------------------------------
          X=0 1  2  3  4  5  6  7  8  9 10 11 12 13 14

In this arrangement N=1,2,3,5,6,etc on the leading diagonal is the first N
of each row (C<tree_depth_to_n()>).

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, in the same pattern.  For example to
start at 0,

=cut

# math-image --path=UlamWarburtonQuarter,n_start=0 --expression='i<22?i:0' --output=numbers

=pod

    n_start => 0

     7 |                      21
     6 | 19    18    17    16
     5 |    11          10
     4 | 20     8     7    15
     3 |           5
     2 |  4     3     6    14
     1 |     1           9
    Y=0|  0     2    12    13
       +-------------------------
        X=0  1  2  3  4  5  6  7

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::UlamWarburtonQuarter-E<gt>new ()>

=item C<$path = Math::PlanePath::UlamWarburtonQuarter-E<gt>new (parts =E<gt> $str, n_start =E<gt> $n)>

Create and return a new path object.  C<parts> can be

    1              first quadrant, the default
    "octant"       first eighth
    "octant_up"    upper eighth

=back

=head2 Tree Methods

=over

=item C<@n_children = $path-E<gt>tree_n_children($n)>

Return the children of C<$n>, or an empty list if C<$n> has no children
(including when C<$n E<lt> 1>, ie. before the start of the path).

The children are the cells turned on adjacent to C<$n> at the next row.  The
way points are numbered means that when there's multiple children they're
consecutive N values, for example at N=12 the children 19,20,21.

=item C<$n_parent = $path-E<gt>tree_n_parent($n)>

Return the parent node of C<$n>, or C<undef> if C<$n E<lt>= 1> (the start of
the path).

=back

=head2 Tree Descriptive Methods

=over

=item C<@nums = $path-E<gt>tree_num_children_list()>

Return a list of the possible number of children at the nodes of C<$path>.
This is the set of possible return values from C<tree_n_num_children()>.

    parts        tree_num_children_list()
    -----        ------------------------
      1              0, 1,    3
    octant           0, 1, 2, 3
    octant_up        0, 1, 2, 3

The octant forms have 2 children when branching from the leading diagonal,
otherwise 0,1,3.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<($n_start, tree_depth_to_n_end(2**($level+1) - 2))>.

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path includes

=over

L<http://oeis.org/A151920> (etc)

=back

    parts=1  (the default)
      A147610   num cells in row, tree_depth_to_width()
      A151920   total cells to depth, tree_depth_to_n_end()

    parts=octant,octant_up
      A079318   num cells in row, tree_depth_to_width()

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::UlamWarburton>,
L<Math::PlanePath::LCornerTree>,
L<Math::PlanePath::CellularRule>

L<Math::PlanePath::SierpinskiTriangle> (a similar binary ones-count related
calculation)

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
