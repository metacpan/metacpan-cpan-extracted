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


# two-of-eight
# A151731, A151732, A151733, A151734


package Math::PlanePath::TwoOfEightByCells;
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
  [ { name      => 'start',
      share_key => 'start_twoofeightbycells',
      display   => 'Start',
      type      => 'enum',
      default   => 'two',
      choices   => ['two','three','four'],
    },
  ];


sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'sq'} = Math::PlanePath::SquareSpiral->new (n_start => 0);

  my $start = ($self->{'start'} ||= 'two');
  my @n_to_x;
  my @n_to_y;
  if ($start eq 'one') {
    @n_to_x = (0);
    @n_to_y = (0);
  } elsif ($start eq 'two') {
    @n_to_x = (0, -1);
    @n_to_y = (0, 0);
  } elsif ($start eq 'three') {
    @n_to_x = (0, -1, -1);
    @n_to_y = (0, 0, -1);
  } elsif ($start eq 'four') {
    @n_to_x = (0, -1, -1, 0);
    @n_to_y = (0, 0, -1, -1);
  } else {
    croak "Unrecognised start: ",$start;
  }
  $self->{'n_to_x'} = \@n_to_x;
  $self->{'n_to_y'} = \@n_to_y;
  $self->{'depth_to_n'} = [0];

  my @endpoints;
  my @xy_to_n;
  foreach my $n (0 .. $#n_to_x) {
    my $sn = $self->{'sq'}->xy_to_n($n_to_x[$n],$n_to_y[$n]);
    $xy_to_n[$sn] = $n;
    push @endpoints, $sn;
  }
  $self->{'endpoints'} = \@endpoints;
  $self->{'xy_to_n'} = \@xy_to_n;

  ### xy_to_n: $self->{'xy_to_n'}
  ### endpoints: $self->{'endpoints'}

  return $self;
}

my @surround8_dx = (1, 1, 0, -1, -1, -1,  0,  1);
my @surround8_dy = (0, 1, 1,  1,  0, -1, -1, -1);

sub _extend {
  my ($self) = @_;
  ### _extend() ...

  my $sq = $self->{'sq'};
  my $endpoints = $self->{'endpoints'};
  my $xy_to_n = $self->{'xy_to_n'};
  my $n_to_x = $self->{'n_to_x'};
  my $n_to_y = $self->{'n_to_y'};

  ### depth: scalar(@{$self->{'depth_to_n'}})
  ### endpoints count: scalar(@$endpoints)

  my @new_endpoints;
  my @new_x;
  my @new_y;

  foreach my $n (0 .. $#$n_to_x) {
    my $x = $n_to_x->[$n];
    my $y = $n_to_y->[$n];
    ### endpoint: "$x,$y"

  SURROUND: foreach my $i (0 .. $#surround8_dx) {
      my $x = $x + $surround8_dx[$i];
      my $y = $y + $surround8_dy[$i];
      ### consider: "$x,$y"
      my $sn = $sq->xy_to_n($x,$y);
      if (defined $xy_to_n->[$sn]) {
        ### occupied ...
        next;
      }

      my $count = 0;
      foreach my $j (0 .. $#surround8_dx) {
        my $x = $x + $surround8_dx[$j];
        my $y = $y + $surround8_dy[$j];
        my $sn = $sq->xy_to_n($x,$y);
        ### count: "$x,$y at sn=$sn is n=".($xy_to_n->[$sn] // 'undef')
        if (defined($xy_to_n->[$sn])) {
          if (++$count > 2) {
            ### more than two surround ...
            next SURROUND;
          }
        }
      }
      ### $count
      if ($count == 2) {
        ### new: "$x,$y"
        push @new_endpoints, $sn;
        push @new_x, $x;
        push @new_y, $y;
      }
    }
  }

  my $n = scalar(@$n_to_x);
  push @{$self->{'depth_to_n'}}, $n;
  foreach my $sn (@new_endpoints) {
    my $x = shift @new_x;
    my $y = shift @new_y;
    if (! defined $xy_to_n->[$sn]) {
      push @$n_to_x, $x;
      push @$n_to_y, $y;
      $xy_to_n->[$sn] = $n++;
    }
  }

  $self->{'endpoints'} = \@new_endpoints;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### TwoOfEightByCells n_to_xy(): $n

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

  while ($#{$self->{'n_to_x'}} < $n && @{$self->{'endpoints'}}) {
    _extend($self);
  }

  ### x: $self->{'n_to_x'}->[$n]
  ### y: $self->{'n_to_y'}->[$n]
  return ($self->{'n_to_x'}->[$n],
          $self->{'n_to_y'}->[$n]);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### TwoOfEightByCells xy_to_n(): "$x, $y"

  my ($depth,$exp) = round_down_pow (max($x,$y), 2);
  $depth *= 2;
  if (is_infinite($depth)) {
    return (1,$depth);
  }
  ### $depth

  for (;;) {
    {
      my $sn = $self->{'sq'}->xy_to_n($x,$y);
      if (defined (my $n = $self->{'xy_to_n'}->[$sn])) {
        ### found at: "sn=$sn  n=$n"
        return $n;
      }
    }
    if (scalar(@{$self->{'depth_to_n'}}) > $depth
        || ! @{$self->{'endpoints'}}) {
      ### past target depth, or no more endpoints ...
      return undef;
    }
    _extend($self);
  }
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### TwoOfEightByCells rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  my $depth = 4 * max(1,
                      abs($x1),
                      abs($x2),
                      abs($y1),
                      abs($y2));
  return (0, $depth*$depth);
}

sub tree_depth_to_n {
  my ($self, $depth) = @_;
  my $depth_to_n = $self->{'depth_to_n'};
  while ($#$depth_to_n <= $depth && @{$self->{'endpoints'}}) {
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
      if (! @{$self->{'endpoints'}}) {
        return undef;
      }
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
    or return undef;
  ### $x
  ### $y

  my $depth = $self->tree_n_to_depth($n) + 1;
  return grep { $self->tree_n_to_depth($_) == $depth }
    map { $self->xy_to_n_list($x + $surround8_dx[$_],
                              $y + $surround8_dy[$_]) }
      0 .. $#surround8_dx;
}
sub tree_n_parent {
  my ($self, $n) = @_;

  if ($n < 0) {
    return undef;
  }
  my ($x,$y) = $self->n_to_xy($n)
    or return undef;
  my $parent_depth = $self->tree_n_to_depth($n) - 1;

  foreach my $i (0 .. $#surround8_dx) {
    my $pn = $self->xy_to_n($x + $surround8_dx[$i],
                            $y + $surround8_dy[$i]);
    if (defined $pn && $self->tree_n_to_depth($pn) == $parent_depth) {
      return $pn;
    }
  }
  return undef;
}

1;
__END__
