# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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


# Maybe:
#
# rule 22 includes the midpoint between adjacent leaf points.
# math-image --path=CellularRule,rule=22 --all --text
#
# rule 126 extra cell to the inward side of each
# math-image --path=CellularRule,rule=60 --all --text
#
# cf rule 150 double ups, something base 2 instead
# math-image --path=CellularRule,rule=150 --all
#
# cf rule 182 filled gaps
# math-image --path=CellularRule,rule=182 --all

# math-image --path=SierpinskiTriangle --all --scale=5
# math-image --path=SierpinskiTriangle --all --output=numbers
# math-image --path=SierpinskiTriangle --all --text --size=80

# Number of cells in a row:
#    numerator of (2^k)/k!
#
# cf A067771  vertices of sierpinski graph, joins up replications
#             so 1 less each giving 3*(3^k-1)/2
#




package Math::PlanePath::SierpinskiTriangle;
use 5.004;
use strict;
use Carp 'croak';
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 128;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'bit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
# use Smart::Comments;

use constant parameter_info_array =>
  [ { name      => 'align',
      share_key => 'align_trld',
      display   => 'Align',
      type      => 'enum',
      default   => 'triangular',
      choices   => ['triangular', 'right', 'left','diagonal'],
      choices_display => ['Triangular', 'Right', 'Left','Diagonal'],
    },
    # { name      => 'parts',
    #   share_key => 'parts_alr',
    #   display   => 'Parts',
    #   type      => 'enum',
    #   default   => 'all',
    #   choices   => ['all', 'left', 'right'],
    #   choices_display => ['All', 'Left', 'Right'],
    # },
    Math::PlanePath::Base::Generic::parameter_info_nstart0(),
  ];

use constant default_n_start => 0;
use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;
use constant tree_num_children_list => (0,1,2);

sub x_negative {
  my ($self) = @_;
  return ($self->{'align'} eq 'left'
          || ($self->{'align'} eq 'triangular'
              && $self->{'parts'} ne 'right'));
}
sub x_negative_at_n {
  my ($self) = @_;
  return ($self->{'align'} eq 'left'
          || ($self->{'align'} eq 'triangular'
              && $self->{'parts'} ne 'right')
          ? $self->n_start + 1
          : undef);
}

# Note: this method shared by SierpinskiArrowhead
sub x_maximum {
  my ($self) = @_;
  return ($self->{'align'} eq 'left'
          || ($self->{'align'} eq 'triangular'
              && ($self->{'parts'}||'all') eq 'left')
          ? 0       # left all X<=0
          : undef); # others X to +infinity
}
use constant sumxy_minimum => 0;  # triangular X>=-Y or all X>=0

sub diffxy_minimum {
  my ($self) = @_;
  return ($self->{'align'} eq 'right'
          && $self->{'parts'} eq 'right'
          ? 0       # X>=Y so X-Y>=0
          : undef);
}

# Note: this method shared by SierpinskiArrowhead, SierpinskiArrowheadCentres
sub diffxy_maximum {
  my ($self) = @_;
  return ($self->{'align'} eq 'diagonal'
          ? undef
          : 0);    # triangular X<=Y so X-Y<=0
}

sub dy_minimum {
  my ($self) = @_;
  return ($self->{'align'} eq 'diagonal' ? undef : 0);
}
sub dy_maximum {
  my ($self) = @_;
  return ($self->{'align'} eq 'diagonal' ? undef : 1);
}
{
  my %absdx_minimum = (triangular => 1,
                       left       => 1,
                       right      => 0,  # at N=0
                       diagonal   => 0); # at N=0
  sub absdx_minimum {
    my ($self) = @_;
    return $absdx_minimum{$self->{'align'}};
  }
}
{
  my %absdy_minimum = (triangular => 0,  # rows
                       left       => 0,  # rows
                       right      => 0,  # rows
                       diagonal   => 1); # diagonal always moves
  sub absdy_minimum {
    my ($self) = @_;
    return $absdy_minimum{$self->{'align'}};
  }
}

sub dsumxy_minimum {
  my ($self) = @_;
  return ($self->{'align'} eq 'diagonal'
          ? 0         # X+Y constant along diagonals
          : undef);
}
sub dsumxy_maximum {
  my ($self) = @_;
  return ($self->{'align'} eq 'diagonal'
          ? 1         # X+Y increase by 1 to next diagonal
          : undef);
}

sub dir_minimum_dxdy {
  my ($self) = @_;
  return ($self->{'align'} eq 'diagonal'
          ? (0,1)   # North
          : (1,0)); # East
}
sub dir_maximum_dxdy {
  my ($self) = @_;
  return ($self->{'align'} eq 'diagonal'
          ? (1,-1)   # South-Eest
          : (-1,0)); # supremum, West and 1 up
}


#------------------------------------------------------------------------------
my %align_known = (triangular => 1,
                   left       => 1,
                   right      => 1,
                   diagonal   => 1);

sub new {
  my $self = shift->SUPER::new(@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  $self->{'parts'} ||= 'all';

  my $align = ($self->{'align'} ||= 'triangular');
  if (! $align_known{$align}) {
    croak "Unrecognised align option: ", $align;
  }
  ### $align

  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### SierpinskiTriangle n_to_xy(): $n

  # written as $n - n_start() rather than "-=" so as to provoke an
  # uninitialized value warning if $n==undef
  $n = $n - $self->{'n_start'};   # N=0 basis

  # this frac behaviour slightly unspecified yet
  my $frac;
  {
    my $int = int($n);
    $frac = $n - $int;
    if (2*$frac >= 1) {        # $frac>=0.5 and BigInt friendly
      $frac -= 1;
      $int += 1;
    } elsif (2*$frac < -1) {   # $frac<0.5 and BigInt friendly
      $frac += 1;
      $int -= 1;
    }
    $n = $int;
  }
  ### $n
  ### $frac

  if ($n < 0) {
    return;
  }
  if ($n == 0) {
    return ($n,$n);
  }

  my ($depthbits, $ndepth) = _n0_to_depthbits($n, $self->{'parts'})
    or return ($n,$n); # infinite

  ### $depthbits
  ### $ndepth

  my $zero = $n * 0;
  $n -= $ndepth;  # offset into row
  my @nbits = bit_split_lowtohigh($n);

  # Where there's a 0-bit in the depth remains a 0-bit.
  # Where there's a 1-bit in the depth takes a bit from Noffset.
  # Small Noffset has less bits than the depth 1s, hence "|| 0".
  #
  my @xbits = map {$_ && (shift @nbits || 0)} @$depthbits;
  ### @xbits

  my $x = digit_join_lowtohigh (\@xbits,    2, $zero);
  my $y = digit_join_lowtohigh ($depthbits, 2, $zero);

  ### n_to_xy as right: "$x,$y"

  # $x,$y is in the style of align=right, transform to others
  if ($self->{'align'} eq 'left') {
    $x -= $y;
  } elsif ($self->{'align'} eq 'diagonal') {
    $y -= $x;
  } elsif ($self->{'align'} eq 'triangular') {
    $x = 2*$x - $y;
  }

  ### n_to_xy final: "$x,$y"
  return ($x, $y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### SierpinskiTriangle xy_to_n(): "$x, $y"

  $y = round_nearest ($y);
  $x = round_nearest($x);

  # transform $x,$y to the style of align=right
  if ($self->{'align'} eq 'diagonal') {
    $y += $x;
  } elsif ($self->{'align'} eq 'left') {
    $x += $y;
  } elsif ($self->{'align'} eq 'triangular') {
    $x += $y;
    if (_divrem_mutate ($x, 2)) {
      # if odd point
      return undef;
    }
  }
  ### adjusted xy: "$x,$y"

  return _right_xy_to_n ($self, $x, $y);
}

sub _right_xy_to_n {
  my ($self, $x, $y) = @_;
  ### _right_xy_to_n(): "$x, $y"

  unless ($x >= 0 && $x <= $y && $y >= 0) {
    ### outside horizontal row range ...
    return undef;
  }
  if (is_infinite($y)) {
    return $y;
  }

  my $zero = ($y * 0);
  my $n = $zero;          # inherit bignum 0
  my $npower = $zero+1;   # inherit bignum 1

  my @xbits = bit_split_lowtohigh($x);
  my @depthbits = bit_split_lowtohigh($y);

  my @nbits;  # N offset into row
  foreach my $i (0 .. $#depthbits) {      # x,y bits low to high
    if ($depthbits[$i]) {
      $n = 2*$n + $npower;
      push @nbits, $xbits[$i] || 0;   # low to high
    } else {
      if ($xbits[$i]) {
        return undef;
      }
    }
    $npower *= 3;
  }

  ### n at left end of y row: $n
  ### n offset for x: @nbits
  ### total: $n + digit_join_lowtohigh(\@nbits,2,$zero) + $self->{'n_start'}

  return $n + digit_join_lowtohigh(\@nbits,2,$zero) + $self->{'n_start'};
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### SierpinskiTriangle rect_to_n_range(): "$x1,$y1, $x2,$y2"

  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1) }

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1) }

  # $y1 to $y2 is the depth range for "triangular", "right" and "left".
  # For "diagonal" must use X+Y to reckon by anti-diagonals.
  #
  if ($self->{'align'} eq 'diagonal') {
    $y2 += $x2;
    $y1 += $x1;
  }

  if ($y2 < 0) {
    return (1, 0);
  }
  if ($y1 < 0) {
    $y1 *= 0;  # preserve any bignum $y1
  }
  return ($self->tree_depth_to_n($y1),
          $self->tree_depth_to_n_end($y2));
}

# To get N within a triangle row, based on the X range ...
#
# use Math::PlanePath::CellularRule54;
# *_rect_for_V = \&Math::PlanePath::CellularRule54::_rect_for_V;
#
# if ($self->{'align'} eq 'diagonal') {
#   if ($x2 < 0 || $y2 < 0) {
#     return (1,0);
#   }
#   if ($x1 < 0) { $x1 *= 0; }
#   if ($y1 < 0) { $y1 *= 0; }
#
#   return ($self->xy_to_n(0, $x1+$y1),
#           $self->xy_to_n($x2+$y2, 0));
# }
#
# ($x1,$y1, $x2,$y2) = _rect_for_V ($x1,$y1, $x2,$y2)
#   or return (1,0); # rect outside pyramid
#
# return ($self->xy_to_n($self->{'align'} eq 'right' ? 0 : -$y1,
#                        $y1),
#         $self->xy_to_n($self->{'align'} eq 'left' ? 0 : $y2,
#                        $y2));


#------------------------------------------------------------------------------
use constant tree_num_roots => 1;

sub tree_n_num_children {
  my ($self, $n) = @_;

  $n = $n - $self->{'n_start'};   # N=0 basis
  if ($n < 0) {
    return undef;
  }
  if ($n == 0 && $self->{'parts'} ne 'all') {
    # parts=left or parts=right have only 1 child under the root n=0
    return 1;
  }
  my ($depthbits, $ndepth) = _n0_to_depthbits($n, $self->{'parts'})
    or return 1;  # infinite

  unless (shift @$depthbits) {  # low bit
    # Depth even (incl zero), two children under every point.
    return 2;
  }

  # Depth odd, either 0 or 1 child.
  # If depth==1mod4 then 1-child.
  # If depth==3mod4 so two or more trailing 1-bits then some 0-child and
  # some 1-child.
  #
  $n -= $ndepth;  # Noffset into row
  my $repbit = _divrem_mutate($n,2); # low bit of $n
  while (shift @$depthbits) {               # bits of depth low to high
    if (_divrem_mutate($n,2) != $repbit) {  # bits of $n offset low to high
      return 0;
    }
  }
  return 1;
}

sub tree_n_children {
  my ($self, $n) = @_;
  ### tree_n_num_children(): $n

  $n = $n - $self->{'n_start'};   # N=0 basis
  if ($n < 0) {
    return;
  }
  if ($n == 0 && $self->{'parts'} ne 'all') {
    # parts=left or parts=right have only 1 child under the root n=0
    return ($n+1 + $self->{'n_start'});
  }
  my ($depthbits, $ndepth, $nwidth) = _n0_to_depthbits($n, $self->{'parts'})
    or return $n;  # infinite

  $n -= $ndepth;  # Noffset into row

  if (shift @$depthbits) {
    # Depth odd, single child under some or all points.
    # When depth==1mod4 it's all points, when depth has more than one
    # trailing 1-bit then it's only some points.
    while (shift @$depthbits) {  # depth==3mod4 or more low 1s
      my $repbit = _divrem_mutate($n,2);
      if (($n % 2) != $repbit) {
        return;
      }
    }
    return $n + $ndepth+$nwidth + $self->{'n_start'};

  } else {
    # Depth even (or zero), two children under every point.
    $n = 2*$n + $ndepth+$nwidth + $self->{'n_start'};
    return ($n,$n+1);
  }
}
sub tree_n_parent {
  my ($self, $n) = @_;

  my ($x,$y) = $self->n_to_xy($n)
    or return undef;

  if ($self->{'align'} eq 'diagonal') {
    my $n_parent = $self->xy_to_n($x-1, $y);
    if (defined $n_parent) {
      return $n_parent;
    } else {
      return $self->xy_to_n($x,$y-1);
    }
  }

  $y -= 1;
  my $n_parent = $self->xy_to_n($x-($self->{'align'} ne 'left'), $y);
  if (defined $n_parent) {
    return $n_parent;
  }
  return $self->xy_to_n($x+($self->{'align'} ne 'right'),$y);
}

sub tree_n_to_depth {
  my ($self, $n) = @_;
  ### SierpinskiTriangle n_to_depth(): $n
  $n = $n - $self->{'n_start'};
  if ($n < 0) {
    return undef;
  }
  my ($depthbits) = _n0_to_depthbits($n, $self->{'parts'})
    or return $n;  # infinite
  return digit_join_lowtohigh ($depthbits, 2, $n*0);
}
sub tree_depth_to_n {
  my ($self, $depth) = @_;
  return ($depth >= 0 ? _right_xy_to_n($self,0,$depth) : undef);
}

# sub _NOTWORKING__tree_depth_to_n_range {
#   my ($self, $depth) = @_;
#   if (is_infinite($depth)) {
#     return $depth;
#   }
#   if ($depth < 0) {
#     return undef;
#   }
#
#   my $zero = my $n = ($depth * 0);    # inherit bignum 0
#   my $width = my $npower = $zero+1;   # inherit bignum 1
#
#   foreach my $dbit (bit_split_lowtohigh($depth)) {
#     if ($dbit) {
#       $n = 2*$n + $npower;
#       $width *= 2;
#     }
#     $npower *= 3;
#   }
#   $n += $self->{'n_start'};
#
#   return ($n, $n+$width-1);
# }


#------------------------------------------------------------------------------
# In align=diagonal style, height is following a straight line X increment
# until hit bit in common with Y, meaning the end of Y low 0s.  Or follow
# straight line Y until hit bit in common with X, meaning end of X low 0s.
#
# If X,Y both even then X or Y lines are the same.
# If X odd then follow X to limit of Y low 0s.
# If Y odd then follow Y to limit of X low 0s.
#
#  | 65       ...
#  | 57 66
#  | 49    67
#  | 45 50 58 68
#  | 37          69
#  | 33 38       59 70
#  | 29    39    51    71
#  | 27 30 34 40 46 52 60 72
#  | 19                      73
#  |  |                       |
#  | 15-20                   61-74
#  |  |                       |
#  | 11    21                53    75
#  |  |     |                 |     |
#  |  9-12-16-22             47-54-62-76
#  |  |                       |
#  |  5          23          41          77
#  |  |           |           |           |
#  |  3--6       17-24       35-42       63-78
#  |  |           |           |           |
#  |  1     7    13    25    31    43    55    79
#  |  |     |     |     |     |     |     |     |
#  |  0--2--4--8-10-14-18-26-28-32-36-44-48-56-64-80
#  +-------------------------------------------------
#   X=0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
#
# depthbits   1 0 0 0 1   Y of "right"
# nbits             n n
# xbits       n 0 0 0 n
# ybits      1-n     1-n  of Y-X for "diagonal"
#
# Y odd when ylow==1,nlow==0
#       follow its X low 0s by nbit==0 and invert of ybits==1
# X odd when ylow==1,nlow==1
#       follow its Y low 0s by nbit==1 and invert of xbits=nbits==1
#
# At a given depth<=2^k can go at most to its 2^k-1 limit, which means
# height = 2^k-1 - depth which is depth with bits flipped.
# Then bits of Noffset may put it in the middle of somewhere which limits
# the height to a sub-part 2^j < 2^k.
#
sub tree_n_to_subheight {
  my ($self, $n) = @_;
  ### SierpinskiTriangle tree_n_to_subheight(): $n

  $n = $n - $self->{'n_start'};
  if ($n < 0) {
    return undef;
  }
  my ($depthbits, $ndepth) = _n0_to_depthbits($n, $self->{'parts'})
    or return $n;  # infinite
  $n -= $ndepth;     # offset into row
  my @nbits = bit_split_lowtohigh($n);

  my $target = $nbits[0] || 0;
  foreach my $i (0 .. $#$depthbits) {
    unless ($depthbits->[$i] ^= 1) {  # flip 0<->1, at original==1 take nbit
      if ((shift @nbits || 0) != $target) {
        $#$depthbits = $i-1;
        return digit_join_lowtohigh($depthbits, 2, $n*0);
      }
    }
  }
  return undef; # first or last of row, infinite
}


#------------------------------------------------------------------------------
#   \                             /
#    4   0   0   0   0   0   0   4
#     \ /     \ /     \ /     \ /
#      1       1       1       1
#       \     /         \     /
#        2   2           2   2
#         \ /             \ /
#          3               3
#           \             /
#            4   0   0   4
#             \ /     \ /
#              1       1
#               \     /
#                2   2
#                 \ /
#                  3

# sub _EXPERIMENTAL__tree_n_to_leafdist {
#   my ($self, $n) = @_;
#   ### _EXPERIMENTAL__tree_n_to_leafdist() ...
#   my $d = $self->tree_n_to_depth($n);
#   if (defined $d) {
#     $d = 3 - ($d % 4);
#     if ($d == 0 && $self->tree_n_num_children($n) != 0) {
#       $d = 4;
#     }
#   }
#   return $d;
# }
sub _EXPERIMENTAL__tree_n_to_leafdist {
  my ($self, $n) = @_;
  ### _EXPERIMENTAL__tree_n_to_leafdist(): $n

  $n = $n - $self->{'n_start'};   # N=0 basis
  if ($n < 0) {
    return undef;
  }
  my ($depthbits, $ndepth) = _n0_to_depthbits($n, $self->{'parts'})  # low to high
    or return 1;  # infinite
  ### $depthbits

  # depth bits leafdist
  #   0    0,0    3
  #   1    0,1    2
  #   2    1,0    1
  #   3    1,1    0 or 4
  #
  my $ret = 3 - ((shift @$depthbits)||0);
  if (shift @$depthbits) { $ret -= 2; }
  ### $ret
  if ($ret) {
    return $ret;
  }

  $n -= $ndepth;
  ### Noffset into row: $n

  # Low bits of Nrem unchanging while trailing 1-bits in @depthbits,
  # to distinguish between leaf or non-leaf.  Same as tree_n_children().
  #
  my $repbit = _divrem_mutate($n,2); # low bit of $n
  ### $repbit
  do {
    ### next bit: $n%2
    if (_divrem_mutate($n,2) != $repbit) {  # bits of $n offset low to high
      return 0;  # is a leaf
    }
  } while (shift @$depthbits);
  return 4; # is a non-leaf
}

#------------------------------------------------------------------------------
# Return ($depthbits, $ndepth, $nwidth).
# $depthbits is an arrayref of bits low to high which are the tree depth of $n.
# $ndepth is first N of the row.
# $nwidth is the number of points in the row.
#
sub _n0_to_depthbits {
  my ($n, $parts) = @_;
  ### _n0_to_depthbits(): "$n  $parts"

  if (is_infinite($n)) {
    return;
  }
  if ($n == 0) {
    return ([], 0, 1);
  }

  my ($nwidth, $bitpos) = round_down_pow ($parts eq 'all' ? $n : 2*$n-1,
                                          3);
  ### $nwidth
  ### $bitpos

  my @depthbits;
  $depthbits[$bitpos] = 1;
  my $ndepth = ($parts eq 'all' ? $nwidth : ($nwidth + 1)/2);
  $nwidth *= 2;

  while (--$bitpos >= 0) {
    $nwidth /= 3;
    ### at: "n=$n nwidth=$nwidth bitpos=$bitpos depthbits=".join(',',map{$_||0}@depthbits)

    if ($n >= $ndepth + $nwidth) {
      $depthbits[$bitpos] = 1;
      $ndepth += $nwidth;
      $nwidth *= 2;
    } else {
      $depthbits[$bitpos] = 0;
    }
  }

  # Nwidth = 2**count1bits(depth), when parts=all
  ### @depthbits
  ### assert: $parts ne 'all' || $nwidth == (1 << scalar(grep{$_}@depthbits))

  return (\@depthbits, $ndepth, $nwidth);
}

#------------------------------------------------------------------------------
# levels

use Math::PlanePath::SierpinskiArrowheadCentres;
*level_to_n_range = \&Math::PlanePath::SierpinskiArrowheadCentres::level_to_n_range;
*n_to_level       = \&Math::PlanePath::SierpinskiArrowheadCentres::n_to_level;

#-----------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Sierpinski Nlevel ie Ymin Ymax OEIS Online rowpoints Nleft Math-PlanePath Gould's Nend bitand Noffset Ndepth Nrem Dyck

=head1 NAME

Math::PlanePath::SierpinskiTriangle -- self-similar triangular path traversal

=head1 SYNOPSIS

 use Math::PlanePath::SierpinskiTriangle;
 my $path = Math::PlanePath::SierpinskiTriangle->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Sierpinski, Waclaw>This path is an integer version of Sierpinski's
triangle from

=over

Waclaw Sierpinski, "Sur une Courbe Dont Tout Point est un Point de
Ramification", Comptes Rendus Hebdomadaires des SE<233>ances de
l'AcadE<233>mie des Sciences, volume 160, January-June 1915, pages 302-305.
L<http://gallica.bnf.fr/ark:/12148/bpt6k31131/f302.image.langEN>

=back

=cut

# PDF download pages 304 to 307 inclusive

=pod

Unit triangles are numbered numbered horizontally across each row.

    65  66  67  68  69  70  71  72  73  74  75  76  77  78  79  80   15
      57      58      59      60      61      62      63      64     14
        49  50          51  52          53  54          55  56       13
          45              46              47              48         12
            37  38  39  40                  41  42  43  44           11
              33      34                      35      36             10
                29  30                          31  32                9
                  27                              28                  8
                    19  20  21  22  23  24  25  26                    7
                      15      16      17      18                      6
                        11  12          13  14                        5
                           9              10                          4
                             5   6   7   8                            3
                               3       4                              2
                                 1   2                                1
                                   0                             <- Y=0

         X= ... -9-8-7-6-5-4-3-2-1 0 1 2 3 4 5 6 7 8 9 ...

The base figure is the first two rows shape N=0 to N=2.  Notice the middle
"." position X=0,Y=1 is skipped

    1  .  2
       0

This is replicated twice in the next row pair as N=3 to N=8.  Then the
resulting four-row shape is replicated twice again in the next four-row
group as N=9 to N=26, etc.

See the C<SierpinskiArrowheadCentres> path to traverse by a connected
sequence rather than rows jumping across gaps.

=head2 Row Ranges

The number of points in each row is always a power of 2.  The power is the
count of 1-bits in Y.  (This count is sometimes called Gould's sequence.)

    rowpoints(Y) = 2^count_1_bits(Y)

For example Y=13 is binary 1101 which has three 1-bits so in row Y=13 there
are 2^3=8 points.

Because the first point is N=0, the N at the left of each row is the
cumulative count of preceding points,

    Ndepth(Y) = rowpoints(0) + ... + rowpoints(Y-1)

Since the powers of 2 are always even except for 2^0=1 in row Y=0, this
Ndepth(Y) total is always odd.  The self-similar nature of the triangle
means the same is true of the sub-triangles, for example odd
N=31,35,41,47,etc on the left of the triangle at X=8,Y=8.  This means in
particular the primes (being odd) fall predominately on the left side of the
triangles and sub-triangles.

=head2 Replication Sizes

Counting the single point N=0 as level=0, then N=0,1,2 as level 1, each
replication level goes from

    Nstart = 0
    Nlevel = 3^level - 1     inclusive

For example level 2 is from N=0 to N=3^2-1=8.  Each level doubles in size,

               0  <= Y <= 2^level - 1
    - 2^level + 1 <= X <= 2^level - 1

=head2 Align Right

Optional C<align=E<gt>"right"> puts points to the right of the Y axis,
packed next to each other and so using an eighth of the plane.

=cut

# math-image --path=SierpinskiTriangle,align=right --all --output=numbers

=pod

    align => "right"

      7  | 19 20 21 22 23 24 25 26 
      6  | 15    16    17    18    
      5  | 11 12       13 14       
      4  |  9          10          
      3  |  5  6  7  8             
      2  |  3     4                
      1  |  1  2                   
    Y=0  |  0                      
         +-------------------------
          X=0  1  2  3  4  5  6  7

=head2 Align Left

Optional C<align=E<gt>"left"> puts points to the left of the Y axis,
ie. into negative X.  The rows are still numbered starting from the left, so
it's a shift across, not a negate of X.

=cut

# math-image --path=SierpinskiTriangle,align=left --all --output=numbers

=pod

    align => "left"

    19 20 21 22 23 24 25 26  |     7
       15    16    17    18  |     6
          11 12       13 14  |     5
              9          10  |     4
                 5  6  7  8  |     3
                    3     4  |     2
                       1  2  |     1
                          0  | <- Y=0
    -------------------------+
    -7 -6 -5 -4 -3 -2 -1 X=0

=head2 Align Diagonal

Optional C<align=E<gt>"diagonal"> puts rows on diagonals down from the Y
axis to the X axis.  This uses the whole of the first quadrant, with gaps
according to the pattern.

=cut

# math-image --expression='i<=80?i:0' --path=SierpinskiTriangle,align=diagonal --output=numbers

=pod

    align => "diagonal"

     15 | 65       ...
     14 | 57 66
     13 | 49    67
     12 | 45 50 58 68
     11 | 37          69
     10 | 33 38       59 70
      9 | 29    39    51    71
      8 | 27 30 34 40 46 52 60 72
      7 | 19                      73
      6 | 15 20                   61 74
      5 | 11    21                53    75
      4 |  9 12 16 22             47 54 62 76
      3 |  5          23          41          77       ...
      2 |  3  6       17 24       35 42       63 78
      1 |  1     7    13    25    31    43    55    79
    Y=0 |  0  2  4  8 10 14 18 26 28 32 36 44 48 56 64 80
        +-------------------------------------------------
         X=0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15

This form visits all points X,Y where X and Y written in binary have no
1-bits in the same bit positions, ie. where S<X bitand Y> == 0.  For example
X=13,Y=3 is not visited because 13="1011" and 6="0110" both have bit "0010"
set.

This bit-and rule is an easy way to test for visited or not visited cells of
the pattern.  The visited cells can be calculated by this diagonal X,Y
bitand, but then plotted X,X+Y for the "right" align or X-Y,X+Y for
"triangular".

=head2 Cellular Automaton

The triangle arises in Stephen Wolfram's 1-D cellular automatons (per
L<Math::PlanePath::CellularRule> and L<Cellular::Automata::Wolfram>).

    align           rule
    -----           ----
    "triangular"    18,26,82,90,146,154,210,218
    "right"         60
    "left"          102

=over

L<http://mathworld.wolfram.com/Rule90.html>

L<http://mathworld.wolfram.com/Rule60.html>

L<http://mathworld.wolfram.com/Rule102.html>

=back

=cut

# rule 60 right hand octant
# rule 102 left hand octant
# math-image --path=CellularRule,rule=60 --all
# math-image --path=CellularRule,rule=102 --all

=pod

In each row the rule 18 etc pattern turns a cell "on" in the next row if one
but not both its diagonal predecessors are "on".  This is a mod 2 sum giving
Pascal's triangle mod 2.

Some other cellular rules are variations on the triangle,

=over

=item *

Rule 22 is "triangular" but filling the gap between leaf points such as N=5
and N=6.

=item *

Rule 126 adds an extra point on the inward side of each visited.

=item *

Rule 182 fills in the big gaps leaving just a single-cell
empty border delimiting them.

=back

=head2 N Start

The default is to number points starting N=0 as shown above.  An optional
C<n_start> parameter can give a different start, with the same shape.  For
example starting at 1, which is the numbering of C<CellularRule> rule=60,

=cut

# math-image --path=SierpinskiTriangle,n_start=1 --expression='i<=27?i:0' --output=numbers

=pod

    n_start => 1

    20    21    22    23    24    25    26    27
       16          17          18          19
          12    13                14    15
             10                      11
                 6     7     8     9
                    4           5
                       2     3
                          1

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::SierpinskiTriangle-E<gt>new ()>

=item C<$path = Math::PlanePath::SierpinskiTriangle-E<gt>new (align =E<gt> $str, n_start =E<gt> $n)>

Create and return a new path object.  C<align> is a string, one of the
following as described above.

    "triangular"    (the default)
    "right"
    "left"
    "diagonal"

=back

=head2 Descriptive Methods

=over

=item C<$n = $path-E<gt>n_start()>

Return the first N in the path.  This is 0 by default, or the given
C<n_start> parameter.

=back

=head2 Tree Methods

=over

=item C<@n_children = $path-E<gt>tree_n_children($n)>

Return the children of C<$n>, or an empty list if C<$n E<lt> n_start>
(ie. before the start of the path).

The children are the points diagonally up left and right on the next row
(Y+1).  There can be 0, 1 or 2 such points.  At even depth there's 2, on
depth=1mod4 there's 1.  On depth=3mod4 there's some 0s and some 1s.  See
L</N to Number of Children> below.

For example N=3 has two children N=5,N=6.  Then in turn N=5 has just one
child N=9 and N=6 has no children.  The way points are numbered across a row
means that when there's two children they're consecutive N values.

=item C<$n_parent = $path-E<gt>tree_n_parent($n)>

Return the parent node of C<$n>, or C<undef> if C<$n E<lt>= n_start> (the
top of the triangle).

=item C<$depth = $path-E<gt>tree_n_to_depth($n)>

Return the depth of node C<$n>, or C<undef> if there's no point C<$n>.  In
the "triangular", "right" and "left" alignments this is the same as the Y
coordinate from C<n_to_xy()>.  In the "diagonal" alignment it's X+Y.

=item C<$n = $path-E<gt>tree_depth_to_n($depth)>

=item C<$n = $path-E<gt>tree_depth_to_n_end($depth)>

Return the first or last N at tree level C<$depth>.  The start of the tree
is depth=0 at the origin X=0,Y=0.

This is the N at the left end of each row.  So in the default triangular
alignment it's the same as C<xy_to_n(-$depth,$depth)>.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 3**$level - 1)>.

=back

=head1 FORMULAS

=head2 X,Y to N

For calculation it's convenient to turn the X,Y coordinates into the "right"
alignment style, so that Y is the depth and X is in the range
0E<lt>=XE<lt>=Y.

The starting position of each row of the triangle is given by turning 1-bits
of the depth into powers-of-3.

    Y = depth = 2^a + 2^b + 2^c + 2^d ...       a>b>c>d...

    Ndepth = first N at this depth
           =         3^a
             +   2 * 3^b
             + 2^2 * 3^c
             + 2^3 * 3^d
             + ...

For example depth=6=2^2+2^1 starts at Ndepth=3^2+2*3^1=15.  The powers-of-3
are the three parts of the triangle replication.  The power-of-2 doubling is
the doubling of the row Y when replicated.

Then the bits of X at the positions of the 1-bits of the depth become an N
offset into the row.

               a  b  c  d
    depth    = 10010010010     binary
    X        = m00n00p00q0
    Noffset  =        mnpq     binary

    N = Ndepth + Noffset

For example in depth=6 binary "110" then at X=4="100" take the bits of X
where depth has 1-bits, which is X="10_" so Noffset="10" binary and
N=15+2=17, as per the "right" table above at X=4,Y=6.

If X has any 1-bits which are a 0-bits in the depth depth then that X,Y is
not visited.  For example if depth=6="110" then X=3="11" is not visited
because the low bit X="__1" has depth="__0" at that position.

=head2 N to Depth

The row containing N can be found by working down the Ndepth formula shown
above.  The "a" term is the highest 3^a E<lt>= N, thus giving a bit 2^a for
the depth.  Then for the remaining Nrem = N - 3^a find the highest "b" where
2*3^b E<lt>= Nrem.  And so on until reaching an Nrem which is too small to
subtract any more terms.

It's convenient to go by bits high to low of the prospective depth, deciding
at each bit whether Nrem is big enough to give the depth a 1-bit there, or
whether it must be a 0-bit.

    a = floor(log3(N))     round down to power-of-3
    pow = 3^a
    Nrem = N - pow

    depth = high 1-bit at bit position "a" (counting from 0)

    factor = 2
    loop bitpos a-1 down to 0
      pow /= 3
      if pow*factor <= Nrem
      then depth 0-bit, factor *= 2
      else depth 1-bit

    factor is 2^count1bits(depth)
    Noffset = Nrem     offset into row
    0 <= Noffset < factor

=head2 N to X,Y

N is turned into depth and Noffset as per above.  X in "right" alignment
style is formed by spreading the bits of Noffset out according to the 1-bits
of the depth.

    depth   = 100110  binary
    Noffset =    abc  binary
    Xright  = a00bc0

For example in depth=5 this spreads an Noffset=0to3 to make X=000, 001, 100,
101 in binary and in "right" alignment style.

From an X,Y in "right" alignment the other alignments are formed

    alignment   from "right" X,Y
    ---------   ----------------
    triangular     2*X-Y, Y       so -Y <= X < Y
    right          X,     Y       unchanged
    left           X-Y,   Y       so -Y <= X <= 0
    diagonal       X,   Y-X       downwards sloping

=head2 N to Number of Children

The number of children follows a pattern based on the depth.

    depth      number of children
    -----      ------------------

     12    2       2       2       2   
     11     1 0 0 1         1 0 0 1
     10      2   2           2   2
      9       1 1             1 1
      8        2               2
      7         1 0 0 0 0 0 0 1   
      6          2   2   2   2 
      5           1 1     1 1  
      4            2       2   
      3             1 0 0 1   
      2              2   2
      1               1 1
      0                2   

If depth is even then all points have 2 children.  For example row depth=6
has 4 points and all have 2 children each.

At odd depth the number of children is either 1 or 0 according to the
Noffset position in the row masked down by the trailing 1-bits of the depth.

    depth  = ...011111 in binary, its trailing 1s

    Noffset = ...00000   \ num children = 1
            = ...11111   /
            = ...other   num children = 0

For example depth=11 is binary "1011" which has low 1-bits "11".  If those
two low bits of Noffset are "00" or "11" then 1 child.  Any other bit
pattern in Noffset ("01" or "10" in this case) is 0 children.  Hence the
pattern 1,0,0,1,1,0,0,1 reading across the depth=11 row.

In general when the depth doubles the triangle is replicated twice and the
number of children is carried with the replications, except the middle two
points are 0 children.  For example the triangle of depth=0to3 is repeated
twice to make depth=4to7, but the depth=7 row is not children 10011001 of a
plain doubling from the depth=3 row, but instead 10000001 which is the
middle two points becoming 0.

=head2 N to Number of Siblings

Each node N has either 0 or 1 siblings.  This is determined by depth,

    depth      number of siblings
    -----      ------------------

      4            0       0   
      3             1 1 1 1   
      2              0   0
      1               1 1
      0                0   

    depth     number of siblings
    -----     ------------------
     odd             1
     even            0

In an even row the points are all spread apart so there are no siblings.
The points in such a row are cousins or second cousins, etc, but none share
a parent.

In an odd row each parent node (an even row) has 2 children and so each of
those points has 1 sibling.

The effect is to conflate the NumChildren=1 and NumChildren=0 cases in the
children picture above, those two becoming a single sibling.

    num children of N      num siblings of N
    -----------------      -----------------
          0 or 1                   1
            2                      0

=head2 Rectangle to N Range

An easy range can be had just from the Y range by noting the diagonals X=Y
and X=-Y are always visited, so just take the Ndepth of Ymin and Nend of
Ymax,

    # align="triangular"
    Nmin = N at X=-Ymin,Y=Ymin
    Nmax = N at X=Ymax,Y=Ymax

Or in "right" style the left end is at X=0 instead,

    # align="right"
    Nmin = N at X=0,Ymin
    Nmax = N at Ymax,Ymax

For less work but a bigger over-estimate, invert the Nlevel formulas given
in L</Row Ranges> above to round up to the end of a depth=2^k replication,

    level = floor(log2(Ymax)) + 1
    Nmax = 3^level - 1

For example Y=11, level=floor(log2(11))+1=4, so Nmax=3^4-1=80, which is the
end of the Y=15 row, ie. rounded up to the top of the replication block Y=8
to Y=15.

=head1 OEIS

The Sierpinski triangle is in Sloane's Online Encyclopedia of Integer
Sequences in various forms,

=over

L<http://oeis.org/A001316> (etc)

=back

    A001316   number of cells in each row (Gould's sequence)
    A001317   rows encoded as numbers with bits 0,1
    A006046   total cells to depth, being tree_depth_to_n(), 
    A074330   Nend, right hand end of each row (starting Y=1)

A001316 is the "rowpoints" described above.  A006046 is the cumulative total
of that sequence which is the "Ndepth", and A074330 is 1 less for "Nend".

    align="triangular" (the default)
      A047999   0,1 cells by rows
      A106344   0,1 cells by upwards sloping dX=3,dY=1
      A130047   0,1 cells of half X<=0 by rows

A047999 etc is every second point in the default triangular lattice, or all
points in align="right" or "left".

    align="triangular" (the default)
      A002487   count points along dX=3,dY=1 slopes
                  is the Stern diatomic sequence
      A106345   count points along dX=5,dY=1 slopes

dX=3,dY=1 sloping lines are equivalent to opposite-diagonals dX=-1,dY=1 in
align="right".

    align="right"
      A075438   0,1 cells by rows including 0 blanks at left of pyramid

    align="right", n_start=0
      A006046   N on Y axis, being Ndepth
      A074330   N on Diagonal starting from Y=1, being Nend
    align="left", n_start=0
      A006046   N on NW diagonal, being Ndepth
      A074330   N on Y axis starting from Y=1, being Nend

    A080263   Dyck encoding of the tree structure
    A080264     same in binary
    A080265     position in list of all balanced binary

    A080268   Dyck encoding breadth-first
    A080269     same in binary
    A080270     position in list of all balanced binary

    A080318   Dyck encoding breadth-first of branch-reduced
                (duplicate each bit)
    A080319     same in binary
    A080320     position in list of all balanced binary

For the Dyck encoding see for example L<Math::NumSeq::BalancedBinary/Binary
Trees>.  The position in all balanced binary which is A080265 etc
corresponds to C<value_to_i()> in that C<NumSeq>.

A branch-reduced tree has any single-child node collapsed out, so that all
remaining nodes are either a leaf node or have 2 (or more) children.  The
effect of this on the Sierpinski triangle in breadth-first encoding is to
duplicate each bit, so A080269 with each bit repeated gives the
branch-reduced A080319.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::SierpinskiArrowhead>,
L<Math::PlanePath::SierpinskiArrowheadCentres>,
L<Math::PlanePath::CellularRule>,
L<Math::PlanePath::ToothpickUpist>

L<Math::NumSeq::SternDiatomic>,
L<Math::NumSeq::BalancedBinary>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
