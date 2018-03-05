# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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


# math-image --values=PlanePathTurn
#
# maybe:
# Turn4    0,1,2,3  and fractional
# Turn4n   0,1,2,-1  negatives    Turn4mid Turn4n Turn4s
# TTurn6n   0,1,2,3, -1,-2,  eg. flowsnake  TTurn6s
# TTurn6   0,1,2,3,4,5



package Math::NumSeq::PlanePathTurn;
use 5.004;
use strict;
use Carp 'croak';

use vars '$VERSION','@ISA';
$VERSION = 126;
use Math::NumSeq;
@ISA = ('Math::NumSeq');

use Math::NumSeq::PlanePathCoord;
use Math::PlanePath;
use Math::PlanePath::Base::Generic
  'is_infinite';
use Math::NumSeq::PlanePathDelta;

# uncomment this to run the ### lines
# use Smart::Comments;

use constant characteristic_smaller => 1;

sub description {
  my ($self) = @_;
  if (ref $self) {
    return "Turn values $self->{'turn_type'} from path $self->{'planepath'}";
  } else {
    # class method
    return 'Turns from a PlanePath';
  }
}

use constant::defer parameter_info_array =>
  sub {
    return [
            Math::NumSeq::PlanePathCoord::_parameter_info_planepath(),
            {
             name    => 'turn_type',
             display => 'Turn Type',
             type    => 'enum',
             default => 'Left',
             choices => ['Left','Right','Straight',
                         'LSR','SLR','SRL',
                          
                         # 'NotStraight',
                         # 'Straight',
                         # 'RSL',
                         # 'Turn4',  # Turn4 is 0<=value<4.
                         # 'Turn4n',
                         # 'TTurn6',
                        ],
             description => 'Left is 1=left, 0=right or straight.
Right is 1=right, 0=left or straight.
LSR is 1=left,0=straight,-1=right.
SLR is 0=straight,1=left,2=right.
SRL is 0=straight,1=right,2=left.',
            },
           ];
  };

sub characteristic_integer {
  my ($self) = @_;
  my $planepath_object = $self->{'planepath_object'};
  if (my $func = $planepath_object->can("_NumSeq_Turn_$self->{'turn_type'}_integer")) {
    return $planepath_object->$func();
  }
  return undef;
}

#------------------------------------------------------------------------------

sub oeis_anum {
  my ($self) = @_;
  ### PlanePathTurn oeis_anum() ...

  my $planepath = $self->{'planepath_object'};
  my $key = Math::NumSeq::PlanePathCoord::_planepath_oeis_anum_key($self->{'planepath_object'});

  ### planepath: ref $planepath
  ### $key
  ### whole table: $planepath->_NumSeq_Turn_oeis_anum
  ### key href: $planepath->_NumSeq_Turn_oeis_anum->{$key}

  return $planepath->_NumSeq_Turn_oeis_anum->{$key}->{$self->{'turn_type'}};
}

#------------------------------------------------------------------------------

sub new {
  ### PlanePathTurn new(): @_
  my $self = shift->SUPER::new(@_);
  ### self from SUPER: $self

  $self->{'planepath_object'}
    ||= Math::NumSeq::PlanePathCoord::_planepath_name_to_object($self->{'planepath'});

  ### turn_func: "_turn_func_$self->{'turn_type'}", $self->{'turn_func'}
  $self->{'turn_func'} = $self->can('_turn_func_'.$self->{'turn_type'})
    || croak "Unrecognised turn_type: ",$self->{'turn_type'};

  $self->rewind;
  ### $self
  return $self;
}

sub i_start {
  my ($self) = @_;
  my $planepath_object = $self->{'planepath_object'} || return 0;
  return $planepath_object->n_start + $planepath_object->arms_count;
}
sub rewind {
  my ($self) = @_;
  my $planepath_object = $self->{'planepath_object'} || return;

  $self->{'i'} = $self->i_start;
  $self->{'arms'} = $planepath_object->arms_count;
  undef $self->{'prev_dx'};
}

sub next {
  my ($self) = @_;
  ### NumSeq-PlanePathTurn next(): "i=$self->{'i'}"

  my $planepath_object = $self->{'planepath_object'};

  my $i = $self->{'i'}++;
  my $arms = $self->{'arms'};

  my $prev_dx = $self->{'prev_dx'};
  my $prev_dy;
  if (defined $prev_dx) {
    $prev_dy = $self->{'prev_dy'};
    ### use prev dxdy: "$prev_dx,$prev_dy"
  } else {
    ($prev_dx, $prev_dy) = $planepath_object->n_to_dxdy($i-$arms)
      or do {
        ### nothing in path at n: $i
        return;
      };
    ### calc prev dxdy: "at i=".($i-$arms)."   $prev_dx,$prev_dy"
  }

  my ($dx, $dy) = $planepath_object->n_to_dxdy($i)
    or do {
      ### nothing in path at previous n: $i-$arms
      return;
    };
  ### calc dxdy: "at i=$i   $dx,$dy"

  if ($arms == 1) {
    $self->{'prev_dx'} = $dx;
    $self->{'prev_dy'} = $dy;
  }
  return ($i, $self->{'turn_func'}->($prev_dx,$prev_dy, $dx,$dy));
}

sub ith {
  my ($self, $i) = @_;
  ### PlanePathTurn ith(): $i

  if (is_infinite($i)) {
    return undef;
  }
  my $planepath_object = $self->{'planepath_object'};
  my $arms = $self->{'arms'};
  my ($prev_dx, $prev_dy) = $planepath_object->n_to_dxdy($i - $arms)
    or return undef;
  my ($dx, $dy) = $planepath_object->n_to_dxdy($i)
    or return undef;
  return $self->{'turn_func'}->($prev_dx,$prev_dy, $dx,$dy);
}

#            dx1,dy1
#  dx2,dy2  /
#       *  /
#         /
#        /
#       /
#      /
#     O
#
# cmpy = dx2 * dy1/dx1
# left if dy2 > cmpy
#         dy2 > dx2 * dy1/dx1
#         dy2 * dx1 > dx2 * dy1
#
# if dx1=0, dy1 > 0 then left if dx2 < 0
#    dy2 * 0 > dx2 * dy1
#          0 > dx2*dy1     good
#
sub _turn_func_Left {
  my ($dx,$dy, $next_dx,$next_dy) = @_;
  ### _turn_func_Left() ...
  return ($next_dy * $dx > $next_dx * $dy ? 1 : 0);
}
sub _turn_func_Right {
  my ($dx,$dy, $next_dx,$next_dy) = @_;
  ### _turn_func_Right() ...
  return ($next_dy * $dx < $next_dx * $dy ? 1 : 0);
}
sub _turn_func_LSR {
  my ($dx,$dy, $next_dx,$next_dy) = @_;
  ### _turn_func_LSR() ...
  return (($next_dy * $dx <=> $next_dx * $dy) || 0);  # 1,0,-1
}
sub _turn_func_RSL {
  return - _turn_func_LSR(@_);
}
{
  my @LSR_to_SLR = (0,  # LSR=0  straight -> SLR=0
                    1,  # LSR=1  left     -> SLR=1
                    2); # LSR=-1 right    -> SLR=2
  sub _turn_func_SLR {
    return $LSR_to_SLR[_turn_func_LSR(@_)];
  }
}
{
  my @LSR_to_SRL = (0,  # LSR=0  straight -> SRL=0
                    2,  # LSR=1  left     -> SRL=2
                    1); # LSR=-1 right    -> SRL=1
  sub _turn_func_SRL {
    return $LSR_to_SRL[_turn_func_LSR(@_)];
  }
}
sub _turn_func_Straight {
  my ($dx,$dy, $next_dx,$next_dy) = @_;
  ### _turn_func_Left() ...
  return ($next_dy * $dx == $next_dx * $dy ? 1 : 0);
}
sub _turn_func_NotStraight {
  my ($dx,$dy, $next_dx,$next_dy) = @_;
  ### _turn_func_Left() ...
  return ($next_dy * $dx == $next_dx * $dy ? 0 : 1);
}

#---------------
# experimental extras

# sub _turn_func_LR_01 {
#   my ($dx,$dy, $next_dx,$next_dy) = @_;
#   ### _turn_func_LR_01() ...
#   return ($next_dy * $dx >= $next_dx * $dy || 0);
# }

# 0,1,2,3 as ddir mod 4, incl fractional
sub _turn_func_Turn4 {
  my ($dx,$dy, $next_dx,$next_dy) = @_;
  ### _turn_func_Turn4(): "$dx,$dy  $next_dx,$next_dy"
  return
    (((Math::NumSeq::PlanePathDelta::_delta_func_Dir360($next_dx,$next_dy)
       - Math::NumSeq::PlanePathDelta::_delta_func_Dir360($dx,$dy)) % 360)
     / 90);
}
# 0,1,2, -1
# MAYBE: 0 <= t < 2 and -2 <= t < 0 for symmetry, so reverse=-2
sub _turn_func_Turn4n {
  my ($dx,$dy, $next_dx,$next_dy) = @_;
  require Math::NumSeq::PlanePathDelta;
  my $ret
    = (((Math::NumSeq::PlanePathDelta::_delta_func_Dir360($next_dx,$next_dy)
         - Math::NumSeq::PlanePathDelta::_delta_func_Dir360($dx,$dy)) % 360)
       / 90);
  if ($ret > 2) { $ret -= 4; }
  return $ret;
}

# 0,1,2,3,4,5 as dtdir mod 6, incl fractional
sub _turn_func_TTurn6 {
  my ($dx,$dy, $next_dx,$next_dy) = @_;
  require Math::NumSeq::PlanePathDelta;
  return
    (((Math::NumSeq::PlanePathDelta::_delta_func_TDir360($next_dx,$next_dy)
       - Math::NumSeq::PlanePathDelta::_delta_func_TDir360($dx,$dy)) % 360)
     / 60);
}
# 0,1,2,3, -2,-1
# MAYBE: 0 <= t < 3 and -3 <= t < 0 for symmetry, so reverse=-3
sub _turn_func_TTurn6n {
  my $t = _turn_func_TTurn6(@_);
  return ($t <= 3 ? $t : $t-6);
}

#---------

sub pred {
  my ($self, $value) = @_;
  ### PlanePathTurn pred(): $value
  my $planepath_object = $self->{'planepath_object'};

  if (defined (my $values_min = $self->values_min)) {
    if ($value < $values_min) {
      return 0;
    }
  }
  if (defined (my $values_max = $self->values_max)) {
    if ($value > $values_max) {
      return 0;
    }
  }

  my $turn_type = $self->{'turn_type'};
  if ($turn_type eq 'Left' || $turn_type eq 'Right' || $turn_type eq 'Straight') {
    unless ($value == 0 || $value == 1) {
      return 0;
    }
  } elsif ($turn_type eq 'LSR' || $turn_type eq 'RSL') {
    unless ($value == 1 || $value == 0 || $value == -1) {
      return 0;
    }
  } else { # ($turn_type eq 'SLR' || $turn_type eq 'SRL') {
    unless ($value == 0 || $value == 1 || $value == 2) {
      return 0;
    }
  }

  if (my $func = $planepath_object->can('_NumSeq_Turn_'.$self->{'turn_type'}.'_pred_hash')) {
    my $href = $self->$func();
    unless ($href->{$value}) {
      return 0;
    }
  }

  return 1;
}



#------------------------------------------------------------------------------

sub values_min {
  my ($self) = @_;

  my $method = '_NumSeq_Turn_' . $self->{'turn_type'} . '_min';
  return $self->{'planepath_object'}->can($method)
    ? $self->{'planepath_object'}->$method()
      : undef;
}

sub values_max {
  my ($self) = @_;

  my $method = '_NumSeq_Turn_' . $self->{'turn_type'} . '_max';
  return $self->{'planepath_object'}->can($method)
    ? $self->{'planepath_object'}->$method()
      : undef;
}

sub characteristic_increasing {
  my ($self) = @_;
  my $planepath_object = $self->{'planepath_object'};
  if (my $func = $planepath_object->can("_NumSeq_Turn_$self->{'turn_type'}_increasing")) {
    return $planepath_object->$func();
  }
  return undef; # unknown
}

sub characteristic_non_decreasing {
  my ($self) = @_;
  my $planepath_object = $self->{'planepath_object'};
  if (my $func = $planepath_object->can("_NumSeq_Turn_$self->{'turn_type'}_non_decreasing")) {
    return $planepath_object->$func();
  }
  if (defined (my $values_min = $self->values_min)) {
    if (defined (my $values_max = $self->values_max)) {
      if ($values_min == $values_max) {
        # constant seq is non-decreasing
        return 1;
      }
    }
  }
  # increasing means non_decreasing too
  return $self->characteristic_increasing;
}

# my $all_Left_predhash = { 0=>1, 1=>1 };
# my $all_LSR_predhash = { 0=>1, 1=>1, -1=>1 };
# my $straight_Left_predhash = { 0=>1 };
# my $straight_LSR_predhash = { 0=>1 };

{ package Math::PlanePath;
  use constant 1.02; # for leading underscore

  sub _NumSeq_Turn_Left_min {
    my ($self) = @_;
    return ($self->turn_any_right
            || $self->turn_any_straight ? 0 : 1);
  }
  sub _NumSeq_Turn_Left_max {
    my ($self) = @_;
    return ($self->turn_any_left ? 1 : 0);
  }
  use constant _NumSeq_Turn_Left_integer => 1;

  sub _NumSeq_Turn_Right_min {
    my ($self) = @_;
    return ($self->turn_any_left
            || $self->turn_any_straight ? 0 : 1);
  }
  sub _NumSeq_Turn_Right_max {
    my ($self) = @_;
    return ($self->turn_any_right ? 1 : 0);
  }
  use constant _NumSeq_Turn_Right_integer => 1;

  sub _NumSeq_Turn_Straight_min {
    my ($self) = @_;
    return ($self->turn_any_left
            || $self->turn_any_right ? 0 : 1);
  }
  sub _NumSeq_Turn_Straight_max {
    my ($self) = @_;
    return ($self->turn_any_straight ? 1 : 0);
  }
  use constant _NumSeq_Turn_Straight_integer => 1;

  sub _NumSeq_Turn_LSR_min {
    my ($self) = @_;
    return ($self->turn_any_right      ? -1
            : $self->turn_any_straight ? 0
            : 1);  # only ever Left
  }
  sub _NumSeq_Turn_LSR_max {
    my ($self) = @_;
    return ($self->turn_any_left       ? 1
            : $self->turn_any_straight ? 0
            : -1);  # only ever Right
  }
  use constant _NumSeq_Turn_LSR_integer => 1;

  sub _NumSeq_Turn_SLR_min {
    my ($self) = @_;
    return ($self->turn_any_straight ? 0
            : $self->turn_any_left   ? 1
            : 2);  # only ever Right
  }
  sub _NumSeq_Turn_SLR_max {
    my ($self) = @_;
    return ($self->turn_any_right ? 2
            : $self->_NumSeq_Turn_Left_max); # 1 if any Left 
  }
  use constant _NumSeq_Turn_SLR_integer => 1;

  sub _NumSeq_Turn_SRL_min {
    my ($self) = @_;
    return ($self->turn_any_straight ? 0
            : $self->turn_any_right  ? 1
            : 2);  # only ever Left
  }
  sub _NumSeq_Turn_SRL_max {
    my ($self) = @_;
    return ($self->turn_any_left ? 2
            : $self->_NumSeq_Turn_Right_max);  # 1 if any Right
  }
  use constant _NumSeq_Turn_SRL_integer => 1;

  use constant _NumSeq_Turn_Turn4_min => 0;
  sub _NumSeq_Turn_Turn4_integer {
    my ($self) = @_;
    return $self->_NumSeq_Delta_Dir4_integer;
  }
  sub _NumSeq_Turn_Turn4_max {
    my ($self) = @_;
    return ($self->_NumSeq_Turn_Turn4_integer ? 3 : 4);
  }

  use constant _NumSeq_Turn_oeis_anum => {};
}

# { package Math::PlanePath::SquareSpiral;
#   # SquareSpiral
#   # abs(A167752)==Left=LSR=Turn4 if that really is the quarter-squares
#   # abs(A167753)==Left=LSR=Turn4 of wider=1 if that really is the ceil(n+1)^2
# }
{ package Math::PlanePath::GreekKeySpiral;
  sub _NumSeq_Turn_Turn4_max {
    my ($self) = @_;
    return ($self->{'turns'} == 0
            ? 1    # SquareSpiral, left or straight only
            : 3);  # otherwise turn right too
  }
}
{ package Math::PlanePath::PyramidSpiral;
  use constant _NumSeq_Turn_Turn4_max => 1.5;
}
{ package Math::PlanePath::TriangleSpiral;
  use constant _NumSeq_Turn_Turn4_max => 1.5;

  use constant _NumSeq_Turn_oeis_anum =>
    { 'n_start=-1' =>
      { Left     => 'A023531',  # 1 at k*(k+3)/2
        LSR      => 'A023531',
        Straight => 'A023532',  # 0 at k*(k+3)/2, 1 otherwise
        # OEIS-Other: A023531 planepath=TriangleSpiral,n_start=-1
        # OEIS-Other: A023531 planepath=TriangleSpiral,n_start=-1 turn_type=LSR
        # OEIS-Other: A023532 planepath=TriangleSpiral,n_start=-1 turn_type=Straight
      },

      # PlanePathTurn planepath=TriangleSpiral,n_start=1,  turn_type=TTurn6
      # A089799 Expansion of Jacobi theta function theta_2(q^(1/2))/q^(1/8)
      # is this 2s with runs of 0s ?
    };
}
{ package Math::PlanePath::TriangleSpiralSkewed;
  use constant _NumSeq_Turn_Turn4_max => 1.5;

  use constant _NumSeq_Turn_oeis_anum =>
    {
     do {
       my $href = { Left     => 'A023531',  # 1 at k*(k+3)/2
                    LSR      => 'A023531',
                    Straight => 'A023532',  # 0 at k*(k+3)/2, 1 otherwise
                  };
       ('skew=left,n_start=-1' => $href,
        'skew=right,n_start=-1' => $href,
        'skew=up,n_start=-1' => $href,
        'skew=down,n_start=-1' => $href)
         # OEIS-Other: A023531 planepath=TriangleSpiralSkewed,n_start=-1
         # OEIS-Other: A023531 planepath=TriangleSpiralSkewed,n_start=-1 turn_type=LSR
         # OEIS-Other: A023532 planepath=TriangleSpiralSkewed,n_start=-1 turn_type=Straight
         # OEIS-Other: A023531 planepath=TriangleSpiralSkewed,n_start=-1,skew=right
         # OEIS-Other: A023531 planepath=TriangleSpiralSkewed,n_start=-1,skew=up
         # OEIS-Other: A023531 planepath=TriangleSpiralSkewed,n_start=-1,skew=down
     },
    };
}
{ package Math::PlanePath::DiamondSpiral;
  use constant _NumSeq_Turn_Turn4_max => 1.5;
}
{ package Math::PlanePath::AztecDiamondRings;
  use constant _NumSeq_Turn_Turn4_max => 1; # left or straight
}
{ package Math::PlanePath::PentSpiral;
  use constant _NumSeq_Turn_Turn4_max =>
    Math::NumSeq::PlanePathTurn::_turn_func_Turn4(2,0, -2,1);
}
{ package Math::PlanePath::PentSpiralSkewed;
  use constant _NumSeq_Turn_Turn4_max => 1.5;
}
{ package Math::PlanePath::HexSpiral;
  use constant _NumSeq_Turn_Turn4_max => 1.5;
}
{ package Math::PlanePath::HexSpiralSkewed;
  use constant _NumSeq_Turn_Turn4_max => 1.5;
}
{ package Math::PlanePath::HeptSpiralSkewed;
  use constant _NumSeq_Turn_Turn4_max => 1.5; # at N=2 turn +135
}
{ package Math::PlanePath::AnvilSpiral;
  use constant _NumSeq_Turn_Turn4_max => 3;
}
{ package Math::PlanePath::OctagramSpiral;
  use constant _NumSeq_Turn_Turn4_max => 3; # +90 right
}
{ package Math::PlanePath::KnightSpiral;
  # use constant _NumSeq_Turn_Turn4_min => ...; # 2,1
}
# { package Math::PlanePath::CretanLabyrinth;
# }
{ package Math::PlanePath::SquareArms;
  use constant _NumSeq_Turn_Turn4_max => 1;  # left or straight
}
{ package Math::PlanePath::DiamondArms;
  use constant _NumSeq_Turn_Turn4_max => 1; # left or straight
  use constant _NumSeq_Turn_Turn4_integer => 1;
}
{ package Math::PlanePath::HexArms;
  use constant _NumSeq_Turn_Turn4_max => 1; # at N=8
}
{ package Math::PlanePath::SacksSpiral;

  sub _NumSeq_Turn_Turn4_max {
    my ($self) = @_;
    # at N=1 is maximum turn
    return Math::NumSeq::PlanePathTurn::_turn_func_Turn4(1,0,
                                                         $self->n_to_dxdy(1));
  }
  use constant _NumSeq_Turn4_min_is_infimum => 1;

  use constant _NumSeq_Turn_oeis_anum =>
    { '' =>
      { 'Left' => 'A000012',  # left always, all ones
        'LSR'  => 'A000012',
        # OEIS-Other: A000012 planepath=SacksSpiral
        # OEIS-Other: A000012 planepath=SacksSpiral turn_type=LSR
      },
    };
}
# { package Math::PlanePath::VogelFloret;
# }
{ package Math::PlanePath::TheodorusSpiral;
  use constant _NumSeq_Turn4_min_is_infimum => 1; # approaches straight
  use constant _NumSeq_Turn_Turn4_max => 1; # initial 90deg

  use constant _NumSeq_Turn_oeis_anum =>
    { '' =>
      { 'Left' => 'A000012',  # left always, all ones
        'LSR'  => 'A000012',
        # OEIS-Other: A000012 planepath=TheodorusSpiral
        # OEIS-Other: A000012 planepath=TheodorusSpiral turn_type=LSR
      },
    };
}
{ package Math::PlanePath::ArchimedeanChords;
  sub _NumSeq_Turn_Turn4_max {
    my ($self) = @_;
    # at N=1 is maximum turn
    return Math::NumSeq::PlanePathTurn::_turn_func_Turn4(1,0,
                                                         $self->n_to_dxdy(1));
  }
  use constant _NumSeq_Turn4_min_is_infimum => 1; # approaches straight ahead

  use constant _NumSeq_Turn_oeis_anum =>
    { '' =>
      { 'Left' => 'A000012',  # left always, all ones
        'LSR'  => 'A000012',
        # OEIS-Other: A000012 planepath=ArchimedeanChords
        # OEIS-Other: A000012 planepath=ArchimedeanChords turn_type=LSR
      },
    };
}
{ package Math::PlanePath::MultipleRings;

  # step=1 and step=2 are mostly 1 for left, but after a while each ring
  # endpoint is to the right

  sub _NumSeq_Turn_Left_non_decreasing {
    my ($self) = @_;
    # step=0 always straight
    # step=1 straight,straight, then always left
    return ($self->{'step'} <= 1);
  }
  *_NumSeq_Turn_Right_non_decreasing = \&_NumSeq_Turn_Left_non_decreasing;
  *_NumSeq_Turn_LSR_non_decreasing = \&_NumSeq_Turn_Left_non_decreasing;
  *_NumSeq_Turn_SLR_non_decreasing = \&_NumSeq_Turn_Left_non_decreasing;
  *_NumSeq_Turn_SRL_non_decreasing = \&_NumSeq_Turn_Left_non_decreasing;

  sub _NumSeq_Turn_Turn4_max {
    my ($self) = @_;
    my $step = $self->{'step'};
    return ($step == 0
            ? 0  # step == 0 is always straight ahead
            : 4/$step);
  }

  use constant _NumSeq_Turn_oeis_anum =>
    {
     # MultipleRings step=0 is trivial X=N,Y=0
     'step=0,ring_shape=circle' =>
     { Left => 'A000004',  # all-zeros
       LSR  => 'A000004',  # all zeros, straight
       # OEIS-Other: A000004 planepath=MultipleRings,step=0
       # OEIS-Other: A000004 planepath=MultipleRings,step=0 turn_type=LSR
     },
     'step=0,ring_shape=polygon' =>
     { Left => 'A000004',  # all-zeros
       LSR  => 'A000004',  # all zeros, straight
       # OEIS-Other: A000004 planepath=MultipleRings,step=0,ring_shape=polygon
       # OEIS-Other: A000004 planepath=MultipleRings,step=0,ring_shape=polygon turn_type=LSR
     },
    };
}
{ package Math::PlanePath::PixelRings;
  # has right turns between rings
  use constant _NumSeq_Turn_Turn4_max => 3.5;
}
{ package Math::PlanePath::FilledRings;
  use constant _NumSeq_Turn_Turn4_max => 3.5;
}
{ package Math::PlanePath::Hypot;
  sub _NumSeq_Turn4_min_is_infimum {
    my ($self) = @_;
    return ($self->{'points'} eq 'all');
  }
  {
    my %_NumSeq_Turn_Turn4_max
      = (all  => 1.5, # at N=2, apparent maximum
         even => 1.5, # at N=2, apparent maximum
         odd  => Math::NumSeq::PlanePathTurn::_turn_func_Turn4(3,-3, 3,5),
        );
    sub _NumSeq_Turn_Turn4_max {
      my ($self) = @_;
      return ($_NumSeq_Turn_Turn4_max{$self->{'points'}} || 0);
    }
  }
}
{ package Math::PlanePath::HypotOctant;
  # apparently approaches +360 degrees
  use constant _NumSeq_Turn4_max_is_supremum => 1;
}
{ package Math::PlanePath::TriangularHypot;
  # points=even Turn4=0 at N=31
  #
  # points=all   apparently approaches 0
  # min i=473890[1303230202] 0.00000  px=-11,py=1 dx=-13,dy=1   -13.000
  #
  # points=odd    apparently approaches 0
  # min i=95618[113112002] 0.01111  px=-14,py=4 dx=-16,dy=4   -4.000
  #
  # points=hex   apparently approaches 0
  # min i=44243[22303103] 0.01111  px=-15,py=3 dx=-12,dy=2   -6.000
  #
  # points=hex_rotated Turn4=0 at N=58
  # points=hex_centred Turn4=0 at N=24
  {
    my %_NumSeq_Turn4_min_is_infimum = (all => 1,
                                        odd => 1,
                                        hex => 1,
                                       );
    sub _NumSeq_Turn4_min_is_infimum {
      my ($self) = @_;
      return ($_NumSeq_Turn4_min_is_infimum{$self->{'points'}} || 0);
    }
  }
  {
    my %_NumSeq_Turn_Turn4_max
      = (even => 1.5, # at N=2
         odd  => Math::NumSeq::PlanePathTurn::_turn_func_Turn4(5,3, 0,-6),
         all  => Math::NumSeq::PlanePathTurn::_turn_func_Turn4(5,3, 0,-6),
         hex  => Math::NumSeq::PlanePathTurn::_turn_func_Turn4(2,0, -3,1),
         hex_rotated => Math::NumSeq::PlanePathTurn::_turn_func_Turn4(1,1, -3,-1),
         hex_centred => Math::NumSeq::PlanePathTurn::_turn_func_Turn4(3,1, -2,2),
        );
    sub _NumSeq_Turn_Turn4_max {
      my ($self) = @_;
      return ($_NumSeq_Turn_Turn4_max{$self->{'points'}} || 0);
    }
  }
}
# { package Math::PlanePath::PythagoreanTree;
#   # A000004 all-zeros and A000012 all-ones are OFFSET=0 which doesn't match
#   # start N=1 here for always turn left or right in UAD.
# }
# { package Math::PlanePath::RationalsTree;
#   #   SB turn cf A021913 0,0,1,1
#   #              A133872 1,1,0,0
#   #              A057077 1,1,-1,-1
#   #              A087960 1,-1,-1,1
#   #   HCS turn left close to A010059 thue-morse or A092436
#   #            right A010060
#   #            LSR => 'A106400',  # thue-morse +/-1
#   #   CfracDigits radix=1 likewise
# }
# { package Math::PlanePath::FractionsTree;
# }
# { package Math::PlanePath::ChanTree;
#   # FIXME: k=4,5,6 are Right-only, maybe
#   # sub _NumSeq_Turn_Left_max {
#   #   my ($self) = @_;
#   #   return ($self->{'k'} >= 4
#   #           ? 0 # never Left
#   #           : 1);
#   # }
#   # sub _NumSeq_Turn_Right_min {
#   #   my ($self) = @_;
#   #   return ($self->{'k'} >= 4
#   #           ? 1 # always Right
#   #           : 0);
#   # }
#   # sub _NumSeq_Turn_LSR_max {
#   #   my ($self) = @_;
#   #   return ($self->{'k'} >= 4
#   #           ? -1 # always Right
#   #           : 1);
#   # }
# }
{ package Math::PlanePath::DiagonalRationals;
  sub _NumSeq_Turn_Turn4_max {
    my ($self) = @_;
    return ($self->{'direction'} eq 'down'
            ? 2.5   # N=2
            : Math::NumSeq::PlanePathTurn::_turn_func_Turn4(-1,1, 2,-1)); # N=3
  }
}
# { package Math::PlanePath::FactorRationals;
#   # revbinary
#   # max i=296[10220] 3.98889  px=-258,py=1 dx=-26,dy=1[-122,1]   -26.000
#   N=295=5*59   X=5*59 Y=1             N=297
#   N=296=2^3*37 X=37   Y=2     -26,+1     \ N=296 <-------- N=295
#   N=297=3^3*11 X=11   Y=3                         -258,+1
# }
{ package Math::PlanePath::GcdRationals;
  # Turn4 minimum
  # pairs_order=rows
  #   min=0 at N=12
  #   max i=216[3120] 3.98889  px=11,py=-14 dx=3,dy=-4[3,-10]   -0.750
  #
  # pairs_order=rows_reverse
  #   min i=13[31] 0.00000  px=-1,py=0 dx=-1,dy=0   0.000
  #   max i=611[21203] 3.98889  px=-1,py=2 dx=-13,dy=28[-31,130]   -0.464
  #
  # pairs_order=diagonals_down
  #   min i=2[2] 0.00000  px=0,py=1 dx=0,dy=1   0.000
  #   max i=561[20301] 3.98889  px=-7,py=8 dx=-5,dy=6[-11,12]   -0.833
  #
  # pairs_order=diagonals_up
  #   min i=11[23] 0.00000  px=-1,py=1 dx=-1,dy=1   -1.000
  #   max i=4886[1030112] 3.98889  px=6,py=-6 dx=15,dy=-16[33,-100]   -0.938
  #
  # Are these exact maximums or more when bigger N?
}
# { package Math::PlanePath::CfracDigits;
# }
{ package Math::PlanePath::AR2W2Curve;     # NSEW+diag
  use constant _NumSeq_Turn_Turn4_max => 3.5;
}
{ package Math::PlanePath::PeanoCurve;
  use constant _NumSeq_Turn_oeis_anum =>
    { 'radix=3' =>
      {
       # 2---0---0---0---0---2
       # |                   |
       # 2---0---1   1---0---2
       #         |   |
       # .---0---1   1---0---0-...
       SLR => 'A163536', # turn 0=ahead,1=left,2=right, OFFSET=1
       SRL => 'A163537',
       # OEIS-Catalogue: A163536 planepath=PeanoCurve turn_type=SLR
       # OEIS-Catalogue: A163537 planepath=PeanoCurve turn_type=SRL

       # Not quite, A039963 is OFFSET=0 vs first turn N=1 here
       # Straight => 'A039963',
      },
    };
}
# { package Math::PlanePath::WunderlichSerpentine;
# }
{ package Math::PlanePath::HilbertCurve;
  use constant _NumSeq_Turn_oeis_anum =>
    { '' =>
      { SLR => 'A163542', # relative direction ahead=0,left=1,right=2 OFFSET=1
        SRL => 'A163543', # relative direction transpose
        # OEIS-Catalogue: A163542 planepath=HilbertCurve turn_type=SLR
        # OEIS-Catalogue: A163543 planepath=HilbertCurve turn_type=SRL
      },
    };
}
{ package Math::PlanePath::HilbertSides;
  use constant _NumSeq_Turn_oeis_anum =>
    { '' =>
      { NotStraight => 'A035263',  # morphism
        # OEIS-Other: A035263 planepath=HilbertSides turn_type=NotStraight

        # Not quite, OFFSET=0 but first turn here N=1.
        # # OEIS-Other: A096268 planepath=HilbertSides turn_type=Straight
        # Straight => 'A096268',  # odd/even trailing 0 bits
      },
    };
}
{ package Math::PlanePath::ZOrderCurve;
  sub _NumSeq_Turn_Turn4_min {
    my ($self) = @_;
    return ($self->{'radix'} == 2
            ? 0.5
            : 0);  # includes straight
  }
  # radix   max at
  # -----   ------
  #   2       3             *---*      Y=radix-1
  #   3       8                  \
  #   4      15                   \
  #   5      24                    *   Y=0
  sub _NumSeq_Turn_Turn4_max {
    my ($self) = @_;
    return (Math::NumSeq::PlanePathTurn::_turn_func_Turn4
            (1,0, 1,1-$self->{'radix'}));
  }
}
{ package Math::PlanePath::GrayCode;
  # ENHANCE-ME: check this is true
  # PlanePathTurn planepath=GrayCode,apply_type=TsF,gray_type=reflected,radix=2,  turn_type=SLR
  # PlanePathTurn planepath=GrayCode,apply_type=Fs,gray_type=reflected,radix=2,  turn_type=SLR
  # match 1,1,0,0,1,1,1,1,1,1,0,0,1,1,0,0,1,1,0,0,1,1,1,1,1,1
  # A039963 The period-doubling sequence A035263 repeated.
  # A039963 ,1,1,0,0,1,1,1,1,1,1,0,0,1,1,0,0,1,1,0,0,1,1,1,1,1,1

  # Not quite, A039963 is OFFSET=0 vs first turn at N=1 here
  # 'Math::PlanePath::GrayCode' =>
  # {
  #  Left => 'A039963',  # duplicated KochCurve
  #  LSR  => 'A039963',
  # },
  # Koch characteristic of A003159 ending even zeros
  # 'Math::PlanePath::GrayCode' =>

  use constant _NumSeq_Turn_oeis_anum =>
    {
     do {
       my $peano = Math::PlanePath::PeanoCurve
         -> _NumSeq_Turn_oeis_anum -> {'radix=3'};
       ('apply_type=TsF,gray_type=reflected,radix=3' => $peano,
        'apply_type=FsT,gray_type=reflected,radix=3' => $peano,
       ),
         # OEIS-Other: A163536 planepath=GrayCode,apply_type=TsF,radix=3 turn_type=SLR
         # OEIS-Other: A163536 planepath=GrayCode,apply_type=FsT,radix=3 turn_type=SLR
         # OEIS-Other: A163537 planepath=GrayCode,apply_type=TsF,radix=3 turn_type=SRL
         # OEIS-Other: A163537 planepath=GrayCode,apply_type=FsT,radix=3 turn_type=SRL
     },
    };
}
# { package Math::PlanePath::ImaginaryBase;
# }
# { package Math::PlanePath::ImaginaryHalf;
# }
# { package Math::PlanePath::CubicBase;
# }
# { package Math::PlanePath::Flowsnake;
#   # inherit from FlowsnakeCentres
# }
{ package Math::PlanePath::FlowsnakeCentres;
  use constant _NumSeq_Turn_Turn4_max => 3.5;
}
# { package Math::PlanePath::GosperIslands;
# }
{ package Math::PlanePath::KochCurve;
  use constant _NumSeq_Turn_oeis_anum =>
    { '' =>
      { Left => 'A035263', # OFFSET=1 matches N=1
        # OEIS-Catalogue: A035263 planepath=KochCurve

        SLR => 'A056832',
        # OEIS-Catalogue: A056832 planepath=KochCurve turn_type=SLR
        # A056832 All a(n) = 1 or 2; a(1) = 1; get next 2^k terms by repeating first 2^k terms and changing last element so sum of first 2^(k+1) terms is odd.
        # A056832 ,1,2,1,1,1,2,1,2,1,2,1,1,1,2,1

        # Not quite, A096268 OFFSET=0 values 0,1,0,0,0,1
        # whereas here N=1 first turn values 0,1,0,0,0,1
        # Right => 'A096268',  # morphism
      },
    };
}
# { package Math::PlanePath::KochPeaks;
# }
# { package Math::PlanePath::KochSnowflakes;
# }
# { package Math::PlanePath::KochSquareflakes;
# }
# { package Math::PlanePath::QuadricCurve;
# }
# { package Math::PlanePath::QuadricIslands;
# }
{ package Math::PlanePath::SierpinskiTriangle;
  {
    my %_NumSeq_Turn_Turn4_max = (triangular => 2.5,
                                  left       => 2.5,
                                  right      => 3,
                                  diagonal   => 2.5,
                                 );
    sub _NumSeq_Turn_Turn4_max {
      my ($self) = @_;
      return $_NumSeq_Turn_Turn4_max{$self->{'align'}};
    }
  }
}
{ package Math::PlanePath::SierpinskiArrowhead;
  use constant _NumSeq_Turn_Turn4_min => 0.5; # North-East diagonal
  use constant _NumSeq_Turn_Turn4_max => 3.5; # South-East diagonal
}
{ package Math::PlanePath::SierpinskiArrowheadCentres;
  use constant _NumSeq_Turn_Turn4_max => 3.5; # South-East diagonal
}
# { package Math::PlanePath::SierpinskiCurve;
# #   use constant _NumSeq_Turn_oeis_anum =>
# #   { 'arms=1' =>
# #     {
# #      # Not quite, A039963 numbered OFFSET=0 whereas first turn at N=1 here
# #      Right => 'A039963',  # duplicated KochCurve turns
# #     },
# #   },
# # }
# }
{ package Math::PlanePath::SierpinskiCurveStair;
  use constant _NumSeq_Turn_Turn4_min => 1; # never straight
}
{ package Math::PlanePath::DragonCurve;
  use constant _NumSeq_Turn_Turn4_min => 1; # left or right only
  use constant _NumSeq_Turn_oeis_anum =>
    { 'arms=1' =>
      {
       'LSR' => 'A034947', # Jacobi symbol (-1/n)
       # OEIS-Catalogue: A034947 planepath=DragonCurve turn_type=LSR

       Turn4 => 'A099545',  # (odd part of n) mod 4
       # OEIS-Catalogue: A099545 planepath=DragonCurve turn_type=Turn4

       # 'L1R0' => 'A014577', # left=1,right=0  OFFSET=0
       # 'L0R1' => 'A014707', # left=0,right=1  OFFSET=0
       # 'L1R2' => 'A014709', # left=1,right=2  OFFSET=0
       # 'L1R3' => 'A099545', # left=1,right=3  OFFSET=1

       #  # Not quite, A014707 has OFFSET=0 cf first elem for N=1
       #  Left => 'A014707', # turn, 1=left,0=right
       #  # OEIS-Catalogue: A014707 planepath=DragonCurve

       #  # Not quite, A014577 has OFFSET=0 cf first elem for N=1
       #  Right => 'A014577', # turn, 0=left,1=right
       #  # OEIS-Catalogue: A014577 planepath=DragonCurve turn_type=Right

       # Not quite A014709 OFFSET=0 vs first turn at N=1 here
       # SLR => 'A014709'
       # SRL => 'A014710',
      },
    };
}
{ package Math::PlanePath::DragonRounded;
  use constant _NumSeq_Turn_Turn4_min => 0.5;
  use constant _NumSeq_Turn_Turn4_max => 3.5;
}
# { package Math::PlanePath::DragonMidpoint;
# }
{ package Math::PlanePath::AlternatePaper;
  use constant _NumSeq_Turn_Turn4_min => 1; # left or right only

  # A209615 is (-1)^e for each p^e prime=4k+3 or prime=2
  # 3*3 mod 4 = 1 mod 4
  # so picks out bit above lowest 1-bit, and factor -1 if an odd power-of-2
  # which is the AlternatePaper turn formula
  #
  use constant _NumSeq_Turn_oeis_anum =>
    { 'arms=1' =>
      { LSR => 'A209615',
        # OEIS-Catalogue: A209615 planepath=AlternatePaper turn_type=LSR
        Right => 'A292077',
        # OEIS-Catalogue: A292077 planepath=AlternatePaper turn_type=Right

        # # Not quite, A106665 has OFFSET=0 cf first here i=1
        # 'Left' => 'A106665', # turn, 1=left,0=right
        # # OEIS-Catalogue: A106665 planepath=AlternatePaper i_offset=1
      },
    };
}
{ package Math::PlanePath::GosperSide;

  # Suspect not in OEIS:
  # Left or Right according to lowest non-zero ternary digit 1 or 2
  #
  use constant _NumSeq_Turn_oeis_anum =>
    { '' =>
      { Left => 'A137893', # turn, 1=left,0=right, OFFSET=1
        SLR  => 'A060236', # base-3 lowest non-zero digit 1=left,2=right
        # OEIS-Catalogue: A137893 planepath=GosperSide
        # OEIS-Other:     A137893 planepath=TerdragonCurve
        # OEIS-Catalogue: A060236 planepath=GosperSide turn_type=SLR
        # OEIS-Other:     A060236 planepath=TerdragonCurve turn_type=SLR
        # A060236 would also be a "TTurn3"

        # cf A136442 - a(3n)=1, a(3n-1)=0, a(3n+1)=a(n)
        # ternary lowest non-1  0->1 2->0

        # Not quite, A080846 OFFSET=0 values 0,1,0,0,1 which are N=1 here
        # Right => 'A080846',
        # # OEIS-Catalogue: A080846 planepath=GosperSide turn_type=Right
        # # OEIS-Other:     A080846 planepath=TerdragonCurve turn_type=Right
        # Or A189640 has extra initial 0.
      },
    };
}
{ package Math::PlanePath::TerdragonCurve;
  # GosperSide and TerdragonCurve same turn sequence, by diff angles
  use constant _NumSeq_Turn_Turn4_min => 1;
  use constant _NumSeq_Turn_Turn4_max => 3;
  use constant _NumSeq_Turn_oeis_anum =>
    { 'arms=1' => Math::PlanePath::GosperSide->_NumSeq_Turn_oeis_anum->{''} };
}
{ package Math::PlanePath::TerdragonRounded;
  use constant _NumSeq_Turn_Turn4_min => 0.5;
  use constant _NumSeq_Turn_Turn4_max => 3.5;
}
{ package Math::PlanePath::TerdragonMidpoint;
  use constant _NumSeq_Turn_Turn4_max => 3;
}
{ package Math::PlanePath::AlternateTerdragon;
  use constant _NumSeq_Turn_Turn4_min => 1;
  use constant _NumSeq_Turn_Turn4_max => 3;
  # use constant _NumSeq_Turn_oeis_anum =>
  #   { 'arms=1' =>
  #     { 
  #       # Not quite, A156595 OFFSET=0, whereas here N=1 first turn
  #       # Right => 'A156595',
  #     },
  #   };
}
{ package Math::PlanePath::R5DragonCurve;
  use constant _NumSeq_Turn_Turn4_min => 1;  # right or left turn always
# # Not quite,    OFFSET=0 values 0,0,1,1,0
# # cf first turn here N=1 values 0,0,1,1,0
# # 'Math::PlanePath::R5DragonCurve' =>
# # { Right => 'A175337',
# #   # OEIS-Catalogue: A175337 planepath=R5DragonCurve turn_type=Right
# # },
}
# { package Math::PlanePath::R5DragonMidpoint;
# }
{ package Math::PlanePath::CCurve;
  # Not quite, A096268 OFFSET=1 vs first turn N=1 here
  # Straight => 'A096268'
}
# { package Math::PlanePath::ComplexPlus;
# }
# { package Math::PlanePath::ComplexMinus;
# }
# { package Math::PlanePath::ComplexRevolving;
# }
{ package Math::PlanePath::Rows;
  #  3---4  width=2
  #    \     N=2 turn4=1.5
  #  1---2   N=3 turn4=2.5
  sub _NumSeq_Turn_Turn4_min {
    my ($self) = @_;
    return ($self->{'width'} == 2
            ? 1.5  # at N=2
            : 0);  # otherwise has straight points
  }
  #   *--------
  #      \---\
  #   *---------*
  sub _NumSeq_Turn_Turn4_max {
    my ($self) = @_;
    return ($self->{'width'} <= 1
            ? 0  # width=1 always straight
            : (Math::NumSeq::PlanePathTurn::_turn_func_Turn4
               (1-$self->{'width'},1, 1,0)));  # at row start
  }

  use constant _NumSeq_Turn_oeis_anum =>
    {
     'n_start=1,width=0' => # Rows width=0 is trivial X=N,Y=0
     { Left => 'A000004',  # all-zeros
       LSR  => 'A000004',  # all zeros, straight
       # OEIS-Other: A000004 planepath=Rows,width=0
       # OEIS-Other: A000004 planepath=Rows,width=0 turn_type=LSR
     },

     # 4      N=1  turn=2
     #   \    N=2  turn=4
     # 2---3
     #   \
     # 0---1
     'n_start=-1,width=2' =>
     { TTurn6 => 'A010694', # repeat 2,4 with OFFSET=0
       # OEIS-Other: A010694 planepath=Rows,width=2,n_start=-1 turn_type=TTurn6
     },
    };
}
{ package Math::PlanePath::Columns;
  #  2   4  height=2
  #  | \ |   N=2 turn4=2.5
  #  1   3   N=3 turn4=1.5
  sub _NumSeq_Turn_Turn4_min {
    my ($self) = @_;
    return ($self->{'height'} == 2
            ? 1.5  # at N=3
            : 0);  # otherwise has straight points
  }
  #   *
  #   | \
  #   |  |
  #   *  *
  sub _NumSeq_Turn_Turn4_max {
    my ($self) = @_;
    return ($self->{'height'} <= 1
            ? 0   # height=1 always straight
            : (Math::NumSeq::PlanePathTurn::_turn_func_Turn4
               (0,1, 1,1-$self->{'height'})));  # at column top
  }

  use constant _NumSeq_Turn_oeis_anum =>
    {
     'n_start=1,height=0' => # Columns height=0 is trivial X=N,Y=0
     { Left => 'A000004',  # all-zeros
       LSR  => 'A000004',  # all zeros, straight
       # OEIS-Other: A000004 planepath=Columns,height=0
       # OEIS-Other: A000004 planepath=Columns,height=0 turn_type=LSR
     },

     # 'n_start=-1,height=4' =>
     # { Straight    => 'A133872', # repeat 1,1,0,0 OFFSET=0
     #   NotStraight => 'A021913', # repeat 0,0,1,1 OFFSET=0
     #   # OEIS-Other: A133872 planepath=Columns,n_start=-1,height=4 turn_type=Straight
     #   # OEIS-Other: A021913 planepath=Columns,n_start=-1,height=4 turn_type=NotStraight
     # },
    };
}
{ package Math::PlanePath::Diagonals;
  {
    my %_NumSeq_Turn_Turn4_max
      = (down => 2.5,
         # at N=3 dx=-1,dy=+1 then dx=2,dy=-1
         up   => Math::NumSeq::PlanePathTurn::_turn_func_Turn4(-1,1, 2,-1));
    sub _NumSeq_Turn_Turn4_max {
      my ($self) = @_;
      return $_NumSeq_Turn_Turn4_max{$self->{'direction'}};
    }
  }

  use constant _NumSeq_Turn_oeis_anum =>
    { 'direction=down,n_start=0,x_start=0,y_start=0' =>
      { Left => 'A129184', # shift of triangle
        SRL  => 'A156319', # triangle 1, 2, 0, 0, 0, ... in each row OFFSET=1
        # OEIS-Catalogue: A129184 planepath=Diagonals,n_start=0
        # OEIS-Catalogue: A156319 planepath=Diagonals,n_start=0 turn_type=SRL
      },
      'direction=down,n_start=-1,x_start=0,y_start=0' =>
      { Right => 'A023531', # 1 at m(m+3)/2
        # OEIS-Other: A023531 planepath=Diagonals,n_start=-1 turn_type=Right
      },

      'direction=up,n_start=0,x_start=0,y_start=0' =>
      { Right => 'A129184', # shift of triangle
        SLR   => 'A156319', # triangle 1, 2, 0, 0, 0, ... in each row OFFSET=1
        # OEIS-Other: A129184 planepath=Diagonals,direction=up,n_start=0 turn_type=Right
        # OEIS-Other: A156319 planepath=Diagonals,direction=up,n_start=0 turn_type=SLR
      },
      'direction=up,n_start=-1,x_start=0,y_start=0' =>
      { Left => 'A023531', # 1 at m(m+3)/2
        # OEIS-Other: A023531 planepath=Diagonals,direction=up,n_start=-1
      },
    };
}
{ package Math::PlanePath::DiagonalsAlternating;
  use constant _NumSeq_Turn_Turn4_max => 3.5;
}
{ package Math::PlanePath::DiagonalsOctant;
  sub _NumSeq_Turn_Turn4_max {
    my ($self) = @_;
    return ($self->{'direction'} eq 'down'
            ? 2.5  # N=3
            : 3);  # N=2
  }
#   # down is left or straight, but also right at N=2,3,4
#   # up is straight or right, but also left at N=2,3,4
#   'Math::PlanePath::DiagonalsOctant,direction=down' =>
#   { Left => square or pronic starting from 1
#   },
#   'Math::PlanePath::DiagonalsOctant,direction=up' =>
#   { Left => square or pronic starting from 1
#   },
}
{ package Math::PlanePath::Staircase;
  use constant _NumSeq_Turn_Turn4_min => 1;
  use constant _NumSeq_Turn_Turn4_max => 3;
}
# { package Math::PlanePath::StaircaseAlternating;
# }
{ package Math::PlanePath::MPeaks;
  use constant _NumSeq_Turn_Turn4_max => 3;
}
{ package Math::PlanePath::Corner;
  use constant _NumSeq_Turn_Turn4_max => 3;

  use constant _NumSeq_Turn_oeis_anum =>
    { 'wider=1,n_start=-1' =>
      { Left => 'A000007', # turn Left=1 at N=0 only
        # catalogued only unless/until a better implementation
        # OEIS-Catalogue: A000007 planepath=Corner,wider=1,n_start=-1
      },
      'wider=2,n_start=-1' =>
      { Left => 'A063524', # turn Left=1 at N=1 only
        # catalogued only unless/until a better implementation
        # OEIS-Catalogue: A063524 planepath=Corner,wider=2,n_start=-1
      },
      'wider=3,n_start=-1' =>
      { Left => 'A185012', # turn Left=1 at N=2 only
        # catalogued only unless/until a better implementation
        # OEIS-Catalogue: A185012 planepath=Corner,wider=3,n_start=-1
      },
      # A185013 Characteristic function of three.
      # A185014 Characteristic function of four.
      # A185015 Characteristic function of 5.
      # A185016 Characteristic function of 6.
      # A185017 Characteristic function of 7.
    };
}
{ package Math::PlanePath::PyramidRows;
  # if step==0 then always straight ahead

  # *--*         *---*
  # | step=1       \   step=3
  # *                *
  sub _NumSeq_Turn_Turn4_max {
    my ($self) = @_;
    return ($self->{'step'} == 0
            ? 0   # straight vertical only
            # at N=2
            : (Math::NumSeq::PlanePathTurn::_turn_func_Turn4
               (- $self->{'left_slope'},1, 1,0)));
  }

  use constant _NumSeq_Turn_oeis_anum =>
    {
     # PyramidRows step=0 is trivial X=N,Y=0
     do {
       my $href= { Left => 'A000004',  # all-zeros, OFFSET=0
                   LSR  => 'A000004',  # all zeros straight
                 };
       ('step=0,align=centre,n_start=1' => $href,
        'step=0,align=right,n_start=1'  => $href,
        'step=0,align=left,n_start=1'   => $href,
       );
       # OEIS-Other: A000004 planepath=PyramidRows,step=0
       # OEIS-Other: A000004 planepath=PyramidRows,step=0 turn_type=LSR
       # OEIS-Other: A000004 planepath=PyramidRows,step=0,align=right
       # OEIS-Other: A000004 planepath=PyramidRows,step=0,align=left turn_type=LSR
     },

     # PyramidRows step=1
     do {
       my $href= { Left => 'A129184', # triangle 1s shift right
                 };
       ('step=1,align=centre,n_start=0' => $href,
        'step=1,align=right,n_start=0'  => $href,
        'step=1,align=left,n_start=0'   => $href,
       );
       # OEIS-Other: A129184 planepath=PyramidRows,step=1,n_start=0
       # OEIS-Other: A129184 planepath=PyramidRows,step=1,align=right,n_start=0
       # OEIS-Other: A129184 planepath=PyramidRows,step=1,align=left,n_start=0
     },
     do {
       my $href= { Right => 'A023531',  # 1 at n==m*(m+3)/2
                 };
       ('step=1,align=centre,n_start=-1' => $href,
        'step=1,align=right,n_start=-1'  => $href,
       );
       # OEIS-Other: A023531 planepath=PyramidRows,step=1,n_start=-1 turn_type=Right
       # OEIS-Other: A023531 planepath=PyramidRows,step=1,align=right,n_start=-1 turn_type=Right
     },
    };
}
{ package Math::PlanePath::PyramidSides;
  use constant _NumSeq_Turn_Turn4_max => 3; # at N=3
}
{ package Math::PlanePath::CellularRule;
  sub _NumSeq_Turn_Left_increasing {
    my ($self) = @_;
    return (defined $self->{'rule'}
            && ($self->{'rule'} & 0x17) == 0    # single cell only
            ? 1
            : 0);
  }
  *_NumSeq_Turn_Right_increasing = \&_NumSeq_Turn_Left_increasing;

  sub _NumSeq_Turn_LSR_increasing {
    my ($self) = @_;
    return (defined $self->{'rule'}
            && ($self->{'rule'} & 0x17) == 0    # single cell only
            ? 1
            : 0);
  }
}
{ package Math::PlanePath::CellularRule::Line;
  use constant _NumSeq_Turn_Turn4_max => 0;
  use constant _NumSeq_Turn_Turn4_integer => 1;
}
{ package Math::PlanePath::CellularRule::OneTwo;

  # 5-6                                      5--6
  #  \                                       |
  #   4          left rule=6                 4   right rule=20
  #    ^----.    N=2 turn4=2.5              /    N=2 turn4=0.5
  #      2--3    N=3 turn4=3.5          2--3     N=3 turn4=3
  #       \      N=4 turn4=             |
  #         1                           1
  sub _NumSeq_Turn_Turn4_min {
    my ($self) = @_;
    return ($self->{'align'} eq 'left'
            ? Math::NumSeq::PlanePathTurn::_turn_func_Turn4(1,0, -2,1) # N=3
            : 0.5);
  }
  sub _NumSeq_Turn_Turn4_max {
    my ($self) = @_;
    return ($self->{'align'} eq 'left'
            ? Math::NumSeq::PlanePathTurn::_turn_func_Turn4(-2,1, -1,1) # N=4
            : 3);
  }

  use constant _NumSeq_Turn_oeis_anum =>
    { 'align=left,n_start=-1' =>
      { SRL => 'A131534', # repeat 1,2,1, 1,2,1, ... OFFSET=0
        # OEIS-Catalogue: A131534 planepath=CellularRule,rule=6,n_start=-1 turn_type=SRL
        # OEIS-Other:     A131534 planepath=CellularRule,rule=38,n_start=-1 turn_type=SRL
        # OEIS-Other:     A131534 planepath=CellularRule,rule=134,n_start=-1 turn_type=SRL
        # OEIS-Other:     A131534 planepath=CellularRule,rule=166,n_start=-1 turn_type=SRL
      },

      'align=right,n_start=-1' =>
      { SRL => 'A130196', # repeat 1,2,2, 1,2,2, ... OFFSET=0
        # OEIS-Catalogue: A130196 planepath=CellularRule,rule=20,n_start=-1 turn_type=SRL
        # OEIS-Other:     A130196 planepath=CellularRule,rule=52,n_start=-1 turn_type=SRL
        # OEIS-Other:     A130196 planepath=CellularRule,rule=148,n_start=-1 turn_type=SRL
        # OEIS-Other:     A130196 planepath=CellularRule,rule=180,n_start=-1 turn_type=SRL
      },
    };
}
{ package Math::PlanePath::CellularRule::Two;

  # 5--6                                      6--7
  #  ^---.                                    |
  #   4--5       left rule=6               4--5   right rule=84
  #    ^----.    N=2 turn4=2.5             |      N=2 turn4=1
  #      2--3    N=3 turn4=             2--3      N=3 turn4=3
  #       \                             |
  #         1                           1
  sub _NumSeq_Turn_Turn4_min {
    my ($self) = @_;
    return ($self->{'align'} eq 'left'
            ? Math::NumSeq::PlanePathTurn::_turn_func_Turn4(1,0, -2,1) # N=3
            : 1);
  }
  sub _NumSeq_Turn_Turn4_max {
    my ($self) = @_;
    return ($self->{'align'} eq 'left'
            ? 2.5
            : 3);
  }
  use constant _NumSeq_Turn_oeis_anum =>
    { 'align=right,n_start=-1' =>
      {
       # right line 2, stair step
       #       |
       #    3--1
       #    |
       # 3--1   Turn4 amounts
       # |
       # *
       Turn4 => 'A176040', # 3,1 repeating OFFSET=0
      },
      # OEIS-Catalogue: A176040 planepath=CellularRule,rule=84,n_start=-1 turn_type=Turn4
      # OEIS-Other:     A176040 planepath=CellularRule,rule=116,n_start=-1 turn_type=Turn4
      # OEIS-Other:     A176040 planepath=CellularRule,rule=212,n_start=-1 turn_type=Turn4
      # OEIS-Other:     A176040 planepath=CellularRule,rule=244,n_start=-1 turn_type=Turn4
    };
}
{ package Math::PlanePath::CellularRule::OddSolid;
  use constant _NumSeq_Turn_Turn4_max => 2.5; # at N=2

  # R 0 0 L  1 0 0 2
  #  R 0 L    1 0 2
  #   R L      1 2
  #    .        .

  use constant _NumSeq_Turn_oeis_anum =>
    { 'n_start=0' =>
      { SRL => 'A156319', # triangle rows 1,2,0,0,0,0,...
        # OEIS-Other: A156319 planepath=CellularRule,rule=50,n_start=0 turn_type=SRL
        # OEIS-Other: A156319 planepath=CellularRule,rule=58,n_start=0 turn_type=SRL
        # OEIS-Other: A156319 planepath=CellularRule,rule=250,n_start=0 turn_type=SRL
        # OEIS-Other: A156319 planepath=CellularRule,rule=179,n_start=0 turn_type=SRL
      },
    };
}
{ package Math::PlanePath::CellularRule54;
  use constant _NumSeq_Turn_Turn4_max => 2.5;
}
{ package Math::PlanePath::CellularRule57;
  sub _NumSeq_Turn_Turn4_max {
    my ($self) = @_;
    return ($self->{'mirror'}
            ? 3.5
            : Math::NumSeq::PlanePathTurn::_turn_func_Turn4(-2,1, 2,0)); # N=2
  }
}
{ package Math::PlanePath::CellularRule190;
  use constant _NumSeq_Turn_Turn4_max => 2.5;
}
# { package Math::PlanePath::CoprimeColumns;
# }
# { package Math::PlanePath::DivisibleColumns;
# }
# { package Math::PlanePath::File;
#   # File                   points from a disk file
#   # FIXME: analyze points for min/max etc
# }
{ package Math::PlanePath::QuintetCurve;
  use constant _NumSeq_Turn_Turn4_max => 3;
}
{ package Math::PlanePath::QuintetCentres;
  use constant _NumSeq_Turn_Turn4_max => 3.5;
}
# { package Math::PlanePath::QuintetSide;
  # PlanePathTurn planepath=QuintetSide,  turn_type=SLR
  # match 1,2,1,1,2,2,1,2,1,1,2,1,1,2,2,1,2,2,1,2,1,1,2,2,1,2
  # A060236 If n mod 3 = 0 then a(n)=a(n/3), otherwise a(n)=n mod 3.
  # A060236 ,1,2,1,1,2,2,1,2,1,1,2,1,1,2,2,1,2,2,1,2,1,1,2,2,1,2,1,1,2,1,1,2,2,1,2,1,1,2,1,1,2,2,1,2,2,1,2,1,1,2,2,1,2,2,1,2,1,1,2,2,1,2,1,1,2,1,1,2,2,1,2,2,1,2,1,1,2,2,1,2,1,1,2,1,1,2,2,1,2,1,1,2,1,1,2,2,1,2,2,1,2,1,1,2,2,
# }
# { package Math::PlanePath::DekkingCurve;
# }
# { package Math::PlanePath::DekkingCentres;
# }
# { package Math::PlanePath::CincoCurve;
# }
{ package Math::PlanePath::CornerReplicate;
  use constant _NumSeq_Turn_Turn4_min =>  # apparent minimum
    Math::NumSeq::PlanePathTurn::_turn_func_Turn4(-1,0, -2,-1);  # at N=11
  use constant _NumSeq_Turn_Turn4_max => 3; # apparent maximum
}
{ package Math::PlanePath::SquareReplicate;
  use constant _NumSeq_Turn_Turn4_max =>
    Math::NumSeq::PlanePathTurn::_turn_func_Turn4(2,1, 0,1);  # at N=9
}
{ package Math::PlanePath::DigitGroups;
  # radix=3 "11110222222"  len many 1s, 2*len-2 many 2s gives ever-increasing
  # radix=4 "1303333...3333" ever-increasing
}
{ package Math::PlanePath::FibonacciWordFractal;

  use constant _NumSeq_Turn_oeis_anum =>
    { '' =>
      { SRL => 'A156596', # turns 0=straight,1=right,2=left
        # OEIS-Catalogue: A156596 planepath=FibonacciWordFractal turn_type=SRL

        # Not quite, A003849 OFFSET=0 vs first turn N=1 here
        # Straight => 'A003849'
      },
    };
}
# { package Math::PlanePath::LTiling;
# }
{ package Math::PlanePath::WythoffArray;
  use constant _NumSeq_Turn_Turn4_max =>   # apparent maximum
    Math::NumSeq::PlanePathTurn::_turn_func_Turn4(-2,3, 5,-4);  # at N=12
}
{ package Math::PlanePath::WythoffPreliminaryTriangle;
  # apparent maximum, searched through to N=10_000_000
  # turn4 = 3.17777777777778
  use constant _NumSeq_Turn_Turn4_max =>
    Math::NumSeq::PlanePathTurn::_turn_func_Turn4(-54,-16, -8,13);  # at N=1344
}
{ package Math::PlanePath::PowerArray;

  # Turn4 ...
  #
  # radix=2
  #  min i=2[10] 1.50000  px=1,py=0 dx=-1,dy=1   -1.000
  # max i=3[11] 2.20000  px=-1,py=1 dx=2,dy=-1[10,-1]   -2.000
  #
  # radix=3
  #  min i=130[11211] 0.00000  px=-1,py=58 dx=0,dy=1   0.000
  # max i=67[2111] 3.98889  px=-1,py=30 dx=0,dy=1[0,1]   0.000
  #
  # radix=4
  #  min i=2[2] 0.00000  px=0,py=1 dx=0,dy=1   0.000
  # max i=53[311] 3.98889  px=-1,py=30 dx=0,dy=1[0,1]   0.000
  #
  # radix=5
  #  min i=2[2] 0.00000  px=0,py=1 dx=0,dy=1   0.000
  # max i=46[141] 3.98889  px=-1,py=29 dx=0,dy=1[0,1]   0.000
  #
  # radix=6
  #  min i=2[2] 0.00000  px=0,py=1 dx=0,dy=1   0.000
  # max i=43[111] 3.98889  px=-1,py=30 dx=0,dy=1[0,1]   0.000
  #
  # radix=7
  #  min i=2[2] 0.00000  px=0,py=1 dx=0,dy=1   0.000
  # max i=43[61] 3.98889  px=-1,py=31 dx=0,dy=1[0,1]   0.000
  #
  # radix=8
  #  min i=2[2] 0.00000  px=0,py=1 dx=0,dy=1   0.000
  # max i=41[51] 3.98889  px=-1,py=31 dx=0,dy=1[0,1]   0.000
  #
  # radix=9
  #  min i=2[2] 0.00000  px=0,py=1 dx=0,dy=1   0.000
  # max i=37[41] 3.98889  px=-1,py=29 dx=0,dy=1[0,1]   0.000
  #
  # radix=10
  #  min i=2[2] 0.00000  px=0,py=1 dx=0,dy=1   0.000
  # max i=41[41] 3.98889  px=-1,py=33 dx=0,dy=1[0,1]   0.000
  #
  # radix=16
  #  min i=2[2] 0.00000  px=0,py=1 dx=0,dy=1   0.000
  # max i=33[21] 3.98889  px=-1,py=29 dx=0,dy=1[0,1]   0.000
  #
  # radix=29
  #  min i=2[2] 0.00000  px=0,py=1 dx=0,dy=1   0.000
  # max i=59[21] 3.98889  px=-1,py=55 dx=0,dy=1[0,1]   0.000

  # use constant _NumSeq_oeis_anum =>
  #   # Not quite, A011765 0,0,0,1 repeating has OFFSET=1
  #   # cf n_start=1 is first turn at N=2
  #   # Left  => 'A011765',
  #   # Right => 'A011765',
  #
  #     # Not quite, A131534 has OFFSET=1 vs first turn at N=2 here
  #     # 'radix=3' =>
  #     # { SRL => 'A131534', # repeat 1,2,1, OFFSET=0
  #     # }
  #
  #     # Not quite, A007877 has OFFSET=1 vs first turn at N=2 here
  #     # 'radix=4' =>
  #     # { SRL => 'A007877', # repeat 0,1,2,1
  #     # }
  #
  #     # Not quite, 0,0,2,1,2 here vs A053796 0,2,1,2,0
  #     # 'radix=5' =>
  #     # { SRL => 'A053796', # repeat 0,2,1,2,0
  #     # }
  #   };
}
{ package Math::PlanePath::ToothpickTree;
  {
    my %_NumSeq_Turn_Turn4_max
      = (wedge => 3,  # at N=1 turn right
        );
    sub _NumSeq_Turn_Turn4_max {
      my ($self) = @_;
      return $_NumSeq_Turn_Turn4_max{$self->{'parts'}} || 4;
    }
  }
  {
    my %_NumSeq_Turn4_max_is_supremum
      = (wedge => 0,
        );
    sub _NumSeq_Turn4_max_is_supremum {
      my ($self) = @_;
      my $ret = $_NumSeq_Turn4_max_is_supremum{$self->{'parts'}};
      return (defined $ret ? $ret : 1);
    }
  }
}
{ package Math::PlanePath::ToothpickReplicate;
  {
    my %_NumSeq_Turn_Turn4_max
      = ( # at N=16
         '3' => Math::NumSeq::PlanePathTurn::_turn_func_Turn4(-1,3, 0,1),
        );
    sub _NumSeq_Turn_Turn4_max {
      my ($self) = @_;
      return $_NumSeq_Turn_Turn4_max{$self->{'parts'}} || 3.5;
    }
  }
}
{ package Math::PlanePath::ToothpickUpist;
  use constant _NumSeq_Turn_Turn4_max =>
    Math::NumSeq::PlanePathTurn::_turn_func_Turn4(-2,1, 2,0);  # at N=4
}
{ package Math::PlanePath::ToothpickSpiral;
  use constant _NumSeq_Turn_Turn4_min => 1; # left or right always
}
{ package Math::PlanePath::LCornerReplicate;
  # min i=63[333] 0.25556  px=1,py=0 dx=7,dy=3   2.333
  use constant _NumSeq_Turn_Turn4_min =>
    Math::NumSeq::PlanePathTurn::_turn_func_Turn4(1,0, 7,3);  # at N=63

  # higher N=1333..3333[base4] loop 3.8, 2.8, 1.7888, 0.7888
  # max i=8191[1333333] 3.80000  px=-1,py=0 dx=-38,dy=13[-212,31]   -2.923
  use constant _NumSeq_Turn_Turn4_max =>
    Math::NumSeq::PlanePathTurn::_turn_func_Turn4(-1,0, -38,13);  # at N=8191
}
{ package Math::PlanePath::LCornerTree;
  # parts=3 maybe maximum
  # max i=3107[300203] 3.98889  px=1,py=0 dx=66,dy=-1[1002,-1]   -66.000

  # LCornerTree,parts=diagonal-1 Turn4 values_max=4 vs saw_values_max=3 at i=27 (to i_end=801)

  {
    my %_NumSeq_Turn_Turn4_max
      = (wedge        => 3,  # at N=14
         'wedge+1'    => 3,  # at N=19
         diagonal     => 3,  # at N=21
         'diagonal-1' => 3,  # at N=27
        );
    sub _NumSeq_Turn_Turn4_max {
      my ($self) = @_;
      return $_NumSeq_Turn_Turn4_max{$self->{'parts'}} || 4;
    }
  }
  {
    my %_NumSeq_Turn4_max_is_supremum
      = (4 => 0,  # apparently
        );
    sub _NumSeq_Turn4_max_is_supremum {
      my ($self) = @_;
      return $_NumSeq_Turn4_max_is_supremum{$self->{'parts'}};
    }
  }
}

1;
__END__


=for stopwords Ryde Math-PlanePath NumSeq PlanePath SquareSpiral ie LSR dX,dY dx1,dy1 dx2,dy2 dx1 dx2 SRL dX

=head1 NAME

Math::NumSeq::PlanePathTurn -- turn sequence from PlanePath module

=head1 SYNOPSIS

 use Math::NumSeq::PlanePathTurn;
 my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'DragonCurve',
                                             turn_type => 'Left');
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is a tie-in to present turns from a C<Math::PlanePath> module in the
form of a NumSeq sequence.

The C<turn_type> choices are

    "Left"      1=left  0=right or straight
    "Right"     1=right 0=left or straight
    "Straight"  1=straight, 0=left or right
    "LSR"       1=left  0=straight -1=right
    "SLR"       0=straight 1=left  2=right
    "SRL"       0=straight 1=right 2=left

In each case the value at sequence index i is the turn at N=i,

            i+1
             ^
             |
             |
    i-1 ---> i     turn at i
                   first turn at i = n_start + 1

For multiple "arms" the turn follows that particular arm so it's i-arms, i,
i+arms.  i values start C<n_start()+arms_count()> so that i-arms is
C<n_start()>, the first N on the path.  A single arm path beginning N=0 has
its first turn at i=1.

For "Straight", "LSR", "SLR" and "SRL", straight means either straight ahead
or 180-degree reversal, ie. the direction N to N+1 is along the same line as
N-1 to N was.

"Left" means to the left side of the N-1 to N line, so not straight or
right.  Similarly "Right" means to the right side of the N-1 to N line, so
not straight or left.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::PlanePathTurn-E<gt>new (key=E<gt>value,...)>

Create and return a new sequence object.  The options are

    planepath          string, name of a PlanePath module
    planepath_object   PlanePath object
    turn_type          string, as described above

C<planepath> can be either the module part such as "SquareSpiral" or a
full class name "Math::PlanePath::SquareSpiral".

=item C<$value = $seq-E<gt>ith($i)>

Return the turn at N=$i in the PlanePath.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs as a turn.  Often this is merely the
possible turn values 1,0,-1, etc, but some spiral paths for example only go
left or straight in which case only 1 and 0 occur and C<pred()> reflects
that.

=item C<$i = $seq-E<gt>i_start()>

Return the first index C<$i> in the sequence.  This is the position
C<rewind()> returns to.

This is C<$path-E<gt>n_start() - $path-E<gt>arms_count()> from the
PlanePath object.

=back

=head1 FORMULAS

=head2 Turn Left or Right

A turn left or right is identified by considering the dX,dY at N-1 and at N.

    N+1      *
             |
             |
             |   dx2,dy2
             |
    N        *
            /
           /
          /  dx1,dy1
    N-1  *

With the two vectors dx1,dy1 and dx2,dy2 at a common origin, if the dx2,dy2
is above the dx1,dy1 line then it's a turn to the left, or below is a turn
to the right

    dx2,dy2
       *
       |   * dx1,dy1
       |  /
       | /
       |/
       o

At dx2 the Y value of the dx1,dy1 vector is

    cmpY = dx2 * dy1/dx1           if dx1 != 0

    left if dy2 > cmpY
            dy2 > dx2 * dy1/dx1
       so   dy2 * dx1 > dx2 * dy1

This cross-product comparison dy2*dx1 E<gt> dx2*dy1 works when dx1=0 too,
ie. when dx1,dy1 is vertical

    left if dy2 * 0 > dx2 * dy1
                  0 > dx2*dy1
    good, left if dx2 and dy1 opposite signs

So

    dy2*dx1 > dx2*dy1      left
    dy2*dx1 < dx2*dy1      right
    dy2*dx1 = dx2*dy1      straight, including 180 degree reverse

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::PlanePathCoord>,
L<Math::NumSeq::PlanePathDelta>,
L<Math::NumSeq::PlanePathN>

L<Math::NumberCruncher> has a C<Clockwise()> turn calculator

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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
