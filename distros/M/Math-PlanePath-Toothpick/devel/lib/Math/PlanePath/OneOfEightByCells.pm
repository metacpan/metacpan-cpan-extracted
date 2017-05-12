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


# Development version of "OneOfEight" done by cellular automaton.



# Tie::CArray
# Tie::Array::Pack  with pack()
# Tie::Array::Pack

package Math::PlanePath::OneOfEightByCells;
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
  [ { name            => 'parts',
      share_key       => 'parts_oneofeightbycells',
      display         => 'Parts',
      type            => 'enum',
      default         => 4,
      choices         => ['4','1','octant','octant_up','wedge',
                          '3mid','3side',
                          '1side','1side_up'],
      description     => 'Which parts of the plane to fill.',
    },
    # { name      => 'start',
    #   share_key => 'start_upstarplus',
    #   display   => 'Start',
    #   type      => 'enum',
    #   default   => 'one',
    #   choices   => ['one','two','three','four'],
    # },
  ];
use constant class_x_negative => 1;
use constant class_y_negative => 1;
{
  my %x_negative = (4         => 1,
                    1         => 0,
                    octant    => 0,
                    octant_up => 0,
                    wedge     => 1,
                    '3mid'    => 1,
                    '3side'   => 1,
                    side      => 0,
                   );
  sub x_negative {
    my ($self) = @_;
    return $x_negative{$self->{'parts'}};
  }
}
{
  my %x_minimum = (4         => undef,
                   1         => 0,
                   octant    => undef,
                   octant_up => undef,
                   wedge     => undef,
                   '3side'   => undef,
                   '3mid'    => undef,
                   side      => 0,
                  );
  sub x_minimum {
    my ($self) = @_;
    return $x_minimum{$self->{'parts'}};
  }
}
{
  my %y_negative = (4         => 1,
                    1         => 0,
                    octant    => 0,
                    octant_up => 0,
                    wedge     => 0,
                    '3mid'    => 1,
                    '3side'   => 1,
                    side      => 0,
                   );
  sub y_negative {
    my ($self) = @_;
    return $y_negative{$self->{'parts'}};
  }
}
{
  my %y_minimum = (4         => undef,
                   1         => 0,
                   octant    => 0,
                   octant_up => 0,
                   wedge     => 0,
                   '3mid'    => undef,
                   '3side'   => undef,
                   side      => 0,
                  );
  sub y_minimum {
    my ($self) = @_;
    return $y_minimum{$self->{'parts'}};
  }
}

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'sq'} = Math::PlanePath::SquareSpiral->new (n_start => 0);

  my $parts = ($self->{'parts'} ||= '4');
  my $start = ($self->{'start'} ||= 'one');
  my @n_to_x;
  my @n_to_y;
  if ($parts eq '1side' || $parts eq '1side_up') {
    @n_to_x = (0);
    @n_to_y = (0);
    $self->{'endpoints_dir'} = [ 4, 4 ];
  } elsif ($parts eq '3mid') {
    @n_to_x = (0);
    @n_to_y = (0);
    $self->{'endpoints_dir'} = [ 2 ];  # for numbering
  } elsif ($parts eq '3side') {
    @n_to_x = (0);
    @n_to_y = (0);
    $self->{'endpoints_dir'} = [ 2 ];  # for numbering
  } elsif ($parts eq '4' || $parts eq '1'
           || $parts eq 'octant' || $parts eq 'octant_up'
           || $parts eq 'wedge') {
    @n_to_x = (0);
    @n_to_y = (0);
    $self->{'endpoints_dir'} = [ 4 ];
  } else {
     croak "Unrecognised parts: ",$parts;
  }

  # } elsif ($start eq 'two') {
  #    @n_to_x = (0, -1);
  #    @n_to_y = (0, 0);
  #    $self->{'endpoints_dir'} = [ 0, 4 ];
  #  } elsif ($start eq 'three') {
  #    @n_to_x = (0, -1, -1);
  #    @n_to_y = (0, 0, -1);
  #    $self->{'endpoints_dir'} = [ 0, 6, 2 ];
  #  } elsif ($start eq 'four') {
  #    @n_to_x = (0, -1, -1, 0);
  #    @n_to_y = (0, 0, -1, -1);
  #    $self->{'endpoints_dir'} = [ 0, 2, 4, 6 ];

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

  my $parts = $self->{'parts'};
  my $sq = $self->{'sq'};
  my $endpoints = $self->{'endpoints'};
  my $endpoints_dir = $self->{'endpoints_dir'};
  my $xy_to_n = $self->{'xy_to_n'};
  my $n_to_x = $self->{'n_to_x'};
  my $n_to_y = $self->{'n_to_y'};

  ### depth: scalar(@{$self->{'depth_to_n'}})
  ### endpoints count: scalar(@$endpoints)

  my @new_endpoints;
  my @new_endpoints_dir;
  my @new_x;
  my @new_y;

  foreach my $endpoint_sn (@$endpoints) {
    my $dir = shift @$endpoints_dir;
    my ($x,$y) = $sq->n_to_xy($endpoint_sn);
    ### endpoint: "$x,$y"

  SURROUND: foreach my $i (0 .. $#surround8_dx) {
      my $dir = ($dir+4 + $i) & 7;
      my $x = $x + $surround8_dx[$dir];
      my $y = $y + $surround8_dy[$dir];
      if ($parts eq '1') {
        if ($x < 0 || $y < 0) { next; }
      }
      # if ($parts eq '1side') {
      #   if ($x < 0 || $y <= 0) { next; }
      # }
      # } elsif ($parts eq '3side') {
      #   if ($x < 0 && $y < 0) { next; }
      # } elsif ($parts eq 'octant') {
      #   if ($x < 0 || $y < 0 || $y > $x) { next; }

      ### consider: "$x,$y"
      my $sn = $sq->xy_to_n($x,$y);
      if (defined $xy_to_n->[$sn]) {
        ### already occupied ...
        next;
      }

      my $count = 0;
      foreach my $j (0 .. $#surround8_dx) {
        my $x = $x + $surround8_dx[$j];
        my $y = $y + $surround8_dy[$j];
        if ($parts eq '1') {
          # if ($x < -1 || $y < -1   # treating rest as occupied
          #     || ($y > 2 && $x < 0)
          #     || ($x > 2 && $y < 0)) { next SURROUND; }
          $x = abs($x);    # treating as quarter of parts=4
          $y = abs($y);
        }
        if ($parts eq 'octant') {
          if ($x < 0 || $y < ($x >= 3 ? 0 : -1) || $y > $x+2) { next SURROUND; }
        }
        if ($parts eq 'octant_up') {
          if ($y < 0 || $x < ($y >= 3 ? 0 : -1) || $x > $y+2) { next SURROUND; }
        }
        if ($parts eq 'wedge') {
          if ($x > $y+2 || $x < -$y-2) { next SURROUND; }
        }
        if ($parts eq '3mid') {
          if ($x < 0 && $y < 0) { next SURROUND; }
        }
        if ($parts eq '3side') {
          if ($x < 0 && $y <= 0) { next SURROUND; }
        }
        if ($parts eq '1side') {
          if ($y < -1) { next SURROUND; }
          if ($x < -1) { next SURROUND; }
          if ($y >= 3 && $x < 0) { next SURROUND; }
          if ($x >= 2 && $y < 0) { next SURROUND; }
          if ($x >= 2 && $y == -1) { next SURROUND; }
        }
        if ($parts eq '1side_up') {
          if ($x < -1) { next SURROUND; }
          if ($y < -1) { next SURROUND; }
          if ($x >= 3 && $y < 0) { next SURROUND; }
          if ($y >= 2 && $x < 0) { next SURROUND; }
          if ($y >= 2 && $x == -1) { next SURROUND; }
        }
        my $sn = $sq->xy_to_n($x,$y);
        ### count: "$x,$y at sn=$sn is ".($xy_to_n->[$sn] // 'undef')
        if (defined($xy_to_n->[$sn])) {
          if ($count++) {
            ### two or more surround ...
            next SURROUND;
          }
        }
      }
      push @new_endpoints, $sn;
      push @new_endpoints_dir, $dir;
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
  $self->{'endpoints_dir'} = \@new_endpoints_dir;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### OneOfEightByCells n_to_xy(): $n

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
  ### OneOfEightByCells xy_to_n(): "$x, $y"

  my ($depth,$exp) = round_down_pow (max(abs($x),abs($y))+3, 2);
  $depth = 2*$depth+2;
  ### depth limit: $depth
  if (is_infinite($depth)) {
    return (1,$depth);
  }

  for (;;) {
    {
      my $sn = $self->{'sq'}->xy_to_n($x,$y);
      if (defined (my $n = $self->{'xy_to_n'}->[$sn])) {
        ### found: $n
        return $n;
      }
    }
    if (scalar(@{$self->{'depth_to_n'}}) <= $depth) {
      _extend($self);
    } else {
      ### stop, depth_to_n[] past target: $depth
      return undef;
    }
  }
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### OneOfEightByCells rect_to_n_range(): "$x1,$y1  $x2,$y2"

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
    or return undef;
  ### $x
  ### $y

  my $depth = $self->tree_n_to_depth($n) + 1;
  return
    sort {$a<=>$b}
      grep { $self->tree_n_to_depth($_) == $depth }
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
