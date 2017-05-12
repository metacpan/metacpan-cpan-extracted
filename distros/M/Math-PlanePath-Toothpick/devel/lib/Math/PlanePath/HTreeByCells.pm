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


# Middle ascending branches grow too fast.


package Math::PlanePath::HTreeByCells;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'bit_split_lowtohigh',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

use vars '$VERSION', '@ISA';
$VERSION = 18;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 1;
use constant class_x_negative => 0;
use constant class_y_negative => 0;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'upto_n'} = $self->n_start;
  my $n = _store ($self, 0,0, 0, undef);
  $self->{'x'} = 0;
  $self->{'y'} = 1;
  $self->{'dx'} = 0;
  $self->{'dy'} = 1;
  $self->{'length'} = 1;
  $self->{'spine_n'} = $n;
  $self->{'depth'} = 1;
  return $self;
}

#                        |
#     0,6         2,6    |    *           *
#      |           |     |    |           |
#     0,5---1,5---2,5    |    *---- * --- *
#      |     |     |     |    |     |     |
#     0,4    |    2,4    |    *     |     *
#            |           |          |
#           1,3---------3,3--------5,3
#            |                      |
#  2  0,2    |    2,2         *     |     *
#      |     |     |          |     |     |
#  1  0,1---1,1---2,1         *---- * --- *
#      |     3     |          |           |
#  0  0,0         2,0         *           *

sub _store {
  my ($self, $x,$y, $depth, $parent_n) = @_;
  ### store: "n=$self->{'upto_n'} $x,$y parent=".($parent_n//'undef')
    my $n = $self->{'upto_n'}++;
  $self->{'n_to_x'}->[$n] = $x;
  $self->{'n_to_y'}->[$n] = $y;
  $self->{'xy_to_n'}->{"$x,$y"} = $n;
  $self->{'n_to_depth'}->[$n] = $depth;
  $self->{'n_parent'}->[$n] = $parent_n;
  if (! defined $self->{'depth_to_n'}->[$depth]) {
    $self->{'depth_to_n'}->[$depth] = $n;
  }
  if (defined $parent_n) {
    push @{$self->{'n_children'}->[$parent_n]}, $n;
  }
  return $n;
}

sub _extend {
  my ($self) = @_;
  ### _extend(): "upto_n=$self->{upto_n} length=$self->{length}"

  my $recurse;
  $recurse = sub {
    my ($x,$y, $dx,$dy, $level,$length, $depth, $parent_n) = @_;

    ### recurse: "$x,$y  parent n=$parent_n  level=$level depth=$depth"
    my $n = _store($self, $x,$y, $depth, $parent_n);

    $level--;
    return unless $level >= 1;
    if ($dy) {
      $length /= 2;
    } else {
    }
    $depth++;
    $recurse->($x + $dy * $length,     # rotate -90
               $y - $dx * $length,
               $dy,-$dx,
               $level, $length, $depth,
               $n);

    $recurse->($x - $dy * $length,     # rotate +90
               $y + $dx * $length,
               -$dy,$dx,
               $level, $length, $depth,
               $n);
  };

  my $x = $self->{'x'};
  my $y = $self->{'y'};
  my $dx = $self->{'dx'};
  my $dy = $self->{'dy'};
  my $length = $self->{'length'};

  ### spine ...
  my $n = _store($self,
                 $x,$y,
                 $self->{'depth'},
                 $self->{'spine_n'});

  $self->{'x'} = $x + $dy * $self->{'length'};
  $self->{'y'} = $y + $dx * $self->{'length'};
  $self->{'dx'} = $dy;
  $self->{'dy'} = $dx;
  $self->{'spine_n'} = $n;

  if ($dy) {
    $self->{'length'} *= 2;
  } else {
    $length /= 2;
  }
  $x += $dx * $length;
  $y += $dy * $length;
  $recurse->($x,$y,
             $dx,$dy,
             $self->{'depth'}, $length, $self->{'depth'},
             $n);

  $self->{'depth'}++;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### HTreeByCells n_to_xy(): $n

  if ($n < $self->n_start) { return; }
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

  until ($self->{'upto_n'} > $n) {
    _extend($self);
  }
  return ($self->{'n_to_x'}->[$n],
          $self->{'n_to_y'}->[$n]);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### HTreeByCells xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if (is_infinite($x)) {
    return $x;
  }
  if (is_infinite($y)) {
    return $y;
  }

  my ($pow,$exp) = round_down_pow(max($x,$y), 2);
  $pow *= 2;
  while ($self->{'depth'} < $pow) {
    _extend($self);
  }
  return $self->{'xy_to_n'}->{"$x,$y"};
}

#use Smart::Comments;

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### HTreeByCells rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);

  my $depth_hi = max($x1, $x2,
                     $y1, $y2);
  ($depth_hi) = round_down_pow($depth_hi,2);
  return (0,
          $depth_hi ** 2);
}

sub tree_depth_to_n {
  my ($self, $depth) = @_;
  ### HTreeByCells depth_to_n(): $depth
  $depth = int($depth);
  if ($depth < 0) {
    return undef;
  }
  my $depth_to_n = $self->{'depth_to_n'};
  until (defined $depth_to_n->[$depth]) {
    _extend($self);
  }
  return $depth_to_n->[$depth];
}
sub tree_n_to_depth {
  my ($self, $n) = @_;
  ### HTreeByCells n_to_depth(): $n

  if ($n < $self->n_start) { return undef; }
  $n = int($n);
  if (is_infinite($n)) { return $n; }
  until ($self->{'upto_n'} > $n) {
    _extend($self);
  }
  return $self->{'n_to_depth'}->[$n];
}


sub tree_n_children {
  my ($self, $n) = @_;
  ### HTreeByCells tree_n_children(): $n

  until ($self->{'spine_n'} > $n) {
    _extend($self);
  }
  ### $self->{'n_children'}
  my $children = $self->{'n_children'}->[$n]
    || return;
  ### $children
  return @$children;
}

sub tree_n_parent {
  my ($self, $n) = @_;
  ### HTreeByCells tree_n_parent(): $n

  if ($n < $self->n_start) {
    return undef;
  }
  until ($self->{'upto_n'} > $n) {
    _extend($self);
  }
  ### is: $self->{'n_parent'}->[$n]
  return $self->{'n_parent'}->[$n]
}

1;
__END__
