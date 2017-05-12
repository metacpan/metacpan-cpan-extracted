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


# Cell ON at 1 of 2 vertically on odd cells X!=Y mod 2
#         at 1 of 2 horizontally on even cells X=Y mod 2
# is same as ToothpickTree.
#
# unwedge_left   extra at left end of wedge region
# A170886 total cells
# A170887 added
# A170886 Similar to A160406, always staying outside the wedge, but starting
# with a toothpick whose midpoint touches the vertex of the wedge.
#
# unwedge_left+1    diagonal stair step only
# A170888 total cells
# A170889 added
# A170888 Similar to A160406, always staying outside the wedge, but starting
# with a vertical half-toothpick which protrudes from the vertex of the
# wedge.
# 0, 1, 2, 4, 4, 4, 6, 10, 8, 4, 6, 10, 10, 12, 20, 26, 16, 4, 6, 10, 10,   

# unwedge_down_W
# A170890 Similar to A160406, always staying outside the wedge, but starting with a horizontal half-toothpick which protrudes from the vertex of the wedge.
# A170891 First differences of A170890.
# math-image --png --path=ToothpickTreeByCells,parts=unwedge_down_W --figure=toothpick --values=LinesTree --scale=20 --size=250x250 >/tmp/x.png

# unwedge_down
# A170892 Similar to A160406, always staying outside the wedge, but starting with a vertical toothpick whose endpoint touches the vertex of the wedge.
# A170893 First differences of A170892.
# 0, 1, 1, 2, 4, 4, 4, 8, 10, 10, 4

# unwedge_left_S
# A170894 Similar to A160406, always staying outside the wedge, but starting with a horizontal toothpick whose endpoint touches the vertex of the wedge.
# A170895 First differences of A170894.



package Math::PlanePath::ToothpickTreeByCells;
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
use Math::PlanePath::Base::Digits
  'round_down_pow';
use Math::PlanePath::SquareSpiral;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;

use constant parameter_info_array =>
  [ { name      => 'parts',
      share_key => 'parts_toothpicktreebycells',
      display   => 'Parts',
      type      => 'enum',
      default   => '4',
      choices   => ['4','3w','3','2','1','octant','octant_up',
                    'cross','two_horiz',
                    'wedge','wedge+1',
                    'unwedge_left','unwedge_left+1','unwedge_left_S',
                    'unwedge_down','unwedge_down+1','unwedge_down_W',
                    ],
      description     => 'Which parts of the plane to fill, 1 to 4 quadrants.',
    },
  ];


sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'sq'} = Math::PlanePath::SquareSpiral->new (n_start => 0);

  my $parts = ($self->{'parts'} ||= '4');
  $self->{'depth_to_n'} = [0];
  my @n_to_x;
  my @n_to_y;
  my @endpoint_dirs;
  if ($parts eq '4'
      || $parts eq 'wedge' || $parts eq 'wedge+1'
      || $parts eq 'unwedge_left' || $parts eq 'unwedge_left+1'
      || $parts eq 'unwedge_down+1'
      || $parts eq 'unwedge_down' || $parts eq 'unwedge_down_W'
      || $parts eq 'unwedge_left_S'
     ) {
    @n_to_x = (0);
    @n_to_y = (0);
    @endpoint_dirs = (2);
  } elsif ($parts eq '1' || $parts eq 'octant') {
    @n_to_x = (1);
    @n_to_y = (1);
    @endpoint_dirs = (0);
  } elsif ($parts eq 'octant_up') {
    @n_to_x = (1);
    @n_to_y = (2);
    @endpoint_dirs = (1);
  } elsif ($parts eq '2') {
    @n_to_x = (0);
    @n_to_y = (1);
    @endpoint_dirs = (1);
  } elsif ($parts eq '3') {
    @n_to_x = (0);
    @n_to_y = (0);
    @endpoint_dirs = (0);  # so N=1 is at X=0,Y=-1 
  } elsif ($parts eq '3w') {
    @n_to_x = (0,  1,1,-1);
    @n_to_y = (1, -1,1, 1);
    @endpoint_dirs = (3,0,2,2);
    push @{$self->{'depth_to_n'}}, 1;
  } elsif ($parts eq 'cross') {
    @n_to_x = (0, -1, 1, 0);
    @n_to_y = (0, 0, 0, -2);
    @endpoint_dirs = (2, 3, 0, 1);
  } elsif ($parts eq 'two_horiz') {
    @n_to_x = (1, -1);
    @n_to_y = (0, 0);
    @endpoint_dirs = (3, 1);
  } else {
    croak "Unrecognised parts: ",$parts;
  }
  $self->{'n_to_x'} = \@n_to_x;
  $self->{'n_to_y'} = \@n_to_y;

  my @endpoints;
  my @xy_to_n;
  foreach my $n (0 .. $#n_to_x) {
    my $sn = $self->{'sq'}->xy_to_n($n_to_x[$n],$n_to_y[$n]);
    $xy_to_n[$sn] = $n;
    push @endpoints, $sn;
  }
  $self->{'endpoints'} = \@endpoints;
  $self->{'endpoint_dirs'} = \@endpoint_dirs;
  $self->{'xy_to_n'} = \@xy_to_n;

  ### xy_to_n: $self->{'xy_to_n'}
  ### endpoints: $self->{'endpoints'}

  return $self;
}

my @dir4_to_dx = (1, 0, -1,  0);
my @dir4_to_dy = (0, 1,  0, -1);

sub _extend {
  my ($self) = @_;
  ### _extend() ...

  my $sq = $self->{'sq'};
  my $endpoints = $self->{'endpoints'};
  my $endpoint_dirs = $self->{'endpoint_dirs'};
  my $xy_to_n = $self->{'xy_to_n'};
  my $n_to_x = $self->{'n_to_x'};
  my $n_to_y = $self->{'n_to_y'};
  my $parts = $self->{'parts'};

  my $depth = scalar(@{$self->{'depth_to_n'}});
  ### $depth
  ### endpoints count: scalar(@$endpoints)

  my @new_endpoints;
  my @new_endpoint_dirs;
  my @new_x;
  my @new_y;

  foreach my $endpoint_sn (@$endpoints) {
    my $endpoint_dir = shift @$endpoint_dirs;
    my ($x,$y) = $sq->n_to_xy($endpoint_sn);
    ### endpoint: "$x,$y  dir=$endpoint_dir"

  SURROUND: foreach my $i (-1, 1) {
      my $dir = ($endpoint_dir + $i) % 4;
      my $x = $x + $dir4_to_dx[$dir];
      my $y = $y + $dir4_to_dy[$dir];
      ### consider: "$x,$y at dir=$dir"

      if ($parts eq '1') {
        if ($y <= 0 || $x <= 0) { next; }
      }
      if ($parts eq '2') {
        if ($y <= 0) { next; }
      }
      if ($parts eq '3') {
        if ($y <= 0 && $x < 0) { next; }
      }
      if ($parts eq '3w') {
        if ($y == 0 || ($y <= 0 && $x <= 0)) { next; }
      }
      if ($parts eq 'octant') {
        if ($y <= 0 || $y > $x+1) { next; }
      }
      if ($parts eq 'octant_up') {
        if ($x <= 0 || $x > $y) { next; }
      }
      if ($parts eq 'wedge') {
        if ($y < abs($x)) { next; }
      }
      if ($parts eq 'wedge+1') {
        if ($y < abs($x)-1) { next; }
      }

      if ($parts eq 'unwedge_down') {
        if ($y < -abs($x)) { next; }
      }
      if ($parts eq 'unwedge_down+1') {
        if ($y < -abs($x)-1) { next; }
      }
      if ($parts eq 'unwedge_down_W') {
        if ($y <= -abs($x-1)) { next; }
      }

      if ($parts eq 'unwedge_left') {
        if (abs($y) <= -$x) { next; }
      }
      if ($parts eq 'unwedge_left+1') {
        if (abs($y) < -$x) { next; }
      }
      if ($parts eq 'unwedge_left_S') {
        if (abs($y+1) <= -$x) { next; }
      }

      my $sn = $sq->xy_to_n($x,$y);
      if (defined($xy_to_n->[$sn])) {
        ### already occupied ...
        next;
      }

      my $count = 0;
      foreach my $j (0, 2) {
        my $dir = ($dir + $j) % 4;
        my $x = $x + $dir4_to_dx[$dir];
        my $y = $y + $dir4_to_dy[$dir];
        my $sn = $sq->xy_to_n($x,$y);
        ### count: "$x,$y at sn=$sn is ".($xy_to_n->[$sn] // 'undef')
        if (defined($xy_to_n->[$sn])) {
          if ($count++) {
            ### two or more surround ...
            next SURROUND;
          }
        }
      }
      ### only one neighbour, add this point ...
      push @new_endpoints, $sn;
      push @new_endpoint_dirs, $dir;
      push @new_x, $x;
      push @new_y, $y;
    }
  }

  my $n = scalar(@$n_to_x);
  push @{$self->{'depth_to_n'}}, $n;
  foreach my $sn (@new_endpoints) {
    $xy_to_n->[$sn] = $n++;
  }
  push @$n_to_x, @new_x;
  push @$n_to_y, @new_y;

  $self->{'endpoints'} = \@new_endpoints;
  $self->{'endpoint_dirs'} = \@new_endpoint_dirs;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### ToothpickTreeByCells n_to_xy(): $n

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

  while ($#{$self->{'n_to_x'}} < $n) {
    _extend($self);
  }

  ### x: $self->{'n_to_x'}->[$n]
  ### y: $self->{'n_to_y'}->[$n]
  return ($self->{'n_to_x'}->[$n],
          $self->{'n_to_y'}->[$n]);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### ToothpickTreeByCells xy_to_n(): "$x, $y"

  my ($depth,$exp) = round_down_pow (max($x,$y), 2);
  $depth *= 8;
  if (is_infinite($depth)) {
    return (1,$depth);
  }

  ### $depth
  for (;;) {
    {
      my $sn = $self->{'sq'}->xy_to_n($x,$y);
      if (defined (my $n = $self->{'xy_to_n'}->[$sn])) {
        return $n;
      }
    }
    if (scalar(@{$self->{'depth_to_n'}}) <= $depth) {
      _extend($self);
    } else {
      return undef;
    }
  }
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### ToothpickTreeByCells rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  my $depth = 8 * max(1,
                      abs($x1),
                      abs($x2),
                      abs($y1),
                      abs($y2));
  return (0, $depth*$depth);
}

sub tree_depth_to_n {
  my ($self, $depth) = @_;
  if ($depth < 0) {
    return undef;
  }
  if (is_infinite($depth)) {
    return $depth;
  }
  my $depth_to_n = $self->{'depth_to_n'};
  while ($#$depth_to_n <= $depth) {
    _extend($self);
  }
  return $depth_to_n->[$depth];
}
sub tree_n_to_depth {
  my ($self, $n) = @_;

  if ($n < 0) {
    return undef;
  }
  if (is_infinite($n)) {
    return $n;
  }
  my $depth_to_n = $self->{'depth_to_n'};
  for (my $depth = 1; ; $depth++) {
    while ($depth > $#$depth_to_n) {
      _extend($self);
    }
    if ($n < $depth_to_n->[$depth]) {
      return $depth-1;
    }
  }
}

sub tree_n_children {
  my ($self, $n) = @_;
  ### tree_n_children(): $n

  my ($x,$y) = $self->n_to_xy($n)
    or return;
  ### $x
  ### $y

  my @n = map { $self->xy_to_n($x+$dir4_to_dx[$_],$y+$dir4_to_dy[$_]) }
    0 .. $#dir4_to_dx;
  my $child_depth = $self->tree_n_to_depth($n) + 1;
  ### $child_depth

  ### @n
  # ### depths: map {defined $_ && $n_to_depth->[$_]} @n

  @n = sort {$a<=>$b}
    grep {defined $_ && $self->tree_n_to_depth($_) == $child_depth}
      @n;

  if ($self->{'parts'} eq '3w' && $n == 0) {
    unshift @n, 1;
  }

  ### found: @n
  return @n;
}
sub tree_n_parent {
  my ($self, $n) = @_;

  if ($self->{'parts'} eq '3w' && $n == 1) {
    return 0;
  }

  my ($x,$y) = $self->n_to_xy($n)
    or return undef;
  my $parent_depth = $self->tree_n_to_depth($n) - 1;
  ### $parent_depth

  foreach my $dir (0 .. $#dir4_to_dx) {
    if (defined (my $n = $self->xy_to_n($x+$dir4_to_dx[$dir],
                                        $y+$dir4_to_dy[$dir]))) {
      if ($self->tree_n_to_depth($n) == $parent_depth) {
        return $n;
      }
    }
  }
  return undef;
}

1;
__END__
