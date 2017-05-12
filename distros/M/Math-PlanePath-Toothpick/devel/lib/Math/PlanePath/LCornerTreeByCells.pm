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


# Development version of "LCornerTree" done by cellular automaton.



package Math::PlanePath::LCornerTreeByCells;
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
      share_key       => 'parts_lcornertreebycells',
      display         => 'Parts',
      type            => 'enum',
      default         => '4',
      choices         => ['4','2','1',
                          'octant','octant+1',
                          'octant_up','octant_up+1',
                          'wedge','wedge+1','single',
                          'pair',
                          'diagonal','diagonal-1','diagonal-2'],
      description     => 'Which parts of the plane to fill.',
    },
  ];
use constant class_x_negative => 1;
use constant class_y_negative => 1;
{
  my %x_negative = (1             => 0,
                    octant        => 0,
                    'octant+1'    => 0,
                    octant_up     => 0,
                    'octant_up+1' => 0,
                    wedge         => 1,
                    'wedge+1'     => 1,
                    single        => 1,
                    pair          => 1,
                   );
  sub x_negative {
    my ($self) = @_;
    return $x_negative{$self->{'parts'}};
  }
}
{
  my %y_negative = (4             => 1,
                    1             => 0,
                    octant        => 0,
                    'octant+1'    => 0,
                    octant_up     => 0,
                    'octant_up+1' => 0,
                    wedge         => 0,
                    'wedge+1'     => 0,
                    pair          => 1,
                   );
  sub y_negative {
    my ($self) = @_;
    return $y_negative{$self->{'parts'}};
  }
}
# {
#   my %y_minimum = (4          => undef,
#                    1          => 0,
#                    octant     => 0,
#                    octant_up  => 0,
#                    wedge      => 0,
#                    pair       => undef,
#                   );
#   sub y_minimum {
#     my ($self) = @_;
#     return $y_minimum{$self->{'parts'}};
#   }
# }

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'sq'} = Math::PlanePath::SquareSpiral->new (n_start => 0);

  my $parts = ($self->{'parts'} ||= '4');
  my $start = ($self->{'start'} ||= 'one');
  $self->{'depth_to_n'} = [0];
  my @n_to_x;
  my @n_to_y;
  if ($parts eq '4') {
    @n_to_x = (0, -1, -1,  0);
    @n_to_y = (0, 0,  -1, -1);
    $self->{'endpoints_dir'} = [ 0, 1, 2, 3 ];
  } elsif ($parts eq '2') {
    @n_to_x = (0, -1);
    @n_to_y = (0, 0);
    $self->{'endpoints_dir'} = [ 0, 1 ];
  } elsif ($parts eq '1' || $parts eq 'octant' || $parts eq 'octant+1'
           || $parts eq 'octant_up' || $parts eq 'octant_up+1') {
    @n_to_x = (0);
    @n_to_y = (0);
    $self->{'endpoints_dir'} = [ 0 ];
  } elsif ($parts eq 'wedge' || $parts eq 'wedge+1') {
    @n_to_x = (0, -1);
    @n_to_y = (0, 0);
    $self->{'endpoints_dir'} = [ 0, 1 ];
  } elsif ($parts eq 'single') {
    @n_to_x = (0);
    @n_to_y = (0);
    $self->{'endpoints_dir'} = [ 0 ];
  } elsif ($parts eq 'diagonal') {
    @n_to_x = (0, 0, -1);
    @n_to_y = (-1, 0, 0);
    $self->{'endpoints_dir'} = [ 3, 0, 1 ];
  } elsif ($parts eq 'diagonal-1') {
    @n_to_x = (0);
    @n_to_y = (0);
    $self->{'endpoints_dir'} = [ 0 ];
  } elsif ($parts eq 'diagonal-2') {
    @n_to_x = (0, 1,1,0, -1,-1,0);
    @n_to_y = (0, 0,1,1, 0,-1,-1);
    $self->{'endpoints_dir'} = [ 0, 3,0,1, 1,2,3 ];
    $self->{'depth_to_n'} = [0, 1];
  } elsif ($parts eq 'pair') {
    @n_to_x = (-1, 0);
    @n_to_y = (0, 1);
    $self->{'endpoints_dir'} = [ 2, 0 ];
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
    my $parent_sn = ($parts eq 'diagonal-2' && $n > 0 ? $self->{'sq'}->xy_to_n(0,0)
                     : undef);
    $self->{'sn_to_parent_sn'}->[$sn] = $parent_sn;
  }
  $self->{'endpoints'} = \@endpoints;
  $self->{'xy_to_n'} = \@xy_to_n;

  ### xy_to_n: $self->{'xy_to_n'}
  ### endpoints: $self->{'endpoints'}

  return $self;
}

my @surround4_dx = (1, 0, -1,  0);
my @surround4_dy = (0, 1,  0, -1);

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
  my $sn_to_parent_sn = $self->{'sn_to_parent_sn'};

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

  SURROUND: foreach my $i (0 .. 0) {  # $#surround4_dx
      my $dx = $surround4_dx[$dir];
      my $dy = $surround4_dy[$dir];

      my $x1 = $x + $dx;
      my $y1 = $y + $dy;
      my $sn1 = $sq->xy_to_n($x1,$y1);

      my $x2 = $x + $dx - $dy;  # diagonal rotate +45
      my $y2 = $y + $dy + $dx;
      my $sn2 = $sq->xy_to_n($x2,$y2);

      my $x3 = $x - $dy;   # rotate +90
      my $y3 = $y + $dx;
      my $sn3 = $sq->xy_to_n($x3,$y3);

      ### corner direction: "$dir   $x1,$y1  $x2,$y2  $x3,$y3"

      if (defined $xy_to_n->[$sn1]) {
        ### sn1 already occupied ...
        next;
      }
      if (defined $xy_to_n->[$sn2]) {
        ### sn2 already occupied ...
        next;
      }
      if (defined $xy_to_n->[$sn3]) {
        ### sn3 already occupied ...
        next;
      }

      if ($parts eq '1' || $parts eq 'octant' || $parts eq 'octant_up') {
        if ($x1 < 0 || $y1 < 0
            || $x2 < 0 || $y2 < 0
            || $x3 < 0 || $y3 < 0
           ) {
          ### outside first quardrant ...
          next;
        }
      } elsif ($parts eq 'octant+1') {
        if ($y1 < 0 || $x1<$y1-1
            || $y2 < 0 || $x2<$y2-1
            || $y3 < 0 || $x3<$y3-1
           ) {
          next;
        }
      } elsif ($parts eq 'octant_up+1') {
        if ($x1 < 0 || $y1<$x1-1
            || $x2 < 0 || $y2<$x2-1
            || $x3 < 0 || $y3<$x3-1
           ) {
          next;
        }
      } elsif ($parts eq 'wedge+1') {
        if ($y1 < 0 || $x1<-$y1-2 || $x1>$y1+1
            || $y2 < 0 || $x2<-$y2-2 || $x2>$y2+1
            || $y3 < 0 || $x3<-$y3-2 || $x3>$y3+1
           ) {
          next;
        }
      } elsif ($parts eq '2') {
        if ($y1 < 0 || $y2 < 0 || $y3 < 0) {
          ### outside upper half-plane ...
          next;
        }
      } elsif ($parts eq 'diagonal') {
        # if ($x!=$y && $x+$y <= 0) {
        #   ### outside diagonal ...
        #   next;
        # }
      } elsif ($parts eq 'diagonal-1') {
        if ($x!=$y && $x+$y <= 0) {
          ### outside diagonal ...
          next;
        }
      } elsif ($parts eq 'diagonal-2') {
        if ($x-$y != 0 && $x+$y >= -0 && $x+$y <= 0) {
          ### diagonal-2 not on diagonal ...
          next;
        }
      } elsif ($parts eq 'single') {
        if ($x == 0 && $y == 0 && ($x1 < 0 || $y1 < 0
                                   || $x2 < 0 || $y2 < 0
                                   || $x3 < 0 || $y3 < 0
                                  )) {
          ### outside single ...
          next;
        }
      }

      if (! ($parts eq 'wedge' && ($x1 < -1-$y1 || $x1 > $y1))
          && ! ($parts eq 'octant' && ($y1 > $x1))
          && ! ($parts eq 'octant_up' && ($x1 > $y1))
          && ! ($parts eq 'diagonal' && $x1+$y1 < -1)
          && ! ($parts eq 'diagonal-2' && $x1 < 0 && $x1+$y1==0)
         ) {
        push @new_endpoints, $sn1;
        push @new_endpoints_dir, ($dir-1)&3;
        push @new_x, $x1;
        push @new_y, $y1;
        $sn_to_parent_sn->[$sn1] = $endpoint_sn;
      }
      if (! ($parts eq 'wedge' && ($x2 < -1-$y2 || $x2 > $y2))
          && ! ($parts eq 'octant' && ($y2 > $x2))
          && ! ($parts eq 'octant_up' && ($x2 > $y2))
          && ! ($parts eq 'diagonal' && $x2+$y2 < -1)
         ) {
        push @new_endpoints, $sn2;
        push @new_endpoints_dir, $dir;
        push @new_x, $x2;
        push @new_y, $y2;
        $sn_to_parent_sn->[$sn2] = $endpoint_sn;
      }
      if (! ($parts eq 'wedge' && ($x3 < -1-$y3 || $x3 > $y3))
          && ! ($parts eq 'octant' && ($y3 > $x3))
          && ! ($parts eq 'octant_up' && ($x3 > $y3))
          && ! ($parts eq 'diagonal' && $x3+$y3 < -1)
          && ! ($parts eq 'diagonal-2' && $x3 > 0 && $x3+$y3==0)
         ) {
        push @new_endpoints, $sn3;
        push @new_endpoints_dir, ($dir+1)&3;
        push @new_x, $x3;
        push @new_y, $y3;
        $sn_to_parent_sn->[$sn3] = $endpoint_sn;
      }
    }
  }

  ### count new endpoints: scalar(@new_endpoints)
  die "no new endpoints" if @new_endpoints == 0;

  my $n = scalar(@$n_to_x);
  push @{$self->{'depth_to_n'}}, $n;
  foreach my $sn (@new_endpoints) {
    $xy_to_n->[$sn] = $n++;
  }
  push @$n_to_x, @new_x;
  push @$n_to_y, @new_y;

  $self->{'endpoints'} = \@new_endpoints;
  $self->{'endpoints_dir'} = \@new_endpoints_dir;
  return scalar(@new_endpoints);
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### LCornerTreeByCells n_to_xy(): $n

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
    _extend($self) || return;
  }

  ### x: $self->{'n_to_x'}->[$n]
  ### y: $self->{'n_to_y'}->[$n]
  return ($self->{'n_to_x'}->[$n],
          $self->{'n_to_y'}->[$n]);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### LCornerTreeByCells xy_to_n(): "$x, $y"

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
  ### LCornerTreeByCells rect_to_n_range(): "$x1,$y1  $x2,$y2"

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
      grep { my $n_parent = $self->tree_n_parent($_);
             (defined $n_parent && $n_parent == $n) }
        map { $self->xy_to_n_list($x + $surround8_dx[$_],
                                  $y + $surround8_dy[$_]) }
          0 .. $#surround8_dx;
}
sub tree_n_parent {
  my ($self, $n) = @_;
  ### tree_n_parent(): $n

  my ($x,$y) = $self->n_to_xy($n)
    or return undef;
  my $sn = $self->{'sq'}->xy_to_n($x,$y);
  $sn = $self->{'sn_to_parent_sn'}->[$sn];
  if (! defined $sn) {
    return undef;
  }
  ($x,$y) = $self->{'sq'}->n_to_xy($sn);
  return $self->xy_to_n($x,$y);
}

1;
__END__
