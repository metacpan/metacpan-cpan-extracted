# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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


# maybe:
#
# dTRadius, dTRSquared   of the radii
# dTheta360, maybe from Dir360

# matching Dir4,TDir6
# dStep dTStep dHypot
# StepDist StepSquared
# StepTDist StepTSquared
# StepRadius
# StepRSquared
# dLength
# dDist dDSquared
# dTDist dTDSquared
# Dist DSquared
# TDist TDSquared


package Math::NumSeq::PlanePathDelta;
use 5.004;
use strict;
use Carp 'croak';
use List::Util 'max';

use vars '$VERSION','@ISA';
$VERSION = 128;
use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');

use Math::NumSeq::PlanePathCoord;
*_planepath_name_to_object = \&Math::NumSeq::PlanePathCoord::_planepath_name_to_object;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant 1.02; # various underscore constants below
use constant characteristic_smaller => 1;

sub description {
  my ($self) = @_;
  if (ref $self) {
    return "Coordinate change $self->{'delta_type'} on path $self->{'planepath'}";
  } else {
    # class method
    return 'Coordinate changes from a PlanePath';
  }
}

use constant::defer parameter_info_array =>
  sub {
    [ Math::NumSeq::PlanePathCoord::_parameter_info_planepath(),
      {
       name    => 'delta_type',
       display => 'Delta Type',
       type    => 'enum',
       default => 'dX',
       choices => ['dX','dY',
                   'AbsdX','AbsdY',
                   'dSum','dSumAbs',
                   'dDiffXY','dDiffYX','dAbsDiff',
                   'dRadius','dRSquared',
                   # 'dTRadius','dTRSquared',
                   'Dir4','TDir6',

                   # 'Dist','DSquared',
                   # 'TDist','TDSquared',
                  ],
       description => 'Coordinate change or direction to take from the path.',
      },
    ];
  };

#------------------------------------------------------------------------------

sub oeis_anum {
  my ($self) = @_;
  ### PlanePathCoord oeis_anum() ...

  my $planepath_object = $self->{'planepath_object'};
  my $delta_type = $self->{'delta_type'};

  {
    my $key = Math::NumSeq::PlanePathCoord::_planepath_oeis_anum_key($self->{'planepath_object'});
    my $i_start = $self->i_start;
    if ($i_start != $self->default_i_start) {
      ### $i_start
      ### cf n_start: $planepath_object->n_start
      $key .= ",i_start=$i_start";
    }

    ### planepath: ref $planepath_object
    ### $key
    ### whole table: $planepath_object->_NumSeq_Delta_oeis_anum
    ### key href: $planepath_object->_NumSeq_Delta_oeis_anum->{$key}

    if (my $anum = $planepath_object->_NumSeq_Delta_oeis_anum->{$key}->{$delta_type}) {
      return $anum;
    }
  }
  return undef;
}

#------------------------------------------------------------------------------

sub new {
  ### NumSeq-PlanePathDelta new(): @_
  my $self = shift->SUPER::new(@_);

  $self->{'planepath_object'}
    ||= _planepath_name_to_object($self->{'planepath'});
  {
    my $delta_type = $self->{'delta_type'};
    ($self->{'delta_func'} = $self->can("_delta_func_$delta_type"))
      or ($self->{'n_func'} = $self->can("_n_func_$delta_type"))
        or croak "Unrecognised delta_type: ",$delta_type;
  }
  $self->rewind;
  return $self;
}

sub default_i_start {
  my ($self) = @_;
  my $planepath_object = $self->{'planepath_object'}
    # nasty hack allow no 'planepath_object' when SUPER::new() calls rewind()
    || return 0;
  return $planepath_object->n_start;
}
sub i_start {
  my ($self) = @_;
  my $planepath_object = $self->{'planepath_object'} || return 0;
  return $planepath_object->n_start;
}

# Old code keeping a previous X,Y to take a delta from.
#
# sub rewind {
#   my ($self) = @_;
#
#   my $planepath_object = $self->{'planepath_object'} || return;
#   $self->{'i'} = $self->i_start;
#   undef $self->{'x'};
#   $self->{'arms_count'} = $planepath_object->arms_count;
# }
# sub next {
#   my ($self) = @_;
#   ### NumSeq-PlanePathDelta next(): $self->{'i'}
#   ### n_next: $self->{'n_next'}
#
#   my $planepath_object = $self->{'planepath_object'};
#   my $i = $self->{'i'}++;
#   my $x = $self->{'x'};
#   my $y;
#   if (defined $x) {
#     $y = $self->{'y'};
#   } else {
#     ($x, $y) = $planepath_object->n_to_xy ($i)
#       or return;
#   }
#
#   my $arms = $self->{'arms_count'};
#   my ($next_x, $next_y) = $planepath_object->n_to_xy($i + $arms)
#     or return;
#   my $value = &{$self->{'delta_func'}}($x,$y, $next_x,$next_y);
#
#   if ($arms == 1) {
#     $self->{'x'} = $next_x;
#     $self->{'y'} = $next_y;
#   }
#   return ($i, $value);
# }

sub ith {
  my ($self, $i) = @_;
  ### NumSeq-PlanePathDelta ith(): $i

  my $planepath_object = $self->{'planepath_object'};
  if (my $func = $self->{'n_func'}) {
    return &$func($planepath_object,$i);
  }
  if (my ($dx, $dy) = $planepath_object->n_to_dxdy($i)) {
    return &{$self->{'delta_func'}}($dx,$dy);
  }
  return undef;
}

sub _delta_func_dX {
  my ($dx,$dy) = @_;
  return $dx;
}
sub _delta_func_dY {
  my ($dx,$dy) = @_;
  return $dy;
}
sub _delta_func_AbsdX {
  my ($dx,$dy) = @_;
  return abs($dx);
}
sub _delta_func_AbsdY {
  my ($dx,$dy) = @_;
  return abs($dy);
}
sub _delta_func_dSum {
  my ($dx,$dy) = @_;
  return $dx+$dy;
}
sub _delta_func_dDiffXY {
  my ($dx,$dy) = @_;
  return $dx-$dy;
}
sub _delta_func_dDiffYX {
  my ($dx,$dy) = @_;
  return $dy-$dx;
}

# (abs(x2)+abs(y2)) - (abs(x1)+abs(y1))
#   = abs(x2)-abs(x1) + abs(y2)-+abs(y1)
#   = dAbsX + dAbsY
sub _n_func_dSumAbs {
  my ($path, $n) = @_;
  ### _n_func_dSumAbs(): $n
  my ($x1,$y1) = $path->n_to_xy($n)
    or return undef;
  my ($x2,$y2) = $path->n_to_xy($n + $path->arms_count)
    or return undef;
  ### coords: "x1=$x1 y1=$y1    x2=$x2 y2=$y2"
  ### result: (abs($x2)+abs($y2)) - (abs($x1)+abs($y1))
  return (abs($x2)+abs($y2)) - (abs($x1)+abs($y1));
}
# abs(x2-y2) - abs(x1-y1)
sub _n_func_dAbsDiff {
  my ($path, $n) = @_;
  my ($x1,$y1) = $path->n_to_xy($n)
    or return undef;
  my ($x2,$y2) = $path->n_to_xy($n + $path->arms_count)
    or return undef;
  return abs($x2-$y2) - abs($x1-$y1);
}
sub _n_func_dRadius {
  my ($path, $n) = @_;
  if (defined (my $r1 = $path->n_to_radius($n))) {
    if (defined (my $r2 = $path->n_to_radius($n + $path->arms_count))) {
      return ($r2 - $r1);
    }
  }
  return undef;
}
*_n_func_dRSquared = \&_path_n_to_drsquared;
sub _path_n_to_drsquared {
  my ($path, $n) = @_;
  # dRSquared = (x2^2+y2^2) - (x1^2+y1^2)
  if (defined (my $r1 = $path->n_to_rsquared($n))) {
    if (defined (my $r2 = $path->n_to_rsquared($n + $path->arms_count))) {
      return ($r2 - $r1);
    }
  }
  return undef;
}
# Projection onto X,Y slope
#
#                 dX       e
#        +---------------------B
#        |             |    + /
#        |             | +   /   slope S = Y/X
#    dY  |            +|    /    dY/e = S
#        |         +   |   / H   e = dY/S
#        |      +      |  /      H = sqrt(dY^2 + dY^2/S^2)
#        |   +         | /       H = dY * sqrt(1 + 1/S^2)
#        | +     w     |/
#   X,Y  A__-----------C         p/h = S
#       /   --__      /          p = S*h
#      /     p  --__ /h          w = dX-e = dX-dY/S
#     /             &
#    /             /   
#   /             /
#
# h^2+p^2 = w^2
# h^2 + S^2*h^2 = (dX-dY/S)^2
# h^2 = (dX-dY/S)^2/(1+S^2)
# h = (dX-dY/S)/sqrt(1+S^2)
#
# H+h = dY * sqrt(1 + 1/S^2) + (dX-dY/S)/sqrt(1+S^2)
#     = dX/sqrt(1+S^2) 
#        + dY * (sqrt(1 + 1/S^2) - 1/S*1/sqrt(1+S^2))
# S*sqrt(1 + 1/S^2)/S - 1/S*1/sqrt(1+S^2))
# sqrt(S^2 + 1)/S - 1/S * 1/sqrt(1+S^2)
# (1+S^2)/S * 1/*sqrt(1+S^2) - 1/S * 1/sqrt(1+S^2)
# (1+S^2 - 1)/S * 1/sqrt(1+S^2)
# (S^2)/S * 1/sqrt(1+S^2)
# S/sqrt(1+S^2)
#
# dTRadius -> (dX + S*dY) / sqrt(1+S^2) 

*_n_func_dTRadius = \&_path_n_to_dtradius;
*_n_func_dTRSquared = \&_path_n_to_dtrsquared;

# dTRadius = sqrt(x2^2+3*y2^2) - sqrt(x1^2+3*y1^2)
sub _path_n_to_dtradius {
  my ($path, $n) = @_;
  if (defined (my $r1 = Math::NumSeq::PlanePathCoord::_path_n_to_tradius($path,$n))
      && defined (my $r2 = Math::NumSeq::PlanePathCoord::_path_n_to_tradius($path, $n + $path->arms_count))) {
    return ($r2 - $r1);
  }
  return undef;
}
# dTRSquared = (x2^2+3*y2^2) - (x1^2+3*y1^2)
sub _path_n_to_dtrsquared {
  my ($path, $n) = @_;
  if (defined (my $r1 = Math::NumSeq::PlanePathCoord::_path_n_to_trsquared($path,$n))
      && defined (my $r2 = Math::NumSeq::PlanePathCoord::_path_n_to_trsquared($path, $n + $path->arms_count))) {
    return ($r2 - $r1);
  }
  return undef;
}

sub _delta_func_Dist {
  return sqrt(_delta_func_DSquared(@_));
}
sub _delta_func_DSquared {
  my ($dx,$dy) = @_;
  return $dx*$dx + $dy*$dy;
}
sub _delta_func_TDist {
  return sqrt(_delta_func_TDSquared(@_));
}
sub _delta_func_TDSquared {
  my ($dx,$dy) = @_;
  return $dx*$dx + 3*$dy*$dy;
}

sub _delta_func_Dir4 {
  my ($dx,$dy) = @_;
  ### _delta_func_Dir4(): "$dx,$dy"
  ### 360 is: _delta_func_Dir360($dx,$dy)
  return _delta_func_Dir360($dx,$dy) / 90;
}
sub _delta_func_TDir6 {
  my ($dx,$dy) = @_;
  ### _delta_func_TDir6(): "$dx,$dy"
  return _delta_func_TDir360($dx,$dy) / 60;
}
sub _delta_func_Dir8 {
  my ($dx,$dy) = @_;
  return _delta_func_Dir360($dx,$dy) / 45;
}

use constant 1.02; # for leading underscore
use constant _PI => 2*atan2(1,0);

sub _delta_func_Dir360 {
  my ($dx,$dy) = @_;
  ### _delta_func_Dir360(): "$dx,$dy"

  if ($dy == 0) {
    ### dy=0 ...
    return ($dx >= 0 ? 0 : 180);
  }
  if ($dx == 0) {
    ### dx=0 ...
    return ($dy > 0 ? 90 : 270);
  }
  if ($dx > 0) {
    if ($dx == $dy) { return 45; }
    if ($dx == -$dy) { return 315; }
  } else {
    if ($dx == $dy) { return 225; }
    if ($dx == -$dy) { return 135; }
  }

  my $radians_to_degrees;

  # don't atan2() on BigInt, go to BigFloat
  foreach ($dx, $dy) {
    if (ref $_ && ($_->isa('Math::BigInt') || $_->isa('Math::BigRat'))) {
      require Math::BigFloat;
      $_ = Math::BigFloat->new($_);

      # 180/pi with pi done in BigFloat configured precision
      $radians_to_degrees ||= do {
        require Math::PlanePath::MultipleRings;
        180 / Math::PlanePath::MultipleRings::_pi($_);
      };
    }
  }
  $radians_to_degrees ||= 180 / _PI;
  ### $radians_to_degrees
  ### $dx
  ### $dy
  ### atan2: atan2($dy,$dx)

  # atan2() returns -PI <= a <= PI and perlfunc says atan2(0,0) is "not well
  # defined" (though glibc gives 0).  Add 360 to negatives to give 0<=dir<360.
  #
  my $degrees = atan2($dy,$dx) * $radians_to_degrees;
  ### $degrees
  return ($degrees < 0 ? $degrees + 360 : $degrees);
}

sub _delta_func_TDir360 {
  my ($dx,$dy) = @_;
  ### _delta_func_TDir360(): "$dx,$dy"

  if ($dy == 0) {
    return ($dx >= 0 ? 0 : 180);
  }
  if ($dx == 0) {
    return ($dy > 0 ? 90 : 270);
  }
  if ($dx > 0) {
    if ($dx == 3*$dy) { return 30; }
    if ($dx == $dy) { return 60; }
    if ($dx == -$dy) { return 300; }
    if ($dx == -3*$dy) { return 330; }
  } else {
    if ($dx == -$dy) { return 120; }
    if ($dx == -3*$dy) { return 150; }
    if ($dx == 3*$dy) { return 210; }
    if ($dx == $dy) { return 240; }
  }

  # Crib: atan2() returns -PI <= a <= PI, and is supposedly "not well
  # defined", though glibc gives 0
  #
  my $degrees = atan2($dy*sqrt(3), $dx) * (180 / _PI);
  return ($degrees < 0 ? $degrees + 360 : $degrees);
}

#------------------------------------------------------------------------------

sub characteristic_integer {
  my ($self) = @_;
  my $method = "_NumSeq_Delta_$self->{'delta_type'}_integer";
  return $self->{'planepath_object'}->$method();
}

sub characteristic_increasing {
  my ($self) = @_;
  ### PlanePathDelta characteristic_increasing() ...
  my $planepath_object = $self->{'planepath_object'};
  my $func;
  return
    (($func = ($planepath_object->can("_NumSeq_Delta_$self->{'delta_type'}_increasing")
               || ($self->{'delta_type'} eq 'DSquared'
                   && $planepath_object->can("_NumSeq_Delta_Dist_increasing"))
               || ($self->{'delta_type'} eq 'TDSquared'
                   && $planepath_object->can("_NumSeq_Delta_TDist_increasing"))))
     ? $planepath_object->$func()
     : undef); # unknown
}

sub characteristic_non_decreasing {
  my ($self) = @_;
  ### PlanePathDelta characteristic_non_decreasing() ...
  if (defined (my $values_min = $self->values_min)) {
    if (defined (my $values_max = $self->values_max)) {
      if ($values_min == $values_max) {
        # constant seq is non-decreasing
        return 1;
      }
    }
  }
  my $planepath_object = $self->{'planepath_object'};
  my $func;
  return
    (($func = ($planepath_object->can("_NumSeq_Delta_$self->{'delta_type'}_non_decreasing")
               || ($self->{'delta_type'} eq 'DSquared'
                   && $planepath_object->can("_NumSeq_Delta_Dist_non_decreasing"))
               || ($self->{'delta_type'} eq 'TDSquared'
                   && $planepath_object->can("_NumSeq_Delta_TDist_non_decreasing"))))
     ? $planepath_object->$func()
     : $self->characteristic_increasing); # increasing means non_decreasing too
}

sub _dir360_to_tdir6 {
  my ($a) = @_;
  if ($a % 90 == 0) {
    # 0,90,180,270 -> 0, 1.5, 3, 4.5
    return $a / 60;
  }
  if ($a % 45 == 0) {
    # 45, 135, 225, 315 -> 1, 2, 4, 5
    return ($a+45)/90 + ($a < 180 ? 0 : 1);
  }
  if ($a == 30)  { return 0.75; }
  if ($a == 150) { return 2.25; }
  if ($a == 210) { return 3.75; }
  if ($a == 330) { return 5.25; }

  $a *= _PI/180; # degrees to radians
  my $tdir6 = atan2(sin($a)*sqrt(3), cos($a))
    * (3/_PI);  # radians to 6
  return ($tdir6 < 0 ? $tdir6 + 6 : $tdir6);
}

sub _dxdy_to_dir4 {
  my ($dx,$dy) = @_;
  ### _dxdy_to_dir4(): "$dx,$dy"

  if ($dy == 0) {
    ### dy=0 ...
    return ($dx == 0 ? 4 : $dx > 0 ? 0 : 2);
  }
  if ($dx == 0) {
    ### dx=0 ...
    return ($dy > 0 ? 1 : 3);
  }
  if ($dx > 0) {
    if ($dx == $dy) { return 0.5; }
    if ($dx == -$dy) { return 3.5; }
  } else {
    if ($dx == $dy) { return 2.5; }
    if ($dx == -$dy) { return 1.5; }
  }

  # don't atan2() in bigints
  if (ref $dx && $dx->isa('Math::BigInt')) {
    $dx = $dx->numify;
  }
  if (ref $dy && $dy->isa('Math::BigInt')) {
    $dy = $dy->numify;
  }

  # Crib: atan2() returns -PI <= a <= PI, and perlfunc says atan2(0,0) is
  # "not well defined", though glibc gives 0
  #
  ### atan2: atan2($dy,$dx)
  my $dir4 = atan2($dy,$dx) * (2 / _PI);
  ### $dir4
  return ($dir4 < 0 ? $dir4 + 4 : $dir4);
}

{
  my %values_min = (dX      => 'dx_minimum',
                    dY      => 'dy_minimum',
                    AbsdX   => 'absdx_minimum',
                    AbsdY   => 'absdy_minimum',
                    dSum    => 'dsumxy_minimum',
                    dDiffXY => 'ddiffxy_minimum',
                   );
  sub values_min {
    my ($self) = @_;
    my $planepath_object = $self->{'planepath_object'};
    if (my $method = ($values_min{$self->{'delta_type'}}
                      || $planepath_object->can("_NumSeq_Delta_$self->{'delta_type'}_min"))) {
      return $planepath_object->$method();
    }
    return undef;
  }
}
{
  my %values_max = (dX      => 'dx_maximum',
                    dY      => 'dy_maximum',
                    AbsdX   => 'absdx_maximum',
                    AbsdY   => 'absdy_maximum',
                    dSum    => 'dsumxy_maximum',
                    dDiffXY => 'ddiffxy_maximum',
                   );
  sub values_max {
    my ($self) = @_;
    my $planepath_object = $self->{'planepath_object'};
    if (my $method = ($values_max{$self->{'delta_type'}}
                      || $planepath_object->can("_NumSeq_Delta_$self->{'delta_type'}_max"))) {
      return $planepath_object->$method();
    }
    return undef;
  }
}

{ package Math::PlanePath;
  use constant _NumSeq_Delta_oeis_anum => {};

  #------------
  # dX,dY
  use constant _NumSeq_Delta_dX_integer => 1;  # usually
  use constant _NumSeq_Delta_dY_integer => 1;

  #------------
  # AbsdX,AbsdY
  sub _NumSeq_Delta_AbsdX_integer { $_[0]->_NumSeq_Delta_dX_integer }
  sub _NumSeq_Delta_AbsdY_integer { $_[0]->_NumSeq_Delta_dY_integer }

  #------------
  # dSum
  sub _NumSeq_Delta_dSum_integer {
    my ($self) = @_;
    return ($self->_NumSeq_Delta_dX_integer
            && $self->_NumSeq_Delta_dY_integer);
  }

  #------------
  # dSumAbs
  sub _NumSeq_Delta_dSumAbs_min {
    my ($self) = @_;
    if (! $self->x_negative && ! $self->y_negative) {
      return $self->dsumxy_minimum;
    }
    return undef;
  }
  sub _NumSeq_Delta_dSumAbs_max {
    my ($self) = @_;
    if (! $self->x_negative && ! $self->y_negative) {
      return $self->dsumxy_maximum;
    }
    return undef;
  }
  *_NumSeq_Delta_dSumAbs_integer = \&_NumSeq_Delta_dSum_integer;

  #------------
  # dDiffXY
  *_NumSeq_Delta_dDiffXY_integer = \&_NumSeq_Delta_dSum_integer;

  #------------
  # dDiffYX

  sub _NumSeq_Delta_dDiffYX_min {
    my ($self) = @_;
    if (defined (my $m = $self->ddiffxy_maximum)) {
      return -$m;
    }
    return undef;
  }
  sub _NumSeq_Delta_dDiffYX_max {
    my ($self) = @_;
    if (defined (my $m = $self->ddiffxy_minimum)) {
      return -$m;
    }
    return undef;
  }

  sub _NumSeq_Delta_dDiffYX_integer {
    return $_[0]->_NumSeq_Delta_dDiffXY_integer;
  }

  #------------
  # dAbsDiff
  *_NumSeq_Delta_dAbsDiff_integer = \&_NumSeq_Delta_dDiffYX_integer;

  #------------
  # dRadius, dRSquared

  use constant _NumSeq_Delta_dRadius_min => undef;
  use constant _NumSeq_Delta_dRadius_max => undef;
  use constant _NumSeq_Delta_dRadius_integer => 0;

  use constant _NumSeq_Delta_dRSquared_min => undef;
  use constant _NumSeq_Delta_dRSquared_max => undef;
  *_NumSeq_Delta_dRSquared_integer = \&_NumSeq_Delta_dDiffYX_integer;

  #------------
  # dTRadius, dTRSquared

  use constant _NumSeq_Delta_dTRadius_min => undef;
  use constant _NumSeq_Delta_dTRadius_max => undef;
  use constant _NumSeq_Delta_dTRadius_integer => 0;

  use constant _NumSeq_Delta_dTRSquared_min => undef;
  use constant _NumSeq_Delta_dTRSquared_max => undef;
  *_NumSeq_Delta_dTRSquared_integer = \&_NumSeq_Delta_dDiffYX_integer;

  #------------
  # Dir4
  sub _NumSeq_Delta_Dir4_min {
    my ($self) = @_;
    return Math::NumSeq::PlanePathDelta::_dxdy_to_dir4
      ($self->dir_minimum_dxdy);
  }
  sub _NumSeq_Delta_Dir4_max {
    my ($self) = @_;
    return Math::NumSeq::PlanePathDelta::_dxdy_to_dir4
      ($self->dir_maximum_dxdy);
  }
  sub _NumSeq_Dir4_max_is_supremum {
    my ($self) = @_;
    return ($self->_NumSeq_Delta_Dir4_max == 4);
  }
  use constant _NumSeq_Dir4_min_is_infimum => 0;
  sub _NumSeq_Delta_Dir4_integer {
    my ($self) = @_;
    {
      my @_UNDOCUMENTED__dxdy_list = $self->_UNDOCUMENTED__dxdy_list;
      for (my $i = 0; $i < $#_UNDOCUMENTED__dxdy_list; $i+=2) {
        unless (_dxdy_is_dir4($_UNDOCUMENTED__dxdy_list[$i], $_UNDOCUMENTED__dxdy_list[$i+1])) {
          return 0;
        }
      }
    }
    my ($dx,$dy) = $self->dir_minimum_dxdy;
    if ($dx && $dy) { return 0; } # diagonal

    ($dx,$dy) = $self->dir_maximum_dxdy;
    return ! (($dx && $dy)  # diagonal
              || ($dx==0 && $dy==0)); # supremum
  }

  #------------
  # TDir6
  sub _NumSeq_Delta_TDir6_min {
    my ($self) = @_;
    return Math::NumSeq::PlanePathDelta::_dir360_to_tdir6
      ($self->_NumSeq_Delta_Dir4_min * 90);
  }
  sub _NumSeq_Delta_TDir6_max {
    my ($self) = @_;
    return Math::NumSeq::PlanePathDelta::_dir360_to_tdir6
      ($self->_NumSeq_Delta_Dir4_max * 90);
  }
  sub _NumSeq_TDir6_max_is_supremum {
    return $_[0]->_NumSeq_Dir4_max_is_supremum;
  }
  sub _NumSeq_TDir6_min_is_infimum {
    return $_[0]->_NumSeq_Dir4_min_is_infimum;
  }
  sub _NumSeq_Delta_TDir6_integer {
    my ($self) = @_;
    {
      my @_UNDOCUMENTED__dxdy_list = $self->_UNDOCUMENTED__dxdy_list;
      for (my $i = 0; $i < @_UNDOCUMENTED__dxdy_list; $i+=2) {
        unless (_dxdy_is_tdir6($_UNDOCUMENTED__dxdy_list[$i], $_UNDOCUMENTED__dxdy_list[$i+1])) {
          return 0;
        }
      }
    }
    my ($dx,$dy) = $self->dir_minimum_dxdy;
    if ($dy != 0 && abs($dx) != abs($dy)) { return 0; } # not diagonal or horiz

    ($dx,$dy) = $self->dir_maximum_dxdy;
    return ! (($dy != 0 && abs($dx) != abs($dy))  # not diagonal or horiz
              || ($dx==0 && $dy==0)); # supremum
  }
  sub _dxdy_is_dir4 {
    my ($dx,$dy) = @_;
    return ($dx == 0 || $dy == 0);
  }
  sub _dxdy_is_tdir6 {
    my ($dx,$dy) = @_;
    return ($dy == 0 || abs($dx)==abs($dy));
  }

  #------------
  sub _NumSeq_Delta_Dist_min {
    my ($self) = @_;
    sqrt($self->_NumSeq_Delta_DSquared_min);
  }
  sub _NumSeq_Delta_Dist_max {
    my ($self) = @_;
    my $max;
    return (defined ($max = $self->_NumSeq_Delta_DSquared_max)
            ? sqrt($max)
            : undef);
  }

  sub _NumSeq_Delta_TDist_min {
    my ($self) = @_;
    sqrt($self->_NumSeq_Delta_TDSquared_min);
  }
  sub _NumSeq_Delta_TDist_max {
    my ($self) = @_;
    my $max;
    return (defined ($max = $self->_NumSeq_Delta_TDSquared_max)
            ? sqrt($max)
            : undef);
  }

  # Default Dist min from AbsdX,AbsdY min.
  # Subclass must overridde if those minimums don't occur together.
  sub _NumSeq_Delta_DSquared_min {
    my ($self) = @_;
    my $dx = $self->absdx_minimum;
    my $dy = $self->absdy_minimum;
    return _max (1, $dx*$dx + $dy*$dy);
  }
  sub _NumSeq_Delta_TDSquared_min {
    my ($self) = @_;
    my $dx = $self->absdx_minimum;
    my $dy = $self->absdy_minimum;
    return _max (1, $dx*$dx + 3*$dy*$dy);
  }

  # Default Dist max from AbsdX,AbsdY max, if maximums exist.
  # Subclass must overridde if those maximums don't occur together.
  sub _NumSeq_Delta_DSquared_max {
    my ($self) = @_;
    if (defined (my $dx = $self->absdx_maximum)
        && defined (my $dy = $self->absdy_maximum)) {
      return ($dx*$dx + $dy*$dy);
    } else {
      return undef;
    }
  }
  sub _NumSeq_Delta_TDSquared_max {
    my ($self) = @_;
    if (defined (my $dx = $self->absdx_maximum)
        && defined (my $dy = $self->absdy_maximum)) {
      return ($dx*$dx + 3*$dy*$dy);
    } else {
      return undef;
    }
  }

  *_NumSeq_Delta_DSquared_integer = \&_NumSeq_Delta_dSum_integer;
  *_NumSeq_Delta_TDSquared_integer = \&_NumSeq_Delta_dSum_integer;

  use constant _NumSeq_Delta_Dir360_min => 0;
  use constant _NumSeq_Delta_Dir360_max => 360;
}


{ package Math::PlanePath::SquareSpiral;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  # at X=-k,Y=k    TRad = sqrt((-k)^2 + 3*k^2)
  #                     = 2k
  # to X=-k,Y=k-1  TRad = sqrt((-k)^2 + 3*(k-1)^2)
  #                     = sqrt(4*k^2 - 6k + 3)
  # dTRad = sqrt(4*k^2 - 6k + 3) - 2k
  #      -> 1.5
  #
  #          -k, k*sqrt(3)    *         arc approaches straight line
  #                           |\        hypot = sqrt(3)
  #                           | \       angle=30,30,120 stretched from 45deg
  #                           | /\      tan 30 = x / (sqrt(3)/2)
  #                           |/  \     sqrt(3)*sqrt(3)/2 = x
  #        -k, (k-1)*sqrt(3)  *    .    x = 3/2
  #                            \   .
  #                             .. .
  #                                O
  #
  use constant _NumSeq_Delta_dTRadius_min => -3/2;
  use constant _NumSeq_Delta_dTRadius_max => 3/2;
  use constant _NumSeq_dTRadius_min_is_infimum => 1;
  use constant _NumSeq_dTRadius_max_is_supremum => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;

  use constant _NumSeq_Delta_oeis_anum =>
    { 'wider=0,n_start=1' =>
      { AbsdY   => 'A079813',   # k 0s then k 1s plus initial 1 is abs(dY)
        # OEIS-Catalogue: A079813 planepath=SquareSpiral delta_type=AbsdY
      },
    };
}
{ package Math::PlanePath::GreekKeySpiral;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  sub _NumSeq_Delta_dTRadius_min {
    my ($self) = @_;
    return ($self->{'turns'} == 0 ? -1.5  # per SquareSpiral
            : - sqrt(3));
  }
  use constant _NumSeq_Delta_dTRadius_max => sqrt(3);
  use constant _NumSeq_dTRadius_min_is_infimum => 1;
  use constant _NumSeq_dTRadius_max_is_supremum => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;
}
{ package Math::PlanePath::PyramidSpiral;
  use constant _NumSeq_Delta_AbsdX_non_decreasing => 1; # constant absdx=1
  use constant _NumSeq_Delta_dSumAbs_min => -2; # near diagonal, eg. N=10
  use constant _NumSeq_Delta_dSumAbs_max => 2;  # near diagonal, eg. N=4
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  # use constant _NumSeq_Delta_dRadius_min => -sqrt(2);
  # use constant _NumSeq_Delta_dRadius_max => sqrt(2);

  use constant _NumSeq_Delta_TDir6_integer => 1;
  use constant _NumSeq_Delta_DSquared_max => 2;
}
{ package Math::PlanePath::TriangleSpiral;
  use constant _NumSeq_Delta_dSumAbs_min => -2;
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  use constant _NumSeq_Delta_TDir6_integer => 1;

  use constant _NumSeq_Delta_DSquared_min => 2;
  use constant _NumSeq_Delta_DSquared_max => 4;
  use constant _NumSeq_Delta_TDSquared_min => 4;  # triangular
  use constant _NumSeq_Delta_TDSquared_max => 4;  # triangular
  use constant _NumSeq_Delta_TDist_non_decreasing => 1;  # triangular
}
{ package Math::PlanePath::TriangleSpiralSkewed;
  use constant _NumSeq_Delta_dSumAbs_min => -2;
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  {
    my %_NumSeq_Delta_dAbsDiff_min = (left  => -2,  # North-West
                                      right => -1,  # N
                                      up    => -1,  # W
                                      down  => -2); # North-West
    sub _NumSeq_Delta_dAbsDiff_min {
      my ($self) = @_;
      return $_NumSeq_Delta_dAbsDiff_min{$self->{'skew'}};
    }
  }
  {
    my %_NumSeq_Delta_dAbsDiff_max = (left  => 2,  # South-East
                                      right => 1,  # S
                                      up    => 1,  # S
                                      down  => 2); # South-East
    sub _NumSeq_Delta_dAbsDiff_max {
      my ($self) = @_;
      return $_NumSeq_Delta_dAbsDiff_max{$self->{'skew'}};
    }
  }

  use constant _NumSeq_Delta_DSquared_max => 2;

  # A204435 f(i,j)=((i+j  )^2 mod 3), antidiagonals
  # A204437 f(i,j)=((i+j+1)^2 mod 3), antidiagonals
  # A204439 f(i,j)=((i+j+2)^2 mod 3), antidiagonals
  # gives 0s at every third antidiagonal
  use constant _NumSeq_Delta_oeis_anum =>
    { 'skew=left,n_start=1' =>
      { AbsdX => 'A204439',
        AbsdY => 'A204437',
        # OEIS-Catalogue: A204439 planepath=TriangleSpiralSkewed,skew=left delta_type=AbsdX
        # OEIS-Catalogue: A204437 planepath=TriangleSpiralSkewed,skew=left delta_type=AbsdY
      },
      'skew=right,n_start=1' =>
      { AbsdX => 'A204435',
        AbsdY => 'A204437',
        # OEIS-Catalogue: A204435 planepath=TriangleSpiralSkewed,skew=right delta_type=AbsdX
        # OEIS-Other:     A204437 planepath=TriangleSpiralSkewed,skew=right delta_type=AbsdY
      },
      'skew=up,n_start=1' =>
      { AbsdX => 'A204439',
        AbsdY => 'A204435',
        # OEIS-Other: A204439 planepath=TriangleSpiralSkewed,skew=up delta_type=AbsdX
        # OEIS-Other: A204435 planepath=TriangleSpiralSkewed,skew=up delta_type=AbsdY
      },
      'skew=down,n_start=1' =>
      { AbsdX => 'A204435',
        AbsdY => 'A204439',
        # OEIS-Other: A204435 planepath=TriangleSpiralSkewed,skew=down delta_type=AbsdX
        # OEIS-Other: A204439 planepath=TriangleSpiralSkewed,skew=down delta_type=AbsdY
      },
    };
}
{ package Math::PlanePath::DiamondSpiral;
  use constant _NumSeq_Delta_AbsdX_non_decreasing => 1; # constant absdx=1
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;
  use constant _NumSeq_Delta_DSquared_max => 2;
  use constant _NumSeq_Delta_TDir6_integer => 1;

  use constant _NumSeq_Delta_oeis_anum =>
    { 'n_start=1' =>
      { AbsdX => 'A000012', # all 1s, starting OFFSET=1
        # OEIS-Other: A000012 planepath=DiamondSpiral delta_type=AbsdX
      },
      'n_start=0' =>
      { dSumAbs => 'A003982',  # characteristic of A001844 Y_neg axis
        # catalogue here in absence of anything else in NumSeq
        # OEIS-Catalogue: A003982 planepath=DiamondSpiral,n_start=0 delta_type=dSumAbs
      },
    };
}
{ package Math::PlanePath::AztecDiamondRings;
  use constant _NumSeq_Delta_dSumAbs_min => -1; # change of diamond
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  use constant _NumSeq_Delta_dRadius_min => -1;
  use constant _NumSeq_Delta_dRadius_max => 1;
  use constant _NumSeq_dRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_dTRadius_min => - sqrt(3);
  use constant _NumSeq_Delta_dTRadius_max => sqrt(3);
  use constant _NumSeq_dTRadius_min_is_infimum => 1;
  use constant _NumSeq_dTRadius_max_is_supremum => 1;

  use constant _NumSeq_Delta_oeis_anum =>
    { 'n_start=0' =>
      { AbsdY => 'A023532', # 0 at n=k*(k+3)/2, 1 otherwise
        # OEIS-Catalogue: A023532 planepath=AztecDiamondRings,n_start=0 delta_type=AbsdY
      },
    };
}
{ package Math::PlanePath::PentSpiral;
  use constant _NumSeq_Delta_dSumAbs_min => -2;
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  use constant _NumSeq_Delta_dAbsDiff_min => -3;
  use constant _NumSeq_Delta_dAbsDiff_max => 3;

  use constant _NumSeq_Delta_dRadius_min => -2;
  use constant _NumSeq_Delta_dRadius_max => 2;  # at N=1
  use constant _NumSeq_dRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_dTRadius_min => -2;
  use constant _NumSeq_Delta_dTRadius_max => 2;
  use constant _NumSeq_dTRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_DSquared_min => 2;
  use constant _NumSeq_Delta_DSquared_max => 5;
}
{ package Math::PlanePath::PentSpiralSkewed;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  use constant _NumSeq_Delta_dRadius_min => -1;
  use constant _NumSeq_Delta_dRadius_max => 1;  # at N=1
  use constant _NumSeq_dRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_dTRadius_min => - sqrt(3);
  use constant _NumSeq_Delta_dTRadius_max => sqrt(3);
  use constant _NumSeq_dTRadius_min_is_infimum => 1;
  use constant _NumSeq_dTRadius_max_is_supremum => 1;

  use constant _NumSeq_Delta_DSquared_max => 2;
}
{ package Math::PlanePath::HexSpiral;
  use constant _NumSeq_Delta_dSumAbs_min => -2;
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  sub _NumSeq_Delta_dRadius_min {
    my ($self) = @_;
    return ($self->{'wider'} < 2 ? -sqrt(2)
            : -2);  # exact -2 along X axis initial horizontal
  }
  use constant _NumSeq_Delta_dRadius_max => 2;
  sub _NumSeq_dRadius_min_is_infimum {
    my ($self) = @_;
    return ($self->{'wider'} < 2);
  }

  sub _NumSeq_Delta_dTRadius_min {
    my ($self) = @_;
    return ($self->{'wider'} < 2 ? -1
            : -2);  # exact -2 along X axis initial horizontal
  }
  use constant _NumSeq_Delta_dTRadius_max => 2;  # N=1 along X axis
  *_NumSeq_dTRadius_min_is_infimum = \&_NumSeq_dRadius_min_is_infimum;

  use constant _NumSeq_Delta_TDir6_integer => 1;

  use constant _NumSeq_Delta_DSquared_min => 2;
  use constant _NumSeq_Delta_DSquared_max => 4;
  use constant _NumSeq_Delta_TDist_non_decreasing => 1;  # triangular
  use constant _NumSeq_Delta_TDSquared_max => 4;  # triangular
}
{ package Math::PlanePath::HexSpiralSkewed;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  use constant _NumSeq_Delta_dRadius_min => -1;
  use constant _NumSeq_Delta_dRadius_max => 1;
  sub _NumSeq_dRadius_min_is_infimum {
    my ($self) = @_;
    return ($self->{'wider'} == 0);
  }

  use constant _NumSeq_Delta_dTRadius_min => -1.5;
  use constant _NumSeq_Delta_dTRadius_max => sqrt(3);
  use constant _NumSeq_dTRadius_min_is_infimum => 1;
  use constant _NumSeq_dTRadius_max_is_supremum => 1;

  use constant _NumSeq_Delta_DSquared_max => 2;
}
{ package Math::PlanePath::HeptSpiralSkewed;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  use constant _NumSeq_Delta_dTRadius_min => -1.5;
  use constant _NumSeq_Delta_dTRadius_max => sqrt(3);
  use constant _NumSeq_dTRadius_min_is_infimum => 1;
  use constant _NumSeq_dTRadius_max_is_supremum => 1;

  use constant _NumSeq_Delta_DSquared_max => 2;
}
{ package Math::PlanePath::OctagramSpiral;
  use constant _NumSeq_Delta_dSumAbs_min => -2;
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  # dTRadius -> (dX + S*dY) / sqrt(1+S^2) 
  # S = 2*sqrt(3)/1 = sqrt(12)
  # dX = 1
  # dY = sqrt(3)
  # dTRadius = (1+sqrt(12)*sqrt(3)) / sqrt(13)
  #          = 7/sqrt(13)
  #          = 1.941450686788301927064196067
  #
  #                       1/2
  #                  *-----------*
  #                  |         .
  #                  |        .
  #          sqrt(3) |      .
  #                  |     .   H = sqrt(13)/2
  #                  |    .
  #                  |  .
  #            1/2   |.
  #        *---------*
  #          .     h
  #         p  .  .
  #             *
  # H = sqrt(sqrt(3)^2 + (1/2)^2) = sqrt(13)/2
  # p/h = sqrt(3)/(1/2)
  # p = sqrt(3)/(1/2) * h
  # h^2 + p^2 = (1/2)^2
  # h^2 + (sqrt(3)/(1/2))^2 * h^2 = (1/2)^2
  # h^2 + 12*h^2 = (1/2)^2
  # h^2  = 1/52
  # h  = 1/sqrt(52)
  # H+h = sqrt(13)/2 + 1/sqrt(52)
  #     = 1.941450686788301927064196067
  # cf x=1000000000; y=2*x; sqrt(x^2+3*y^2) - sqrt((x-1)^2+3*(y-1)^2)
  #     = 1.941450686756299992650077330
  #
  use constant _NumSeq_Delta_dTRadius_max =>    sqrt(13)/2 + 1/sqrt(52);
  use constant _NumSeq_Delta_dTRadius_min => - _NumSeq_Delta_dTRadius_max;
  use constant _NumSeq_dTRadius_min_is_infimum => 1;
  use constant _NumSeq_dTRadius_max_is_supremum => 1;

  use constant _NumSeq_Delta_DSquared_max => 2;
}
{ package Math::PlanePath::AnvilSpiral;
  use constant _NumSeq_Delta_AbsdX_non_decreasing => 1; # constant
  use constant _NumSeq_Delta_dSumAbs_min => -2;
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;
  use constant _NumSeq_Delta_TDir6_integer => 1;
  use constant _NumSeq_Delta_DSquared_max => 2;

  use constant _NumSeq_Delta_oeis_anum =>
    { 'wider=0,n_start=0' =>
     { AbsdX     => 'A000012',  # all 1s, OFFSET=0
       # OEIS-Other: A000012 planepath=AnvilSpiral,n_start=0 delta_type=AbsdX
     },
    };
}
{ package Math::PlanePath::KnightSpiral;
  use constant _NumSeq_Delta_dSumAbs_min => -3;
  use constant _NumSeq_Delta_dSumAbs_max => 3;
  use constant _NumSeq_Delta_dAbsDiff_min => -3;
  use constant _NumSeq_Delta_dAbsDiff_max => 3;

  use constant _NumSeq_Delta_DSquared_min => 2*2+1*1; # dX=1,dY=2
  use constant _NumSeq_Delta_DSquared_max => 2*2+1*1;
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_min => 2*2 + 3*1*1; # dX=2,dY=1
  use constant _NumSeq_Delta_TDSquared_max => 1*1 + 3*2*2; # dX=1,dY=2
}
{ package Math::PlanePath::CretanLabyrinth;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;
  use constant _NumSeq_Delta_DSquared_max => 1;
}
{ package Math::PlanePath::SquareArms;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_dRadius_min => -1/sqrt(2);
  use constant _NumSeq_Delta_dRadius_max => 1;
  use constant _NumSeq_dRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_dTRadius_min => -1.5;
  use constant _NumSeq_Delta_dTRadius_max => sqrt(3);  # at N=1
  use constant _NumSeq_dTRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;  # vertical
}
{ package Math::PlanePath::DiamondArms;  # diag always
  use constant _NumSeq_Delta_AbsdX_non_decreasing => 1; # constant absdx=1
  use constant _NumSeq_Delta_AbsdY_non_decreasing => 1; # constant absdy=1
  use constant _NumSeq_Delta_dSumAbs_min => 0; # only outwards
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  use constant _NumSeq_Delta_dRadius_min => -1;
  use constant _NumSeq_Delta_dRadius_max => sqrt(2);
  use constant _NumSeq_dRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_dTRadius_min => -sqrt(3);
  use constant _NumSeq_Delta_dTRadius_max => 2;  # at N=1
  use constant _NumSeq_dTRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_TDir6_integer => 1;

  use constant _NumSeq_Delta_DSquared_min => 2;   # diagonal always
  use constant _NumSeq_Delta_DSquared_max => 2;
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;

  use constant _NumSeq_Delta_TDSquared_min => 4;   # diagonal always
  use constant _NumSeq_Delta_TDSquared_max => 4;
  use constant _NumSeq_Delta_TDist_non_decreasing => 1;
}
{ package Math::PlanePath::HexArms;
  use constant _NumSeq_Delta_dSumAbs_min => -2;
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;
  use constant _NumSeq_Delta_TDir6_integer => 1;

  use constant _NumSeq_Delta_dRadius_min => - sqrt(2);  # diagonal
  use constant _NumSeq_Delta_dRadius_max => sqrt(10) - sqrt(2);  # at N=4
  use constant _NumSeq_dRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_dTRadius_min => -1;
  use constant _NumSeq_Delta_dTRadius_max => 2;  # at N=1
  use constant _NumSeq_dTRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_DSquared_min => 2;
  use constant _NumSeq_Delta_DSquared_max => 4;

  use constant _NumSeq_Delta_TDSquared_max => 4;  # triangular
  use constant _NumSeq_Delta_TDist_non_decreasing => 1;  # triangular
}
{ package Math::PlanePath::SacksSpiral;
  use constant _NumSeq_Delta_dX_integer => 0;
  use constant _NumSeq_Delta_dY_integer => 0;
  use constant _NumSeq_Delta_dSumAbs_min => - 2*atan2(1,0);  # -pi
  use constant _NumSeq_Delta_dSumAbs_max =>   2*atan2(1,0);  # +pi
  use constant _NumSeq_AbsdX_min_is_infimum => 1;

  use constant _NumSeq_Delta_dRadius_min => 0;
  use constant _NumSeq_Delta_dRadius_max => 1;  # at N=0 horiz along X axis
  use constant _NumSeq_dRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_dRSquared_min => 1;  # always R^2+1
  use constant _NumSeq_Delta_dRSquared_max => 1;
  use constant _NumSeq_Delta_dRSquared_integer => 1;

  use constant _NumSeq_Delta_Dist_increasing => 1; # each step bigger
}
{ package Math::PlanePath::VogelFloret;
  use constant _NumSeq_Delta_dX_integer => 0;
  use constant _NumSeq_Delta_dY_integer => 0;
  use constant _NumSeq_AbsdX_min_is_infimum => 1;
  use constant _NumSeq_AbsdY_min_is_infimum => 1;

  use constant _NumSeq_Delta_dRadius_min => 0;  # diagonal
  sub _NumSeq_Delta_dRadius_max {
    my ($self) = @_;
    return ($self->n_to_radius($self->n_start + 1)
            - $self->n_to_radius($self->n_start));
  }
  use constant _NumSeq_dRadius_min_is_infimum => 1;

  # R1^2 = (sqrt(N) * radius_factor)^2
  #      = N * radius_factor^2
  # R2^2 = (N+1) * radius_factor^2
  # R2^2-R1^2 = radius_factor^2    constant
  #
  sub _NumSeq_Delta_dRSquared_min {
    my ($self) = @_;
    return ($self->{'radius_factor'} ** 2);
  }
  *_NumSeq_Delta_dRSquared_max = \&_NumSeq_Delta_dRSquared_min;
  sub _NumSeq_Delta_dRSquared_integer {
    my ($self) = @_;
    my $rf_squared = $self->{'radius_factor'} ** 2;
    return ($rf_squared == int($rf_squared));
  }

  use constant _NumSeq_Dir4_min_is_infimum => 1;
  use constant _NumSeq_Dir4_max_is_supremum => 1;
}
{ package Math::PlanePath::TheodorusSpiral;
  use constant _NumSeq_Delta_dX_integer => 0;
  use constant _NumSeq_Delta_dY_integer => 0;
  use constant _NumSeq_dX_min_is_infimum => 1;
  use constant _NumSeq_dY_min_is_infimum => 1;

  use constant _NumSeq_dSum_min_is_infimum => 1;
  use constant _NumSeq_dSum_max_is_supremum => 1;

  use constant _NumSeq_Delta_dSumAbs_min => -1; # supremum vert/horiz
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_dSumAbs_min_is_infimum => 1;

  use constant _NumSeq_dDiffXY_min_is_infimum => 1;
  use constant _NumSeq_dDiffXY_max_is_supremum => 1;

  use constant _NumSeq_Delta_dAbsDiff_min => -sqrt(2); # supremum diagonal
  use constant _NumSeq_Delta_dAbsDiff_max => sqrt(2);
  use constant _NumSeq_dAbsDiff_min_is_infimum => 1;
  use constant _NumSeq_dAbsDiff_max_is_supremum => 1;

  use constant _NumSeq_Delta_dRadius_min => 0;
  use constant _NumSeq_Delta_dRadius_max => 1;  # at N=0 horiz along X axis
  use constant _NumSeq_dRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_dRSquared_min => 1;  # always R^2+1
  use constant _NumSeq_Delta_dRSquared_max => 1;
  use constant _NumSeq_Delta_dRSquared_integer => 1;

  use constant _NumSeq_Delta_dTRadius_min => -sqrt(2);
  use constant _NumSeq_Delta_dTRadius_max => 1;  # at N=0 horiz along X axis
  use constant _NumSeq_dTRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_DSquared_max => 1; # constant 1
  use constant _NumSeq_Delta_Dist_non_decreasing => 1; # constant 1
  use constant _NumSeq_Delta_TDSquared_max => 3; # vertical
}
{ package Math::PlanePath::ArchimedeanChords;
  use constant _NumSeq_Delta_dX_integer => 0;
  use constant _NumSeq_Delta_dY_integer => 0;
  use constant _NumSeq_dX_min_is_infimum => 1;

  use constant _NumSeq_AbsdX_min_is_infimum => 1;
  use constant _NumSeq_dY_min_is_infimum => 1;
  use constant _NumSeq_dY_max_is_supremum => 1;

  use constant _NumSeq_dSum_min_is_infimum => 1;

  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_dSumAbs_min_is_infimum => 1;

  use constant _NumSeq_dDiffXY_min_is_infimum => 1;

  use constant _NumSeq_Delta_dAbsDiff_min => -sqrt(2); # supremum when diagonal
  use constant _NumSeq_Delta_dAbsDiff_max => sqrt(2);
  use constant _NumSeq_dAbsDiff_min_is_infimum => 1;

  use constant _NumSeq_Delta_dRadius_min => 0;
  use constant _NumSeq_Delta_dRadius_max => 1;  # at N=0
  use constant _NumSeq_dRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_dRSquared_min => -1/(4*atan2(1,1));  # -1/pi
  use constant _NumSeq_Delta_dRSquared_max => 1;  # at N=0

  use constant _NumSeq_Delta_DSquared_max => 1;
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;  # supremum
  use constant _NumSeq_TDSquared_max_is_supremum => 1;

  use constant _NumSeq_Dir4_max_is_supremum => 1;
}
{ package Math::PlanePath::MultipleRings;
  sub _NumSeq_Delta__step_is_0 {
    my ($self) = @_;
    return ($self->{'step'} == 0); # constant when column only
  }

  #---------
  # dX
  sub _NumSeq_dX_min_is_infimum {
    my ($self) = @_;
    if ($self->{'step'} == 0) {
      return 0;    # horizontal only, exact
    }
    return 1;  # infimum
  }
  sub _NumSeq_dX_max_is_supremum {
    my ($self) = @_;
    return ($self->{'step'} <= 6
            ? 0
            : 1); # supremum
  }
  *_NumSeq_Delta_dX_non_decreasing = \&_NumSeq_Delta__step_is_0; # constant dX=1,dY=0
  *_NumSeq_Delta_dX_integer        = \&_NumSeq_Delta__step_is_0;

  #---------
  # dY
  *_NumSeq_dY_max_is_supremum      = \&_NumSeq_dX_min_is_infimum;
  *_NumSeq_dY_min_is_infimum       = \&_NumSeq_dX_min_is_infimum;
  *_NumSeq_Delta_dY_non_decreasing = \&_NumSeq_Delta__step_is_0;
  *_NumSeq_Delta_dY_integer        = \&_NumSeq_Delta__step_is_0;

  #---------
  # AbsdX
  sub _NumSeq_AbsdX_min_is_infimum {
    my ($self) = @_;
    if ($self->{'step'} == 1) {
      return 0; # horizontal only
    }
    if ($self->{'step'} % 2 == 1) {
      return 0; # any odd num sides has left vertical dX=0 exactly
    }
    return $self->_NumSeq_dX_min_is_infimum;
  }
  *_NumSeq_Delta_AbsdX_non_decreasing   = \&_NumSeq_Delta_dX_non_decreasing;

  #---------
  # AbsdY
  sub _NumSeq_Delta_AbsdY_non_decreasing {
    my ($self) = @_;
    if ($self->{'ring_shape'} eq 'polygon' && $self->{'step'} == 4) {
      return 1;   # abs(dY) constant
    }
    return $self->_NumSeq_Delta_dY_non_decreasing;
  }

  #---------
  # dSum
  *_NumSeq_dSum_max_is_supremum    = \&_NumSeq_dX_min_is_infimum;
  *_NumSeq_dSum_min_is_infimum     = \&_NumSeq_dX_min_is_infimum;
  *_NumSeq_Delta_dSum_non_decreasing = \&_NumSeq_Delta__step_is_0;

  #---------
  # dDiffXY
  *_NumSeq_dDiffXY_min_is_infimum  = \&_NumSeq_dX_min_is_infimum;
  *_NumSeq_dDiffXY_max_is_supremum = \&_NumSeq_dX_min_is_infimum;
  *_NumSeq_Delta_dDiffXY_non_decreasing = \&_NumSeq_Delta__step_is_0;

  #---------
  # dDiffYX
  *_NumSeq_Delta_dDiffYX_non_decreasing = \&_NumSeq_Delta__step_is_0;

  #---------
  # dSumAbs
  *_NumSeq_Delta_dSumAbs_non_decreasing = \&_NumSeq_Delta__step_is_0;

  #---------
  # dAbsDiff
  sub _NumSeq_Delta_dAbsDiff_min {
    my ($self) = @_;
    return ($self->{'step'} == 0
            ? 1    # always dX=+1,dY=0 so d(abs(X-Y))=1 always
            # FIXME: side length some maximum?
            : undef);
  }
  sub _NumSeq_Delta_dAbsDiff_max {
    my ($self) = @_;
    return ($self->{'step'} == 0
            ? 1    # always dX=+1,dY=0 so d(abs(X-Y))=1 always
            # FIXME: side length some maximum?
            : undef);
  }
  *_NumSeq_Delta_dAbsDiff_non_decreasing = \&_NumSeq_Delta__step_is_0;

  #---------
  # dRadius,dRSquared
  sub _NumSeq_Delta_dRadius_min {
    my ($self) = @_;
    return ($self->{'step'} == 0 ? 1     # step=0 always dRadius=+1
            : $self->{'ring_shape'} eq 'circle' ? 0  # within circle dRadius=0
            : undef);
  }
  sub _NumSeq_Delta_dRadius_max {
    my ($self) = @_;
    return ($self->{'step'} == 0 ? 1     # always dRadius=+1
            : $self->{'ring_shape'} eq 'circle' ? 1
            : undef);
  }
  sub _NumSeq_Delta_dRadius_integer {
    my ($self) = @_;
    return ($self->{'step'} <= 1 || $self->{'step'} == 6);
  }

  *_NumSeq_Delta_dRSquared_min = \&_NumSeq_Delta_dRadius_min;
  *_NumSeq_Delta_dRSquared_increasing = \&_NumSeq_Delta__step_is_0; # step==0
  *_NumSeq_Delta_dRSquared_integer = \&_NumSeq_Delta_dRadius_integer;

  #---------
  # dTRadius,dTRSquared
  # step odd vertical
  sub _NumSeq_Delta_dTRadius_min {
    my ($self) = @_;
    return ($self->{'step'} == 0 ? 1     # step=0 always dTRadius=+1
            : undef);
  }
  sub _NumSeq_Delta_dTRadius_max {
    my ($self) = @_;
    return ($self->{'step'} == 0 ? 1     # always dTRadius=+1
            : undef);
  }
  *_NumSeq_Delta_dTRadius_integer      = \&_NumSeq_Delta__step_is_0;

  *_NumSeq_Delta_dTRSquared_min = \&_NumSeq_Delta_dTRadius_min;
  *_NumSeq_Delta_dTRSquared_increasing = \&_NumSeq_Delta__step_is_0;
  *_NumSeq_Delta_dTRSquared_integer    = \&_NumSeq_Delta__step_is_0;

  #---------
  # DSquared
  sub _NumSeq_Delta_DSquared_max {
    my ($self) = @_;
    return ($self->{'step'} == 0
            ? 1    # horizontal only

            : $self->{'step'} <= 6
            ? ((8*atan2(1,1)) / $self->{'step'}) ** 2

            # step > 6, between rings
            : ((0.5/_PI()) * $self->{'step'}) ** 2);
  }

  *_NumSeq_Delta_Dist_non_decreasing    = \&_NumSeq_Delta__step_is_0;
  *_NumSeq_Delta_TDist_non_decreasing   = \&_NumSeq_Delta__step_is_0;

  #-----------
  # Dir4,TDir6
  *_NumSeq_Delta_Dir4_non_decreasing    = \&_NumSeq_Delta__step_is_0;
  *_NumSeq_Delta_TDir6_non_decreasing   = \&_NumSeq_Delta__step_is_0;
  *_NumSeq_Delta_Dir4_integer           = \&_NumSeq_Delta__step_is_0;
  *_NumSeq_Delta_TDir6_integer          = \&_NumSeq_Delta__step_is_0;

  use constant _NumSeq_Delta_oeis_anum =>
    {
     # MultipleRings step=0 is trivial X=N,Y=0
     'step=0,ring_shape=circle' =>
     { dX     => 'A000012',  # all 1s
       dY     => 'A000004',  # all-zeros
       Dir4   => 'A000004',  # all zeros, East
       TDir6  => 'A000004',  # all zeros, East
       # OEIS-Other: A000012 planepath=MultipleRings,step=0 delta_type=dX
       # OEIS-Other: A000004 planepath=MultipleRings,step=0 delta_type=dY
       # OEIS-Other: A000004 planepath=MultipleRings,step=0 delta_type=Dir4
       # OEIS-Other: A000004 planepath=MultipleRings,step=0 delta_type=TDir6
     },
    };
}
{ package Math::PlanePath::PixelRings;  # NSEW+diag
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;
  use constant _NumSeq_Delta_DSquared_max => 5; # dx=2,dy=1 at jump N=5 to N=6
}
{ package Math::PlanePath::FilledRings;  # NSEW+diag
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;
  use constant _NumSeq_Delta_DSquared_max => 2;
}
{ package Math::PlanePath::Hypot;

  use constant _NumSeq_Delta_dRadius_min => 0;
  use constant _NumSeq_Delta_dRSquared_min => 0;
  {
    my %_NumSeq_Delta_dRadius_max = (all  => 1,
                                     even => sqrt(2),   # N=1
                                     odd  => sqrt(5)-1, # N=4 0,1 -> 2,1
                                    );
    sub _NumSeq_Delta_dRadius_max {
      my ($self) = @_;
      return $_NumSeq_Delta_dRadius_max{$self->{'points'}};
    }
  }

  # approaches horizontal
  use constant _NumSeq_Dir4_max_is_supremum => 1;


  sub _NumSeq_Delta_DSquared_min {
    my ($self) = @_;
    return ($self->{'points'} eq 'all'
            ? 1    # dX=1,dY=0
            : 2);   # dX=1,dY=1
  }
  sub _NumSeq_Delta_TDSquared_min {
    my ($self) = @_;
    return ($self->{'points'} eq 'all'
            ? 1    # dX=1,dY=0
            : 4);   # dX=1,dY=1
  }
}
{ package Math::PlanePath::HypotOctant;
  use constant _NumSeq_Delta_dRadius_min => 0;
  use constant _NumSeq_Delta_dRSquared_min => 0;
  {
    my %_NumSeq_Delta_dRadius_max = (all  => 1,         # N=1
                                     even => sqrt(2),   # N=1
                                     odd  => sqrt(5)-1, # N=1 1,0 -> 2,1
                                    );
    sub _NumSeq_Delta_dRadius_max {
      my ($self) = @_;
      return $_NumSeq_Delta_dRadius_max{$self->{'points'}};
    }
  }
  sub _NumSeq_Delta_DSquared_min {
    my ($self) = @_;
    return ($self->{'points'} eq 'all'
            ? 1    # dX=1,dY=0
            : 2);   # dX=1,dY=1
  }
  sub _NumSeq_Delta_TDSquared_min {
    my ($self) = @_;
    return ($self->{'points'} eq 'all'
            ? 1    # dX=1,dY=0
            : 4);   # dX=1,dY=1
  }
  use constant _NumSeq_Delta_TDir6_integer => 0;
}
{ package Math::PlanePath::TriangularHypot;
  # approaches horizontal
  use constant _NumSeq_Dir4_max_is_supremum => 1;

  # non-decreasing TRadius
  use constant _NumSeq_Delta_dTRadius_min => 0;
  {
    my %_NumSeq_Delta_dTRadius_max = (odd => 1,
                                      all => 1,  # at N=1
                                     );
    sub _NumSeq_Delta_dTRadius_max {
      my ($self) = @_;
      return $_NumSeq_Delta_dTRadius_max{$self->{'points'}} || 2;
    }
  }
  sub _NumSeq_dTRadius_max_is_supremum {
    my ($self) = @_;
    return $self->{'points'} eq 'odd';
  }
  use constant _NumSeq_Delta_dTRSquared_min => 0;

  sub _NumSeq_Delta_DSquared_min {
    my ($self) = @_;
    return ($self->{'points'} eq 'all'
            ? 1    # dX=1,dY=0
            : 2);   # dX=1,dY=1
  }
  sub _NumSeq_Delta_TDSquared_min {
    my ($self) = @_;
    return ($self->{'points'} eq 'all'
            ? 1    # dX=1,dY=0
            : 4);   # dX=1,dY=1
  }
}
{ package Math::PlanePath::PythagoreanTree;
  {
    my %_NumSeq_Delta_dRadius_integer = ('AB' => 1,  # Radius=C
                                         'SM' => 1,  # Radius=C
                                        );
    sub _NumSeq_Delta_dRadius_integer {
      my ($self) = @_;
      return $_NumSeq_Delta_dRadius_integer{$self->{'coordinates'}};
    }
  }
  {
    my %Dir4_min_is_infimum = ('BC,UAD' => 1,
                               'SM,UAD' => 1,
                               'SC,UAD' => 1,
                               'MC,UAD' => 1,

                               'AB,FB' => 1,
                               'AC,FB' => 1,
                               'BC,FB' => 1,
                               'PQ,FB' => 1,
                               'SM,FB' => 1,
                               'SC,FB' => 1,
                               'MC,FB' => 1,

                               'AC,UMT' => 1,
                               'SM,UMT' => 1,
                               'SC,UMT' => 1,
                              );
    sub _NumSeq_Dir4_min_is_infimum {
      my ($self) = @_;
      return $Dir4_min_is_infimum{"$self->{'coordinates'},$self->{'tree_type'}"};
    }
  }
  {
    my %Dir4_max_is_supremum = ('BC,UAD' => 1,
                                'SM,UAD' => 1,
                                'SC,UAD' => 1,
                                'MC,UAD' => 1,

                                'AB,FB'  => 1,
                                'AC,FB'  => 1,
                                'PQ,FB'  => 1,
                                'SM,FB' => 1,
                                'SC,FB' => 1,
                                'MC,FB' => 1,

                                'AB,UMT' => 1,
                                'BC,UMT' => 1,
                                'SM,UMT' => 1,
                                'SC,UMT' => 1,
                                'MC,UMT' => 1,
                               );
    sub _NumSeq_Dir4_max_is_supremum {
      my ($self) = @_;
      return $Dir4_max_is_supremum{"$self->{'coordinates'},$self->{'tree_type'}"};
    }
  }
  use constant _NumSeq_Delta_TDir6_integer => 0;
}
{ package Math::PlanePath::RationalsTree;
  {
    my %Dir4_min_is_infimum = (Drib => 1);
    sub _NumSeq_Dir4_min_is_infimum {
      my ($self) = @_;
      return $Dir4_min_is_infimum{$self->{'tree_type'}};
    }
  }
  {
    my %Dir4_max_is_supremum = (CW   => 1,
                                AYT  => 1,
                                Drib => 1,
                                L    => 1);
    sub _NumSeq_Dir4_max_is_supremum {
      my ($self) = @_;
      return $Dir4_max_is_supremum{$self->{'tree_type'}};
    }
  }
  use constant _NumSeq_Delta_TDir6_integer => 0; # vertical

  use constant _NumSeq_Delta_oeis_anum =>
    { 'tree_type=L' =>
      { dY => 'A070990',  # Stern diatomic differences OFFSET=0
        # OEIS-Catalogue: A070990 planepath=RationalsTree,tree_type=L delta_type=dY
      },

      # 'tree_type=CW' =>
      # {
      #  # dY => 'A070990', # Stern diatomic first diffs, except it starts i=0
      #  # where RationalsTree N=1.  dX is same, but has extra leading 0.
      # },
    };
}
{ package Math::PlanePath::FractionsTree;
  use constant _NumSeq_Dir4_max_is_supremum => 1;
}
{ package Math::PlanePath::ChanTree;
  sub _NumSeq_Dir4_min_is_infimum {
    my ($self) = @_;
    return ($self->{'k'} == 2 || ($self->{'k'} & 1) == 0
            ? 0    # k=2 or k odd
            : 1);  # k even
  }

  use constant _NumSeq_Dir4_max_is_supremum => 1;
}
{ package Math::PlanePath::DiagonalRationals;
  use constant _NumSeq_TDSquared_min => 3;
}
{ package Math::PlanePath::FactorRationals;
  use constant _NumSeq_Dir4_min_is_infimum => 1;
  use constant _NumSeq_Dir4_max_is_supremum => 1;
}
{ package Math::PlanePath::CfracDigits;

  # radix=1 N=1       has dir4=0
  # radix=2 N=5628    has dir4=0 dx=9,dy=0
  # radix=3 N=1189140 has dir4=0 dx=1,dy=0
  # radix=4 N=169405  has dir4=0 dx=2,dy=0
  # always eventually 0 ?
  sub _NumSeq_Dir4_min_is_infimum {
    my ($self) = @_;
    return ($self->{'radix'} > 4);
  }
  use constant _NumSeq_Dir4_max_is_supremum => 1;
  use constant _NumSeq_Delta_Dir4_integer => 0;
}
{ package Math::PlanePath::GcdRationals;
  sub _NumSeq_Delta_TDSquared_min {
    my ($self) = @_;
    return ($self->{'pairs_order'} eq 'diagonals_down'
            ? 3   # at N=1 vert
            : 1); # at N=4 horiz
  }
  use constant _NumSeq_Delta_TDir6_integer => 0; # vertical
}
{ package Math::PlanePath::PeanoCurve;

  *_NumSeq_Delta_dAbsDiff_min = \&dx_minimum;
  *_NumSeq_Delta_dAbsDiff_max = \&dx_maximum;

  *_NumSeq_Delta_DSquared_max = \&dx_maximum;
  sub _NumSeq_Delta_Dist_non_decreasing {
    my ($self) = @_;
    return ($self->{'radix'} % 2
            ? 1     # odd
            : 0);   # even, jumps about
  }
  sub _NumSeq_Delta_TDSquared_max {
    my ($self) = @_;
    return ($self->{'radix'} % 2
            ? 3         # odd, vertical
            : undef);   # even, unlimited
  }

  sub _NumSeq_Delta_Dir4_integer {
    my ($self) = @_;
    return ($self->{'radix'} % 2
            ? 1      # odd, continuous path
            : 0);    # even, jumps
  }

  sub _NumSeq_Dir4_max_is_supremum {
    my ($self) = @_;
    return ($self->{'radix'} % 2
            ? 0      # odd
            : 1);    # even, supremum
  }

  # use constant _NumSeq_Delta_oeis_anum =>
  #   { 'radix=3' =>
  #     {
  #      # Not quite, extra initial 0
  #      # AbsdX => 'A014578', # 1 - count low 0-digits, mod 2
  #      #  # OEIS-Catalogue: A014578 planepath=PeanoCurve delta_type=AbsdX
  #
  #      #  # Not quite, OFFSET n=1 cf N=0
  #      #  # # A163534 is 0=east,1=south,2=west,3=north treated as down page,
  #      #  # # which corrsponds to 1=north (incr Y), 3=south (decr Y) for
  #      #  # # directions of the PeanoCurve planepath here
  #      #  # Dir4 => 'A163534',
  #      #  # # OEIS-Catalogue: A163534 planepath=PeanoCurve delta_type=Dir4
  #      #
  #      #  # delta a(n)-a(n-1), so initial dx=0 at i=0 ...
  #      #  # dX => 'A163532',
  #      #  # # OEIS-Catalogue: A163532 planepath=PeanoCurve delta_type=dX
  #      #  # dY => 'A163533',
  #      #  # # OEIS-Catalogue: A163533 planepath=PeanoCurve delta_type=dY
  #     },
  #   };
}
# { package Math::PlanePath::PeanoDiagonals;
# }
{ package Math::PlanePath::WunderlichSerpentine;
  sub _NumSeq_Delta_dAbsDiff_min { return $_[0]->dsumxy_minimum; }
  sub _NumSeq_Delta_dAbsDiff_max { return $_[0]->dsumxy_maximum; }

  # radix=2 0101 is straight NSEW parts, other evens are diagonal
  sub _NumSeq_Delta_Dir4_integer {
    my ($self) = @_;
    return (($self->{'radix'} % 2)
            || join('',@{$self->{'serpentine_array'}}) eq '0101'
            ? 1      # odd, continuous path
            : 0);    # even, jumps
  }
  sub _NumSeq_Dir4_max_is_supremum {
    my ($self) = @_;
    return (($self->{'radix'} % 2)
            || join('',@{$self->{'serpentine_array'}}) eq '0101'
            ? 0      # odd, South
            : 1);    # even, supremum
  }

  *_NumSeq_Delta_DSquared_max = \&Math::PlanePath::PeanoCurve::_NumSeq_Delta_DSquared_max;
  *_NumSeq_Delta_Dist_non_decreasing = \&Math::PlanePath::PeanoCurve::_NumSeq_Delta_Dist_non_decreasing;
  *_NumSeq_Delta_TDSquared_max = \&Math::PlanePath::PeanoCurve::_NumSeq_Delta_TDSquared_max;
}
{ package Math::PlanePath::HilbertCurve;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  # only approached as steps towards origin are only at X=2 or Y=2 not on axes
  use constant _NumSeq_Delta_dRadius_max => 1;  # at N=0
  use constant _NumSeq_Delta_dRadius_min => -1;
  use constant _NumSeq_dRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;

  # 'Math::PlanePath::HilbertCurve' =>
  # {
  #  # Not quite, OFFSET=1 at origin, cf path N=0
  #  # # A163540 is 0=east,1=south,2=west,3=north for drawing down the page,
  #  # # which corresponds to 1=north,3=south per the HilbertCurve planepath
  #  # Dir4 => 'A163540',
  #  # # OEIS-Catalogue: A163540 planepath=HilbertCurve delta_type=Dir4
  #
  # Not quite, # A163538 path(n)-path(n-1) starting i=0 with path(-1)=0 for
  # first value 0
  # # dX => 'A163538',
  # # # OEIS-Catalogue: A163538 planepath=HilbertCurve delta_type=dX
  # # dY => 'A163539',
  # # # OEIS-Catalogue: A163539 planepath=HilbertCurve delta_type=dY
  # #
  # # cf A163541    absolute direction, transpose X,Y
  # # would be N=0,E=1,S=2,W=3
  # },
}
{ package Math::PlanePath::HilbertSides;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  # only approached as steps towards origin are only at X=2 or Y=2 not on axes
  use constant _NumSeq_Delta_dRadius_max => 1;  # at N=0
  use constant _NumSeq_Delta_dRadius_min => -1;
  use constant _NumSeq_dRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_oeis_anum =>
    { '' =>
      { AbsdX => 'A010059', # 1 - Thue-Morse binary parity 
        AbsdY => 'A010060', # Thue-Morse binary parity
        # OEIS-Other: A010059 planepath=HilbertSides delta_type=AbsdX
        # OEIS-Other: A010060 planepath=HilbertSides delta_type=AbsdY
      },
    };
}
{ package Math::PlanePath::HilbertSpiral;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;
  use constant _NumSeq_Delta_dRadius_max => 1;  # at N=0
  use constant _NumSeq_Delta_dRadius_min => -1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;
}
# { package Math::PlanePath::HilbertMidpoints;
#   use constant _NumSeq_Delta_DSquared_min => 2;
#   use constant _NumSeq_Delta_DSquared_max => 4;
# }
{ package Math::PlanePath::ZOrderCurve;
  use constant _NumSeq_Delta_dRadius_max => 1;

  # diagonal up towards Y axis
  # X=1,Y     TRsq = sqrt(1+3*Y^2)
  # X=0,Y+1   TRsq = sqrt(1+3*(Y+1)^2)
  # dTRsq = sqrt(1+3*(Y+1)^2) - sqrt(1+3*Y^2)
  #      -> sqrt(3*(Y+1)^2) - sqrt(3*Y^2)
  #       = sqrt(3)*(sqrt((Y+1)^2) - sqrt(Y^2))
  #      -> sqrt(3)
  #      as Y -> infinity
  use constant _NumSeq_Delta_dTRadius_max => sqrt(3);
  use constant _NumSeq_dTRadius_max_is_supremum => 1;

  use constant _NumSeq_Delta_TDir6_integer => 0; # verticals
}
{ package Math::PlanePath::GrayCode;
  sub _NumSeq_Delta_dSumAbs_min { return $_[0]->dsumxy_minimum; }
  sub _NumSeq_Delta_dSumAbs_max { return $_[0]->dsumxy_maximum; }
  sub _NumSeq_Delta_dAbsDiff_min { return $_[0]->ddiffxy_minimum; }
  sub _NumSeq_Delta_dAbsDiff_max { return $_[0]->ddiffxy_maximum; }

  {
    my %Dir4_integer = (reflected => { TsF => 1,
                                       FsT => 1,
                                       Ts  => 1,
                                       Fs  => 1,
                                     },
                        modular => { TsF => 1,
                                     Ts  => 1,
                                   },
                       );
    sub _NumSeq_Delta_Dir4_integer {
      my ($self) = @_;
      my $gray_type = ($self->{'radix'} == 2
                       ? 'reflected'
                       : $self->{'gray_type'});
      return $Dir4_integer{$gray_type}->{$self->{'apply_type'}};
    }
  }
  use constant _NumSeq_Delta_TDir6_integer => 0;

  sub _NumSeq_Delta_Dist_non_decreasing {
    my ($self) = @_;
    return ($self->{'radix'} % 2
            && $self->{'gray_type'} eq 'reflected'
            && ($self->{'apply_type'} eq 'TsF'
                || $self->{'apply_type'} eq 'FsT')
            ? 1    # PeanoCurve style NSEW only
            : 0);
  }
}
{ package Math::PlanePath::ImaginaryBase;
  # Dir4 radix=2 goes south-east at
  #  N=2^3-1=7
  #  N=2^7-1=127
  #  N=2^11-1=2047
  #  N=2^15-1=32767
  # dx=0x555555
  # dy=-0xAAAAAB
  # approaches dx=1,dy=-2
  #
  # radix=3
  # dy=dx+1 approches SE
  #
  # radix=4 dx/dy=1.5
  # radix=5 dx/dy=2
  # dx/dy=(radix-1)/2

  use constant _NumSeq_Dir4_max_is_supremum => 1;
  use constant _NumSeq_Delta_TDir6_integer => 0;
}
{ package Math::PlanePath::ImaginaryHalf;
  {
    my %_NumSeq_Dir4_min_is_infimum = (XYX => 0,
                                       XXY => 0,
                                       YXX => 1,  # dX=big,dY=1
                                       XnYX => 1,  # dX=big,dY=1
                                       XnXY => 0,  # dX=1,dY=0 at N=1
                                       YXnX =>  1,  # dX=big,dY=1
                                      );
    sub _NumSeq_Dir4_min_is_infimum {
      my ($self) = @_;
      return $_NumSeq_Dir4_min_is_infimum{$self->{'digit_order'}};
    }
  }

  use constant _NumSeq_Dir4_max_is_supremum => 1;
  use constant _NumSeq_Delta_TDir6_integer => 0;
}
{ package Math::PlanePath::CubicBase;
  use constant _NumSeq_Delta_DSquared_min => 4; # at X=0 to X=2
  # direction supremum maybe at
  #   dx=-0b 1001001001001001... = - (8^k-1)/7
  #   dy=-0b11011011011011011... = - (3*8^k-1)/7
  # which is
  #   dx=-1, dy=-3
  use constant _NumSeq_Dir4_max_is_supremum => 1;

  use constant _NumSeq_Delta_TDSquared_min => 4;  # at N=0 dX=2,dY=1
}
# { package Math::PlanePath::Flowsnake;
#   # (inherits from FlowsnakeCentres)
# 
#   # Not quite, A261180 OFFSET=1 whereas n_start=0 here
#   # use constant _NumSeq_Delta_oeis_anum =>
#   #   { 'n_start=1' =>
#   #     { TDir6 => 'A261180',
#   #       # OEIS-Catalogue: A261180 planepath=Flowsnake delta_type=TDir6
#   #     },
#   #   };
# }
{ package Math::PlanePath::FlowsnakeCentres;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  # dRadius_min at arms=1 N=8591
  #                arms=2 N=85
  #                arms=3 N=127
  use constant _NumSeq_Delta_dRadius_min => -2;
  use constant _NumSeq_Delta_dRadius_max => 2;  # at N=0

  use constant _NumSeq_Delta_dTRadius_min => -2; # along X axis dX=-2,dY=0
  use constant _NumSeq_Delta_dTRadius_max => 2;  # at N=0

  use constant _NumSeq_Delta_DSquared_min => 2;
  use constant _NumSeq_Delta_DSquared_max => 4;
  use constant _NumSeq_Delta_TDist_non_decreasing => 1;  # triangular
  use constant _NumSeq_Delta_TDSquared_max => 4;         # triangular
}
{ package Math::PlanePath::GosperReplicate;
  # maximum angle N=34 dX=3,dY=-1, it seems
}
{ package Math::PlanePath::GosperIslands;
  use constant _NumSeq_Delta_DSquared_min => 2;
  use constant _NumSeq_Delta_TDir6_integer => 0; # between islands
}
{ package Math::PlanePath::GosperSide;
  use constant _NumSeq_Delta_dSumAbs_min => -2; # diagonals
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;
  use constant _NumSeq_Delta_DSquared_min => 2;
  use constant _NumSeq_Delta_DSquared_max => 4;

  # use constant _NumSeq_Delta_oeis_anum =>
  # 'Math::PlanePath::GosperSide' =>
  # 'Math::PlanePath::TerdragonCurve' =>
  # A062756 is total turn starting OFFSET=0, count of ternary 1 digits.
  # Dir6 would be total%6, or 2*(total%3) for Terdragon, suspect such a
  # modulo version not in OEIS.
}
{ package Math::PlanePath::KochCurve;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  use constant _NumSeq_Delta_dTRadius_min => -2;
  use constant _NumSeq_Delta_dTRadius_max => 2;
  use constant _NumSeq_dTRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_DSquared_min => 2;
  use constant _NumSeq_Delta_DSquared_max => 4;

  use constant _NumSeq_Delta_oeis_anum =>
    { '' =>
      { AbsdY => 'A011655', # 0,1,1 repeating
        # OEIS-Catalogue: A011655 planepath=KochCurve delta_type=AbsdY
      },
    };
}
{ package Math::PlanePath::KochPeaks;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;

  use constant _NumSeq_Delta_dTRadius_min => -2;
  use constant _NumSeq_dTRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_DSquared_min => 2;
}
{ package Math::PlanePath::KochSnowflakes;
  use constant _NumSeq_Delta_dX_integer => 1;
  use constant _NumSeq_Delta_dY_integer => 0; # initial Y=+2/3

  use constant _NumSeq_Delta_dTRadius_min => -2;
  use constant _NumSeq_dTRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_DSquared_min => 2; # step diag or 2straight
  use constant _NumSeq_Delta_Dir4_integer => 0; # diagonals
  use constant _NumSeq_Delta_TDir6_integer => 0; # between rings
}
{ package Math::PlanePath::KochSquareflakes;
  use constant _NumSeq_Delta_dX_integer => 0; # initial non-integers
  use constant _NumSeq_Delta_dY_integer => 0;
  use constant _NumSeq_Delta_dSum_integer => 1;
  use constant _NumSeq_Delta_dSumAbs_integer => 1;
  use constant _NumSeq_Delta_dDiffXY_integer => 1;
  use constant _NumSeq_Delta_dAbsDiff_integer => 1;

  use constant _NumSeq_Delta_dTRadius_min => -2;
  use constant _NumSeq_dTRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_TDir6_integer => 0; # between rings
}

{ package Math::PlanePath::QuadricCurve;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;
}
{ package Math::PlanePath::QuadricIslands;
  use constant _NumSeq_Delta_dX_integer => 0; # initial 0.5s
  use constant _NumSeq_Delta_dY_integer => 0;

  # minimum unbounded jumping to next ring
  use constant _NumSeq_Delta_dSum_integer => 1;  # 0.5+0.5 integer

  # maximum unbounded jumping to next ring
  use constant _NumSeq_Delta_dSumAbs_min => -1;     # at N=5
  use constant _NumSeq_Delta_dSumAbs_integer => 1;  # 0.5+0.5 integer

  use constant _NumSeq_Delta_dDiffXY_integer => 1;   # dDiffXY=+1 or -1

  # dAbsDiff=+1 or -1
  # jump to next ring is along leading diagonal so dAbsDiff bounded
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_integer => 1;  # 0.5-0.5 integer

  use constant _NumSeq_Delta_Dir4_integer => 0; # between islands
}

{ package Math::PlanePath::SierpinskiCurve;

  sub _NumSeq_Delta_dSumAbs_min { return $_[0]->dsumxy_minimum; }
  sub _NumSeq_Delta_dSumAbs_max { return $_[0]->dsumxy_maximum; }
  sub _NumSeq_Delta_dAbsDiff_min { return $_[0]->ddiffxy_minimum; }
  sub _NumSeq_Delta_dAbsDiff_max { return $_[0]->ddiffxy_maximum; }

  sub _NumSeq_Delta_Dir4_integer {
    my ($self) = @_;
    return ($self->{'diagonal_spacing'} == 0);
  }
  sub _NumSeq_Delta_TDir6_integer {
    my ($self) = @_;
    return ($self->{'straight_spacing'} == 0);
  }

  use List::Util;
  sub _NumSeq_Delta_DSquared_min {
    my ($self) = @_;
    return List::Util::min ($self->{'straight_spacing'} ** 2,
                            2 * $self->{'diagonal_spacing'} ** 2);
  }
  sub _NumSeq_Delta_DSquared_max {
    my ($self) = @_;
    return List::Util::max ($self->{'straight_spacing'} ** 2,
                            2 * $self->{'diagonal_spacing'} ** 2);
  }
  sub _NumSeq_Delta_TDSquared_min {
    my ($self) = @_;
    return List::Util::min($self->{'straight_spacing'},
                           2 * $self->{'diagonal_spacing'}) ** 2;
  }
  sub _NumSeq_Delta_TDSquared_max {
    my ($self) = @_;
    return List::Util::max(3 * $self->{'straight_spacing'} ** 2, # vertical
                           4 * $self->{'diagonal_spacing'} ** 2);
  }

  # use constant _NumSeq_Delta_oeis_anum =>
  # 'arms=1,straight_spacing=1,diagonal_spacing=1' =>
  # {
  #  # # Not quite, A127254 has extra initial 1
  #  # AbsdY => 'A127254',  # 0 at 2*position of "odious" odd number 1-bits
  #  # # OEIS-Catalogue: A127254 planepath=SierpinskiCurve delta_type=AbsdY
  # },
}
{ package Math::PlanePath::SierpinskiCurveStair;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;

  use constant _NumSeq_Delta_oeis_anum =>
    { 'arms=1' =>
      { AbsdX => 'A059841',  # 1,0 repeating
        AbsdY => 'A000035',  # 0,1 repeating

        # OEIS-Other: A059841 planepath=SierpinskiCurveStair delta_type=AbsdX
        # OEIS-Other: A000035 planepath=SierpinskiCurveStair delta_type=AbsdY
        #
        # OEIS-Other: A059841 planepath=SierpinskiCurveStair,diagonal_length=2 delta_type=AbsdX
        # OEIS-Other: A059841 planepath=SierpinskiCurveStair,diagonal_length=3 delta_type=AbsdX
        # OEIS-Other: A000035 planepath=SierpinskiCurveStair,diagonal_length=2 delta_type=AbsdY
        # OEIS-Other: A000035 planepath=SierpinskiCurveStair,diagonal_length=3 delta_type=AbsdY
      },
    };
}
{ package Math::PlanePath::SierpinskiTriangle;
  use constant _NumSeq_Delta_DSquared_min => 2;

  sub _NumSeq_Delta_dSumAbs_min { return $_[0]->dsumxy_minimum; }
  sub _NumSeq_Delta_dSumAbs_max { return $_[0]->dsumxy_maximum; }

  sub _NumSeq_Dir4_max_is_supremum {
    my ($self) = @_;
    return ($self->{'align'} ne 'diagonal');
  }
  use constant _NumSeq_Delta_Dir4_integer => 0;  # between rows
  use constant _NumSeq_Delta_TDir6_integer => 0; # between rows
}
{ package Math::PlanePath::SierpinskiArrowhead;
  {
    my %_NumSeq_Delta_dSumAbs_min = (triangular => -2,
                                     left       => -2,
                                     right      => -2,
                                     diagonal   => -1,
                                    );
    sub _NumSeq_Delta_dSumAbs_min {
      my ($self) = @_;
      return $_NumSeq_Delta_dSumAbs_min{$self->{'align'}};
    }
  }
  {
    my %_NumSeq_Delta_dSumAbs_max = (triangular => 2,
                                     left       => 2,
                                     right      => 2,
                                     diagonal   => 1,
                                    );
    sub _NumSeq_Delta_dSumAbs_max {
      my ($self) = @_;
      return $_NumSeq_Delta_dSumAbs_max{$self->{'align'}};
    }
  }

  sub _NumSeq_Delta_dAbsDiff_min { return $_[0]->ddiffxy_minimum; }
  sub _NumSeq_Delta_dAbsDiff_max { return $_[0]->ddiffxy_maximum; }

  use constant _NumSeq_Delta_dTRadius_min => -2;
  sub _NumSeq_Delta_dTRadius_max {
    my ($self) = @_;
    return ($self->{'align'} eq 'diagonal' ? sqrt(3) : 2);
  }
  use constant _NumSeq_dTRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_DSquared_min => 2;
  use constant _NumSeq_Delta_DSquared_max => 4;
  use constant _NumSeq_Delta_TDist_non_decreasing => 1;  # triangular
  use constant _NumSeq_Delta_TDSquared_max => 4;             # triangular
}
{ package Math::PlanePath::SierpinskiArrowheadCentres;
  *_NumSeq_Delta_dSumAbs_min
    = \&Math::PlanePath::SierpinskiArrowhead::_NumSeq_Delta_dSumAbs_min;
  *_NumSeq_Delta_dSumAbs_max
    = \&Math::PlanePath::SierpinskiArrowhead::_NumSeq_Delta_dSumAbs_max;

  sub _NumSeq_Delta_dAbsDiff_min { return $_[0]->ddiffxy_minimum; }
  sub _NumSeq_Delta_dAbsDiff_max { return $_[0]->ddiffxy_maximum; }

  use constant _NumSeq_Delta_dTRadius_min => -2;
  sub _NumSeq_Delta_dTRadius_max {
    my ($self) = @_;
    return ($self->{'align'} eq 'diagonal' ? sqrt(3) : 2);
  }
  use constant _NumSeq_dTRadius_min_is_infimum => 1;

  sub _NumSeq_Delta_dDSquared_min {
    my ($self) = @_;
    return ($self->{'align'} eq 'triangular' ? 2 : 1);
  }
  sub _NumSeq_Delta_dDSquared_max {
    my ($self) = @_;
    return ($self->{'align'} eq 'triangular' ? 4 : 2);
  }
}

{ package Math::PlanePath::DragonCurve;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_dRadius_min => -1;
  use constant _NumSeq_Delta_dRadius_max => 1;

  use constant _NumSeq_Delta_dTRadius_min => - sqrt(3);
  use constant _NumSeq_Delta_dTRadius_max => sqrt(3);

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;

  use constant _NumSeq_Delta_oeis_anum =>
    {
     'arms=1' =>
     { AbsdX => 'A059841', # 1,0 repeating
       AbsdY => 'A000035', # 0,1 repeating
       Dir4  => 'A246960', # direction
       # OEIS-Other: A059841 planepath=DragonCurve delta_type=AbsdX
       # OEIS-Other: A000035 planepath=DragonCurve delta_type=AbsdY
       # OEIS-Catalogue: A246960 planepath=DragonCurve delta_type=Dir4
     },
     'arms=3' =>
     { AbsdX => 'A059841', # 1,0 repeating
       AbsdY => 'A000035', # 0,1 repeating
       # OEIS-Other: A059841 planepath=DragonCurve,arms=3 delta_type=AbsdX
       # OEIS-Other: A000035 planepath=DragonCurve,arms=3 delta_type=AbsdY
     },
     # 'arms=2' => $href,# 0,1,1,0
     'arms=4' =>
     { AbsdY => 'A165211', # 0,1,0,1, 1,0,1,0, repeating
       # OEIS-Other: A165211 planepath=DragonCurve,arms=4 delta_type=AbsdY
     },
    };
}
{ package Math::PlanePath::DragonRounded;
  use constant _NumSeq_Delta_dSumAbs_min => -2;
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  # dRadius infimum/supremum because diagonals only occur on "odd" diagonals,
  # never on the X=Y diagonal, so never have step by sqrt(2) exactly
  use constant _NumSeq_Delta_dRadius_min => -sqrt(2);
  use constant _NumSeq_Delta_dRadius_max => sqrt(2);
  use constant _NumSeq_dRadius_min_is_infimum => 1;
  use constant _NumSeq_dRadius_max_is_supremum => 1;

  use constant _NumSeq_Delta_dTRadius_min => -2;
  use constant _NumSeq_Delta_dTRadius_max => 2;
  use constant _NumSeq_dTRadius_min_is_infimum => 1;
  use constant _NumSeq_dTRadius_max_is_supremum => 1;

  use constant _NumSeq_Delta_DSquared_max => 2;

  use constant _NumSeq_Delta_oeis_anum =>
    { 'arms=1' =>
      { AbsdX => 'A152822', # 1,1,0,1 repeating
        AbsdY => 'A166486', # 0,1,1,1 repeating
        # OEIS-Catalogue: A166486 planepath=DragonRounded delta_type=AbsdY
        # OEIS-Catalogue: A152822 planepath=DragonRounded delta_type=AbsdX
      },
    };
}
{ package Math::PlanePath::DragonMidpoint;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_dRadius_min => -1; # at N=1534
  use constant _NumSeq_Delta_dRadius_max => 1;  # at N=0
  use constant _NumSeq_Delta_dRadius_min_n => 1534;

  use constant _NumSeq_Delta_dTRadius_min => - sqrt(3);
  use constant _NumSeq_Delta_dTRadius_max => sqrt(3);

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;

  # use constant _NumSeq_Delta_oeis_anum =>
  # '' =>
  # {
  #  # Not quite, has n=N+2 and extra initial 0 at n=1
  #  # AbsdY => 'A073089',
  # },
}
{ package Math::PlanePath::R5DragonCurve;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_dRadius_min => -1;
  use constant _NumSeq_Delta_dRadius_max => 1;

  use constant _NumSeq_Delta_dTRadius_min => - sqrt(3);
  use constant _NumSeq_Delta_dTRadius_max => sqrt(3);

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;

  use constant _NumSeq_Delta_oeis_anum =>
    { do {
      my $href =
        { AbsdX => 'A059841', # 1,0 repeating
          AbsdY => 'A000035', # 0,1 repeating
        };
      ('arms=1' => $href,
       'arms=3' => $href,
      );
      # OEIS-Other: A059841 planepath=R5DragonCurve delta_type=AbsdX
      # OEIS-Other: A000035 planepath=R5DragonCurve delta_type=AbsdY
      # OEIS-Other: A059841 planepath=R5DragonCurve,arms=3 delta_type=AbsdX
      # OEIS-Other: A000035 planepath=R5DragonCurve,arms=3 delta_type=AbsdY
    },
      'arms=4' =>
      { AbsdY => 'A165211', # 0,1,0,1, 1,0,1,0, repeating
        # OEIS-Other: A165211 planepath=R5DragonCurve,arms=4 delta_type=AbsdY
      },
    };
}
{ package Math::PlanePath::R5DragonMidpoint;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_dRadius_min => -1;
  use constant _NumSeq_Delta_dRadius_max => 1;

  use constant _NumSeq_Delta_dTRadius_min => - sqrt(3);  # at N=11 on Y axis dY=-1
  use constant _NumSeq_Delta_dTRadius_max => sqrt(3);    # at N=1348 on Y neg axis dY=-1
  use constant _NumSeq_Delta_dTRadius_max_n => 1348;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;
}
{ package Math::PlanePath::CCurve;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;

  use constant _NumSeq_Delta_oeis_anum =>
    { '' =>
      { AbsdX => 'A010059', # Thue-Morse binary parity
        AbsdY => 'A010060', # 1-bit count mod 2, DigitSumModulo Thue-Morse
        Dir4  => 'A179868', # 1-bit count mod 4, DigitSumModulo
        # OEIS-Catalogue: A010059 planepath=CCurve delta_type=AbsdX
        # OEIS-Other:     A010060 planepath=CCurve delta_type=AbsdY
        # OEIS-Other:     A179868 planepath=CCurve delta_type=Dir4
      },
    };
}
{ package Math::PlanePath::AlternatePaper;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_dRadius_min => -1;
  use constant _NumSeq_Delta_dRadius_max => 1;
  use constant _NumSeq_dRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;

  use constant _NumSeq_Delta_oeis_anum =>
    { 'arms=1' =>
      { AbsdY    => 'A000035', # 0,1 repeating
        dSum     => 'A020985', # GRS
        dSumAbs  => 'A020985', # GRS
        # OEIS-Other: A000035 planepath=AlternatePaper delta_type=AbsdY
        # OEIS-Other: A020985 planepath=AlternatePaper delta_type=dSum
        # OEIS-Other: A020985 planepath=AlternatePaper delta_type=dSumAbs

        # dX_every_second_point_skipping_zeros => 'A020985', # GRS
        #  # ie. Math::NumSeq::GolayRudinShapiro
      },

      'arms=4' =>
      { dSum  => 'A020985', # GRS
        # OEIS-Other: A020985 planepath=AlternatePaper,arms=4 delta_type=dSum
      },
    };
}
{ package Math::PlanePath::AlternatePaperMidpoint;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;
}
{ package Math::PlanePath::TerdragonCurve;
  use constant _NumSeq_Delta_dSumAbs_min => -2;
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  use constant _NumSeq_Delta_dRadius_min => -2;  # at N=157
  use constant _NumSeq_Delta_dRadius_max => 2;   # at N=0

  use constant _NumSeq_Delta_dTRadius_min => -2;
  use constant _NumSeq_Delta_dTRadius_max => 2;

  use constant _NumSeq_Delta_TDir6_integer => 1;

  use constant _NumSeq_Delta_DSquared_min => 2;
  use constant _NumSeq_Delta_DSquared_max => 4;
  use constant _NumSeq_Delta_TDist_non_decreasing => 1;  # triangular
  use constant _NumSeq_Delta_TDSquared_max => 4;  # triangular
}
{ package Math::PlanePath::TerdragonRounded;
  use constant _NumSeq_Delta_dSumAbs_min => -2;
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  use constant _NumSeq_Delta_dRadius_min => -2;  # at N=314
  use constant _NumSeq_Delta_dRadius_max => 2;   # at N=0

  use constant _NumSeq_Delta_dTRadius_min => -2;
  use constant _NumSeq_Delta_dTRadius_max => 2;

  use constant _NumSeq_Delta_TDir6_integer => 1;

  use constant _NumSeq_Delta_DSquared_min => 2;
  use constant _NumSeq_Delta_DSquared_max => 4;
  use constant _NumSeq_Delta_TDist_non_decreasing => 1;  # triangular
  use constant _NumSeq_Delta_TDSquared_max => 4;         # triangular
}
{ package Math::PlanePath::TerdragonMidpoint;
  use constant _NumSeq_Delta_dSumAbs_min => -2;
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  # dRadius infimum/supremum because horizontals only occur on Y odd, so
  # never have step by 2 exactly along X axis
  use constant _NumSeq_Delta_dRadius_min => -2;
  use constant _NumSeq_Delta_dRadius_max => 2;
  use constant _NumSeq_dRadius_min_is_infimum => 1;
  use constant _NumSeq_dRadius_max_is_supremum => 1;

  use constant _NumSeq_Delta_dTRadius_min => -2;
  use constant _NumSeq_Delta_dTRadius_max => 2;
  use constant _NumSeq_dTRadius_min_is_infimum => 1;
  use constant _NumSeq_dTRadius_max_is_supremum => 1;

  use constant _NumSeq_Delta_TDir6_integer => 1;

  use constant _NumSeq_Delta_DSquared_min => 2;
  use constant _NumSeq_Delta_DSquared_max => 4;
  use constant _NumSeq_Delta_TDist_non_decreasing => 1;  # triangular
  use constant _NumSeq_Delta_TDSquared_max => 4;             # triangular
}
{ package Math::PlanePath::AlternateTerdragon;
  use constant _NumSeq_Delta_dSumAbs_min => -2;
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  use constant _NumSeq_Delta_dRadius_min => -2;  # at N=...?
  use constant _NumSeq_Delta_dRadius_max => 2;   # at N=0

  use constant _NumSeq_Delta_dTRadius_min => -2;
  use constant _NumSeq_Delta_dTRadius_max => 2;

  use constant _NumSeq_Delta_TDir6_integer => 1;

  use constant _NumSeq_Delta_DSquared_min => 2;
  use constant _NumSeq_Delta_DSquared_max => 4;
  use constant _NumSeq_Delta_TDist_non_decreasing => 1;  # triangular
  use constant _NumSeq_Delta_TDSquared_max => 4;  # triangular
}
{ package Math::PlanePath::ComplexPlus;
  use constant _NumSeq_Dir4_max_is_supremum => 1;
  use constant _NumSeq_Delta_Dir4_integer => 0;
}
{ package Math::PlanePath::ComplexMinus;
  use constant _NumSeq_Dir4_max_is_supremum => 1;
  use constant _NumSeq_Delta_Dir4_integer => 0;
}
{ package Math::PlanePath::ComplexRevolving;
  use constant _NumSeq_Dir4_max_is_supremum => 1;
  use constant _NumSeq_Delta_Dir4_integer => 0;
}
{ package Math::PlanePath::Rows;
  sub _NumSeq_Delta_dX_non_decreasing {
    my ($self) = @_;
    return ($self->{'width'} <= 1
           ? 1  # single column only, dX=0 always
           : 0);
  }
  sub _NumSeq_Delta_AbsdX_non_decreasing {
    my ($self) = @_;
    return ($self->{'width'} <= 2); # 1 or 2 is constant 0 or 1
  }

  # abs(X-Y) move towards and then away from X=Y diagonal by +1 and -1 in row,
  # then at row end to Y axis goes
  #    from X=width-1, Y=k      AbsDiff = abs(k-(width-1))
  #    to   X=0,       Y=k+1    AbsDiff = k+1
  #    dAbsDiff = k+1 - abs(k-(width-1))
  #    when k>=width-1  dAbsDiff = k+1 - (k-(width-1))
  #                              = k+1 - k + (width-1)
  #                              = 1 + width-1
  #                              = width
  #    when k<=width-1  dAbsDiff = k+1 - ((width-1)-k)
  #                              = k+1 - (width-1) + k
  #                              = 2k+1 - width + 1
  #                              = 2k+2 - width
  #      at k=0       dAbsDiff = 2-width
  #      at k=width-1 dAbsDiff = 2*(width-1)+2 - width
  #                            = 2*width - 2 + 2 - width
  #                            = width
  #    minimum = 2-width or -1
  #    maximum = width
  #
  sub _NumSeq_Delta_dAbsDiff_min {
    my ($self) = @_;
    if ($self->{'width'} == 1) { return 1; } # constant dAbsDiff=1
    return List::Util::min(-1, 2 - $self->{'width'});
  }
  sub _NumSeq_Delta_dAbsDiff_max {
    my ($self) = @_;
    return $self->{'width'};
  }

  *_NumSeq_Delta_dY_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_AbsdY_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_dSum_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_Dir4_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_TDir6_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_Dist_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_TDist_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_dDiffXY_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_dDiffYX_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_dAbsDiff_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_dSumAbs_non_decreasing # width=1 is dSumAbs=constant
    = \&_NumSeq_Delta_dX_non_decreasing;

  sub _NumSeq_Delta_dRadius_min {
    my ($self) = @_;
    return 2 - $self->{'width'};
  }
  use constant _NumSeq_Delta_dRadius_max => 1;  # at N=1
  *_NumSeq_Delta_dRadius_integer = \&_NumSeq_Delta_dX_non_decreasing;

  sub _NumSeq_Delta_dRSquared_min {
    my ($self) = @_;
    return ($self->{'width'} == 1 ? 1
            : $self->{'width'} == 2 ? 0
            : undef);
  }
  use constant _NumSeq_Delta_dRSquared_integer => 1;
  *_NumSeq_Delta_dRSquared_increasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_dRSquared_increasing = \&_NumSeq_Delta_dX_non_decreasing;

  # end of first row X=w-1,Y=0  TRadius = w-1
  # start next       X=0,  Y=1  TRadius = sqrt(3)
  # dTRadius = sqrt(3)-(w-1)
  # also horizontal 0 which is minimum for width=2
  #
  # maximum prev row to next row dY=+1 is dTRadius -> sqrt(3)
  #
  sub _NumSeq_Delta_dTRadius_min {
    my ($self) = @_;
    my $width = $self->{'width'};
    return ($width == 2 ? 0
            : sqrt(3)+1 - $width);
  }
  sub _NumSeq_dTRadius_min_is_infimum {
    my ($self) = @_;
    my $width = $self->{'width'};
    return ($width == 2 ? 1  # infimum
            : 0);            # exact
  }
  use constant _NumSeq_Delta_dTRadius_max => sqrt(3);
  use constant _NumSeq_dTRadius_max_is_supremum => 1;

  # end of row X=w-1,Y    TRsq     = (w-1)^2 + 3Y^2
  # start next X=0,  Y+1  TRsqNext = 3(Y+1)^2
  # dTRsq = 3Y^2 + 6Y + 3 - (w-1)^2 - 3Y^2
  #       = 6Y+3 - (w-1)^2
  # minimum at Y=0 is  3-(w-1)^2 = 2+2w-w^2
  #    w=1 min=3
  #    w=2 min=2
  #    w=3 min=-1
  # also if w>=2 then 0,0 to 1,0 is dTRsq=1
  sub _NumSeq_Delta_dTRSquared_min {
    my ($self) = @_;
    my $width = $self->{'width'};
    return ($width == 2 ? 1  # N=Nstart 0,0 to 1,0
            : (2-$width)*$width+2);
  }
  *_NumSeq_Delta_dTRSquared_increasing = \&_NumSeq_Delta_dX_non_decreasing;

  *_NumSeq_Delta_Dir4_integer = \&_NumSeq_Delta_dX_non_decreasing;
  sub _NumSeq_Delta_TDir6_integer {
    my ($self) = @_;
    return ($self->{'width'} == 2); # E and NW
  }

  use constant _NumSeq_Delta_oeis_anum =>
    { 'n_start=1,width=1' =>
      { dX   => 'A000004', # all zeros, X=0 always
        dY   => 'A000012', # all 1s
        Dir4 => 'A000012', # all 1s, North
        # OEIS-Other: A000004 planepath=Rows,width=1 delta_type=dX
        # OEIS-Other: A000012 planepath=Rows,width=1 delta_type=dY
        # OEIS-Other: A000012 planepath=Rows,width=1 delta_type=Dir4
      },
      'n_start=0,width=2' =>
      { dX        => 'A033999', # 1,-1 repeating, OFFSET=0
        dRSquared => 'A124625', # 1,0,1,2,1,4,1,6,1,8 ones and evens OFFSET=0
        TDir6     => 'A010673', # 0,2 repeating, OFFSET=0
        # catalogued here pending perhaps simpler implementation elsewhere
        # OEIS-Catalogue: A033999 planepath=Rows,width=2,n_start=0 delta_type=dX
        # OEIS-Catalogue: A124625 planepath=Rows,width=2,n_start=0 delta_type=dRSquared
        # OEIS-Catalogue: A010673 planepath=Rows,width=2,n_start=0 delta_type=TDir6
      },

      'n_start=1,width=3' =>
      { dX   => 'A061347', # 1,1,-2 repeating OFFSET=1
        # OEIS-Catalogue: A061347 planepath=Rows,width=3 delta_type=dX
      },
      'n_start=0,width=3' =>
      { dSum    => 'A131561', # 1,1,-1 repeating
        dSumAbs => 'A131561', # same
        # OEIS-Catalogue: A131561 planepath=Rows,width=3,n_start=0 delta_type=dSum
        # OEIS-Other:     A131561 planepath=Rows,width=3,n_start=0 delta_type=dSumAbs

      # dY   => 'A022003', # 0,0,1 repeating, decimal of 1/999
      # # OEIS-Other: A022003 planepath=Rows,width=3 delta_type=dY
      },
      'n_start=1,width=4' =>
      { dY   => 'A011765', # 0,0,0,1 repeating, starting OFFSET=1
        # OEIS-Other: A011765 planepath=Rows,width=4 delta_type=dY
      },
      # OFFSET
      # 'n_start=1,width=6' =>
      # { dY   => 'A172051', # 0,0,0,0,0,1 repeating decimal 1/999999
      #   # OEIS-Other: A172051 planepath=Rows,width=6 delta_type=dY
      # },
    };
}

{ package Math::PlanePath::Columns;
  sub _NumSeq_Delta_AbsdY_non_decreasing {
    my ($self) = @_;
    return ($self->{'height'} <= 2); # 1 or 2 is constant
  }

  # same as Rows dAbsDiff
  sub _NumSeq_Delta_dAbsDiff_min {
    my ($self) = @_;
    if ($self->{'height'} == 1) { return 1; } # constant dAbsDiff=1
    return List::Util::min(-1, 2 - $self->{'height'});
  }
  sub _NumSeq_Delta_dAbsDiff_max {
    my ($self) = @_;
    return $self->{'height'};
  }

  # same as Rows
  sub _NumSeq_Delta_dRadius_min {
    my ($self) = @_;
    return 2 - $self->{'height'};
  }
  use constant _NumSeq_Delta_dRadius_max => 1;  # at N=1
  *_NumSeq_Delta_dRadius_integer = \&_NumSeq_Delta_dX_non_decreasing;

  sub _NumSeq_Delta_dRSquared_min {
    my ($self) = @_;
    return ($self->{'height'} == 1 ? 1
            : $self->{'height'} == 2 ? 0
            : undef);
  }
  use constant _NumSeq_Delta_dRSquared_integer => 1;
  *_NumSeq_Delta_dRSquared_increasing = \&_NumSeq_Delta_dX_non_decreasing;

  # end of first column X=0,Y=h-1  TRadius = sqrt(0 + 3*(h-1)^2)
  # start next          X=1,Y=0    TRadius = sqrt(1 + 0)
  # min dTRadius = 1 - sqrt(3)*(h-1)
  #              = (1+sqrt(3)) - h*sqrt(3)
  sub _NumSeq_Delta_dTRadius_min {
    my ($self) = @_;
    my $height = $self->{'height'};
    return ($height == 1 ? 1          # constant increment 1
            : (-sqrt(3))*$height + (1+sqrt(3)));
  }
  sub _NumSeq_Delta_dTRadius_max {
    my ($self) = @_;
    return ($self->{'height'} == 1 ? 1          # constant increment 1
            : sqrt(3));
  }
  *_NumSeq_Delta_dTRadius_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_dTRadius_integer        = \&_NumSeq_Delta_dX_non_decreasing;

  # end of column X,  Y=h-1  TRsq     = X^2 + 3(h-1)^2
  # start next    X+1,Y=0    TRsqNext = (X+1)^2
  # dTRsq = 2X+1 - 3(h-1)^2
  # minimum at X=0 is  1-3*(h-1)^2 = -3*h^2 + 6h - 2
  #    h=1 min=1
  #    h=2 min=-2
  sub _NumSeq_Delta_dTRSquared_min {
    my ($self) = @_;
    my $height = $self->{'height'};
    return (-3*$height + 6)*$height - 2;
  }
  *_NumSeq_Delta_dTRSquared_increasing = \&_NumSeq_Delta_dX_non_decreasing;

  sub _NumSeq_Delta_TDSquared_min {
    my ($self) = @_;
    return ($self->{'height'} == 1
            ? 1    # horizontal
            : 3);  # vertical
  }

  sub _NumSeq_Delta_dX_non_decreasing {
    my ($self) = @_;
    return ($self->{'height'} == 1); # constant when column only
  }
  *_NumSeq_Delta_dY_non_decreasing      = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_AbsdX_non_decreasing   = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_dSum_non_decreasing    = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_dDiffXY_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_dDiffYX_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_dAbsDiff_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_dSumAbs_non_decreasing # height=1 is dSumAbs=constant
    = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_Dir4_non_decreasing    = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_TDir6_non_decreasing   = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_Dist_non_decreasing    = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_TDist_non_decreasing   = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_Dir4_integer           = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_TDir6_integer          = \&_NumSeq_Delta_dX_non_decreasing;

  use constant _NumSeq_Delta_oeis_anum =>
    { 'n_start=1,height=1' =>
      { dX     => 'A000012', # all 1s
        dY     => 'A000004', # all zeros, Y=0 always
        Dir4   => 'A000004', # all zeros, East
        TDir6  => 'A000004', # all zeros, East
        # OEIS-Other: A000012 planepath=Columns,height=1 delta_type=dX
        # OEIS-Other: A000004 planepath=Columns,height=1 delta_type=dY
        # OEIS-Other: A000004 planepath=Columns,height=1 delta_type=Dir4
        # OEIS-Other: A000004 planepath=Columns,height=1 delta_type=TDir6
      },

      'n_start=0,height=2' =>
      { dY        => 'A033999', # 1,-1 repeating
        dSum      => 'A059841', # 1,0 repeating, 1-n mod 2
        dSumAbs   => 'A059841', # same
        dRSquared => 'A124625', # 1,0,1,2,1,4,1,6,1,8 ones and evens OFFSET=0
        # OEIS-Other: A033999 planepath=Columns,height=2,n_start=0 delta_type=dY
        # OEIS-Other: A059841 planepath=Columns,height=2,n_start=0 delta_type=dSum
        # OEIS-Other: A059841 planepath=Columns,height=2,n_start=0 delta_type=dSumAbs
        # OEIS-Other: A124625 planepath=Columns,height=2,n_start=0 delta_type=dRSquared
      },

      'n_start=0,height=3' =>
      { dSum    => 'A131561', # 1,1,-1 repeating
        dSumAbs => 'A131561', # same
        # OEIS-Other: A131561 planepath=Columns,height=3,n_start=0 delta_type=dSum
        # OEIS-Other: A131561 planepath=Columns,height=3,n_start=0 delta_type=dSumAbs
      },
      'n_start=1,height=3' =>
      { dY   => 'A061347', # 1,1,-2 repeating
        # OEIS-Other: A061347 planepath=Columns,height=3 delta_type=dY

        # dX   => 'A022003', # 0,0,1 repeating from frac 1/999
        # # OEIS-Other: A022003 planepath=Columns,height=3 delta_type=dX
      },
      'n_start=1,height=4' =>
      { dX   => 'A011765', # 0,0,0,1 repeating, starting OFFSET=1
        # OEIS-Other: A011765 planepath=Columns,height=4 delta_type=dX
      },
      # OFFSET
      # 'n_start=1,height=6' =>
      # { dX   => 'A172051', # 0,0,0,1 repeating, starting n=0
      #   # OEIS-Other: A172051 planepath=Columns,height=6 delta_type=dX
      # },
    };
}

{ package Math::PlanePath::Diagonals;
  #       -2
  #           |  0          dSumAbs
  #      \    |    /
  #       \  /|\  /
  #        \/ | \/  0
  #        /\ | /\
  #       /  \|/  \
  #     ------+--------
  #           |\  /
  #           | \/ +2
  #           | /\
  #           |/
  #           |
  # within diagonal from X=Xstart+p   Y=Ystart+k-p
  #                   to X=Xstart+p+1 Y=Ystart+k-p-1
  # abs(Xstart+p+1)-abs(Xstart+p)
  # if X1=Xstart+p>=0 then X2=Xstart+p+1>=0
  #    dAbsX = (Xstart+p+1)-(Xstart+p) = +1
  # if X1=Xstart+p<0 then X2=Xstart+p+1<=0
  #    dAbsX = -(Xstart+p+1) - (-(Xstart+p)) = -1
  #    X1<0 occurs when Xstart<=-1
  #
  # abs(Ystart+k-p-1)-abs(Ystart+k-p)
  # if Y2=Ystart+k-p-1>=0 then Y1=Ystart+k-p>=0
  #    dAbsY = (Ystart+k-p-1)-(Ystart+k-p) = -1
  # if Y2=Ystart+k-p-1<0 then Y1=Ystart+k-p<=0
  #    dAbsY = -(Ystart+k-p-1) - (-(Ystart+k-p)) = +1
  #    Y2<0 occurs when Ystart<=-1
  #
  # within diagonal dAbsX = (Xstart>=0 ?  1 : -1)
  #                 dAbsY = (Ystart>=0 ? -1 :  1)
  # is dSumAbs_min =
  #
  # towards or away X=Y is dSumAbs=+/-2
  # end of diagonal X=Xstart+k Y=Ystart
  #             to  X=Xstart   Y=Ystart+k+1
  # if Xstart>=0 and Ystart>=0 then dSumAbs=dSum=1 always
  #
  # if Xstart<0 then from abs(X) = -(Xstart+k)
  #                    to abs(X) = -Xstart
  # dSumAbs = (-Xstart + Ystart+k+1) - (-(Xstart+k) + Ystart)
  #         = 2*k+1
  # until (Xstart+k)>=0 and then
  # dSumAbs = (-Xstart + Ystart+k+1) - (Xstart+k + Ystart)
  #         = -2*Xstart+1 which is >0
  # so dSumAbs_max = -2*Xstart+1
  #
  # if Ystart<0 then from abs(Y) = -Ystart
  #                    to abs(Y) = -(Ystart+k+1)
  # dSumAbs = (Xstart + -(Ystart+k+1)) - (Xstart+k + -Ystart)
  #         = -2*k-1
  # until (Ystart+k+1)>=0 and then
  # dSumAbs = (Xstart + (Ystart+k+1)) - (Xstart+k + -Ystart)
  #         = 2*Ystart+1 which is <0
  # so dSumAbs_min = 2*Ystart+1
  #
  sub _NumSeq_Delta_dSumAbs_min {
    my ($self) = @_;
    my $x_start = $self->{'x_start'};
    my $y_start = $self->{'y_start'};
    if ($self->{'direction'} eq 'up') {
      ($x_start,$y_start) = ($y_start,$x_start);
    }
    return List::Util::min(($x_start < 0 ? -2 : 0),
                           2*($y_start-List::Util::min($x_start,0)) + 1);
  }
  sub _NumSeq_Delta_dSumAbs_max {
    my ($self) = @_;
    my $x_start = $self->{'x_start'};
    my $y_start = $self->{'y_start'};
    if ($self->{'direction'} eq 'up') {
      ($x_start,$y_start) = ($y_start,$x_start);
    }
    return List::Util::max(($y_start < 0 ? 2 : 1),
                           -2*($x_start-List::Util::min($y_start,0)) + 1);
  }


  # step 2 along opp diagonal, except end of row jumping back up goes
  #
  #           | T             step = 2*(F-Xstart)+1
  #           | \     X=Y     F = Ystart
  #           | |\   /        eg. Xstart=20 Ystart=10
  #           | | \ /         step = 2*(10-20)+1 = -19
  #           | +--F
  #           |   /
  #           |  /
  #           | /
  #           |/
  #           +--------
  sub _NumSeq_Delta_dAbsDiff_min {
    my ($self) = @_;
    return List::Util::min (-2, # towards X=Y diagonal
                            ($self->{'direction'} eq 'down' ? 2 : -2)
                            * ($self->{'y_start'} - $self->{'x_start'}) + 1);
  }
  sub _NumSeq_Delta_dAbsDiff_max {
    my ($self) = @_;
    return List::Util::max (2,  # away from X=Y diagonal
                            ($self->{'direction'} eq 'down' ? 2 : -2)
                            * ($self->{'y_start'} - $self->{'x_start'}) + 1);

  }

  # *      R1=sqrt(X^2+Y^2)
  #  \     R2=sqrt((X+1)^2+(Y-1)^2)
  #   \    R1-R2 -> 1
  #    *
  #
  use constant _NumSeq_Delta_dRadius_min => -1;
  use constant _NumSeq_Delta_dRadius_max => 1;

  # *      R1=X^2+Y^2
  #  \     R2=(X+1)^2+(Y-1)^2
  #   \    R2-R1 = X^2+2X+1 - (Y^2-2Y+1) - X^2 - Y^2
  #    *         = 2X+1 - 2*Y^2 + 2Y - 1     unbounded
  #
  # use constant _NumSeq_Delta_dRSquared_min => undef;
  # use constant _NumSeq_Delta_dRSquared_max => undef;

  use constant _NumSeq_Delta_Dir4_integer => 0; # diagonals

  sub _NumSeq_Delta_TDSquared_min {
    my ($self) = @_;
    return ($self->{'direction'} eq 'down'
            ? 3      # N=1 dX=0,dY=1 vertical
            : 1);    # N=1 dX=0,dY=1 horizontal
  }

  use constant _NumSeq_Delta_oeis_anum =>
    { 'direction=down,n_start=1,x_start=0,y_start=0' =>
      { dY    => 'A127949',
        # OEIS-Catalogue: A127949 planepath=Diagonals delta_type=dY
      },
      'direction=up,n_start=1,x_start=0,y_start=0' =>
      { dX    => 'A127949',
        # OEIS-Other: A127949 planepath=Diagonals,direction=up delta_type=dX
      },

      'direction=down,n_start=0,x_start=0,y_start=0' =>
      { AbsdY   => 'A051340',
        dSum    => 'A023531', # characteristic "1" at triangulars
        dSumAbs => 'A023531', # same
        # OEIS-Catalogue: A051340 planepath=Diagonals,n_start=0 delta_type=AbsdY
        # OEIS-Other:     A023531 planepath=Diagonals,n_start=0 delta_type=dSum
        # OEIS-Other:     A023531 planepath=Diagonals,n_start=0 delta_type=dSumAbs
      },
      'direction=up,n_start=0,x_start=0,y_start=0' =>
      { AbsdX => 'A051340',
        dSum    => 'A023531', # characteristic "1" at triangulars
        dSumAbs => 'A023531', # same
        # OEIS-Other: A051340 planepath=Diagonals,direction=up,n_start=0 delta_type=AbsdX
        # OEIS-Other: A023531 planepath=Diagonals,direction=up,n_start=0 delta_type=dSum
        # OEIS-Other: A023531 planepath=Diagonals,direction=up,n_start=0 delta_type=dSumAbs

        # Almost AbsdY=>'A051340' too, but path starts initial 0,1,1 whereas
        # A051340 starts 1,1,2
      },
    };
}
{ package Math::PlanePath::DiagonalsAlternating;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;
  use constant _NumSeq_Delta_DSquared_max => 2;

  use constant _NumSeq_Delta_oeis_anum =>
    { 'n_start=0' =>
      { dSum    => 'A023531', # characteristic "1" at triangulars
        dSumAbs => 'A023531', # same
        # OEIS-Other: A023531 planepath=DiagonalsAlternating,n_start=0 delta_type=dSum
        # OEIS-Other: A023531 planepath=DiagonalsAlternating,n_start=0 delta_type=dSumAbs
      },
    };
}
{ package Math::PlanePath::DiagonalsOctant;

  sub _NumSeq_Delta_dAbsDiff_min {
    my ($self) = @_;
    return ($self->{'direction'} eq 'down'
            ? -2      # "down"
            : undef); # "up"
  }
  sub _NumSeq_Delta_dAbsDiff_max {
    my ($self) = @_;
    return ($self->{'direction'} eq 'down'
            ? undef   # "down"
            : 2);     # "up"
  }

  sub _NumSeq_Delta_TDSquared_min {
    my ($self) = @_;
    return ($self->{'direction'} eq 'down'
            ? 3      # N=1 dX=0,dY=1 vertical
            : 1);    # N=1 dX=0,dY=1 horizontal
  }
}
{ package Math::PlanePath::MPeaks;
  use constant _NumSeq_Delta_dSumAbs_min => -2;
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_dRadius_min => -sqrt(2);
  use constant _NumSeq_Delta_dRadius_max => sqrt(2);

  use constant _NumSeq_Delta_Dir4_integer => 0; # diagonals
  use constant _NumSeq_Delta_TDir6_integer => 0; # verticals
  use constant _NumSeq_Delta_TDSquared_min => 3; # vertical
}
{ package Math::PlanePath::Staircase;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;
  use constant _NumSeq_Delta_dTRadius_min => - sqrt(3);
  use constant _NumSeq_Delta_Dir4_integer => 0; # going back to Y axis
}
{ package Math::PlanePath::StaircaseAlternating;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  {
    my %_NumSeq_Delta_dAbsDiff_max = (jump   => 2,  # at endpoint
                                      square => 1); # always NSEW
    sub _NumSeq_Delta_dAbsDiff_max {
      my ($self) = @_;
      return $_NumSeq_Delta_dAbsDiff_max{$self->{'end_type'}};
    }
  }

  use constant _NumSeq_Delta_dTRadius_min => - sqrt(3);
  use constant _NumSeq_dTRadius_min_is_infimum => 1;
  {
    my %_NumSeq_Delta_dTRadius_max = (jump   => undef,
                                      square => sqrt(3));
    sub _NumSeq_Delta_dTRadius_max {
      my ($self) = @_;
      return $_NumSeq_Delta_dTRadius_max{$self->{'end_type'}};
    }
  }

  {
    my %DSquared_max = (jump   => 4,
                        square => 1);
    sub _NumSeq_Delta_DSquared_max {
      my ($self) = @_;
      return $DSquared_max{$self->{'end_type'}};
    }
  }
  {
    my %Dist_non_decreasing = (jump   => 0,
                               square => 1); # NSEW always
    sub _NumSeq_Delta_Dist_non_decreasing {
      my ($self) = @_;
      return $Dist_non_decreasing{$self->{'end_type'}};
    }
  }
  {
    my %TDSquared_max = (jump   => 12,
                         square => 3);
    sub _NumSeq_Delta_TDSquared_max {
      my ($self) = @_;
      return $TDSquared_max{$self->{'end_type'}};
    }
  }
}
{ package Math::PlanePath::Corner;

  # X=k+wider, Y=0 has abs(X-Y)=k+wider
  # X=0, Y=k+1     has abs(X-Y)=k+1
  # dAbsDiff = (k+1)-(k+wider)
  #          = 1-wider
  # and also dAbsDiff=-1 when going towards X=Y diagonal
  use List::Util;
  sub _NumSeq_Delta_dAbsDiff_min {
    my ($self) = @_;
    return List::Util::min(-1, 1-$self->{'wider'});
  }
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_dRadius_min => - sqrt(2);
  use constant _NumSeq_Delta_dRadius_max => 1;

  use constant _NumSeq_Delta_Dir4_integer => 0; # between gnomons

  # use constant _NumSeq_Delta_oeis_anum =>
  #   { 'wider=0,n_start=0' =>
  #     { dSumAbs => 'A000012',   # all ones, OFFSET=0
  #       # OEIS-Other: A000012 planepath=Corner delta_type=dSumAbs
  #     },
  #   };
}
{ package Math::PlanePath::PyramidRows;
  sub _NumSeq_Delta__step_is_0 {
    my ($self) = @_;
    return ($self->{'step'} == 0); # constant when column only
  }
  *_NumSeq_Delta_dSum_non_decreasing = \&_NumSeq_Delta__step_is_0; # constant when column only

  # align=right
  #   X>=0 so SumAbs=Sum
  #   within row X increasing dSum=1
  #   end row decrease by big
  #   minimum = undef
  #   maximum = 1
  #
  # align=left
  #   within dSumAbs=-1 towards Y axis then dSumAbs=1 away
  #   end row X=0,Y=k              SumAbs=k
  #        to X=-step*(k+1),Y=k+1  SumAbs=step*(k+1) + (k+1)
  #   dSumAbs = step*(k+1) + (k+1) - k
  #           = step*k + step + k + 1 - k
  #           = step*(k+1) + 1    big positive
  #   minimum = -1
  #   maximum = undef
  #
  # align=centre, step=even
  #   within dSumAbs=-1 towards Y axis then dSumAbs=1 away
  #   end row X=k*step/2, Y=k        SumAbs=k*step/2 + k
  #        to X=-step/2*(k+1),Y=k+1  SumAbs=step/2*(k+1) + k+1
  #   dSumAbs = step/2*(k+1) + k+1 - (k*step/2 + k)
  #           = step/2*(k+1) + k+1 - k*step/2 - k
  #           = step/2*(k+1) +1 - k*step/2
  #           = step/2 +1
  #   minimum = -1
  #   maximum = step/2 +1
  #
  # align=centre, step=odd
  #   f=floor(step/2) c=ceil(step/2)=f+1
  #   within dSumAbs=-1 towards Y axis then dSumAbs=1 away
  #   end row X=k*c, Y=k         SumAbs=k*c + k
  #        to X=-f*(k+1),Y=k+1  SumAbs=f*(k+1) + k+1
  #   dSumAbs = f*(k+1) + k+1 - (k*c + k)
  #           = f*(k+1) + k+1 - k*(f+1) - k
  #           = f*k +f + k+1 - k*f - k - k
  #           = f + 1 - k
  #           = (step+1)/2 - k
  #   minimum = big negative
  #   maximum = floor(step/2) + 1   when k=0 first end row
  #
  sub _NumSeq_Delta_dSumAbs_min {
    my ($self) = @_;
    if ($self->{'step'} == 0) {
      return 1;         # step=0 constant dSumAbs=1
    }
    if ($self->{'align'} eq 'left'
        || ($self->{'align'} eq 'centre' && $self->{'step'} % 2 == 0)) {
      return -1;     # towards Y axis
    }
    return undef;  # big negatives
  }
  sub _NumSeq_Delta_dSumAbs_max {
    my ($self) = @_;
    if ($self->{'step'} == 0
        || $self->{'align'} eq 'right') {
      return 1;
    }
    if ($self->{'align'} eq 'centre') {
      return int($self->{'step'}/2) + 1;
    }
    return undef;
  }

  # abs(X-Y) move towards and then away from X=Y diagonal by +1 and -1 in row
  #
  # align=left
  #    towards X=Y diagonal so dAbsDiff=-1
  #    from X=0,Y=k               AbsDiff = k
  #    to   X=-(k+1)*step,Y=k+1   AbsDiff = k+1 - (-(k+1)*step)
  #    dAbsDiff = k+1 - (-(k+1)*step) - k
  #             = step*(k+1) + 1      big positive
  #
  # align=right
  #    step<=1 only towards X=Y diagonal dAbsDiff=-1
  #    step>=2 away from  X=Y diagonal   dAbsDiff=+1
  #    from X=k*step,Y=k   AbsDiff = k*step - k
  #    to   X=0,Y=k+1      AbsDiff = k+1
  #    dAbsDiff = k+1 - (k*step - k)
  #             = -(step-2)*k + 1
  #    step=1 dAbsDiff = k+1       big positive
  #    step=2 dAbsDiff = 1
  #    step=3 dAbsDiff = -k + 1    big negative
  #
  sub _NumSeq_Delta_dAbsDiff_min {
    my ($self) = @_;
    if ($self->{'step'} == 0) {      # constant N dY=1
      return 1;
    }
    if ($self->{'align'} eq 'right' && $self->{'step'} >= 3) {
      return undef;  # big negative
    }
    return -1;
  }
  sub _NumSeq_Delta_dAbsDiff_max {
    my ($self) = @_;
    if ($self->{'step'} == 0) {      # constant N dY=1
      return 1;
    }
    if ($self->{'align'} eq 'right' && $self->{'step'} >= 2) {
      return 1;
    }
    return undef;
  }
  *_NumSeq_Delta_dAbsDiff_non_decreasing = \&_NumSeq_Delta__step_is_0;

  *_NumSeq_Delta_AbsdX_non_decreasing = \&_NumSeq_Delta__step_is_0;
  *_NumSeq_Delta_AbsdY_non_decreasing = \&_NumSeq_Delta__step_is_0;
  *_NumSeq_Delta_dDiffXY_non_decreasing = \&_NumSeq_Delta__step_is_0;
  *_NumSeq_Delta_dDiffYX_non_decreasing = \&_NumSeq_Delta__step_is_0;
  *_NumSeq_Delta_dSumAbs_non_decreasing = \&_NumSeq_Delta__step_is_0;

  sub _NumSeq_Delta_dRadius_min {
    my ($self) = @_;
    return ($self->{'step'} == 0 ? 1
            : $self->{'step'} == 1 ? undef
            : -1/sqrt(2));
  }
  sub _NumSeq_Delta_dRadius_max {
    my ($self) = @_;
    return ($self->{'step'} == 0 ? 1
            : sqrt(2));
  }
  *_NumSeq_Delta_dRadius_integer = \&_NumSeq_Delta__step_is_0;

  sub _NumSeq_Delta_dRSquared_min {
    my ($self) = @_;
    return ($self->{'step'} == 0 ? 1
            : undef);
  }
  sub _NumSeq_Delta_dRSquared_max {
    my ($self) = @_;
    return ($self->{'step'} == 0 ? undef
            : undef);
  }
  *_NumSeq_Delta_dRSquared_increasing = \&_NumSeq_Delta__step_is_0;

  sub _NumSeq_Delta_dTRadius_min {
    my ($self) = @_;
    return ($self->{'step'} == 0 ? sqrt(3)
            : $self->{'align'} eq 'centre' && $self->{'step'} % 2 == 0 ? - sqrt(3)
            : undef);
  }
  sub _NumSeq_Delta_dTRadius_max {
    my ($self) = @_;
    return ($self->{'step'} <= 1 ? sqrt(3)
            : $self->{'align'} eq 'centre' && $self->{'step'} % 2 == 1 ? 2
            # : $self->{'align'} eq 'centre' && $self->{'step'} % 2 == 0 ? 2
            : undef);
  }

  sub _NumSeq_Delta_dTRSquared_min {
    my ($self) = @_;
    return ($self->{'step'} == 0 ? 3   # step=0 vertical line
            : undef);
  }
  *_NumSeq_Delta_dTRSquared_increasing = \&_NumSeq_Delta__step_is_0;

  use constant _NumSeq_Delta_TDir6_integer => 0;

  sub _NumSeq_Delta_DSquared_max {
    my ($self) = @_;
    return ($self->{'step'} == 0
            ? 1    # X=0 vertical only
            : undef);
  }

  sub _NumSeq_Dir4_max_is_supremum {
    my ($self) = @_;
    return ($self->{'step'} == 0
            ? 0    # north only, exact
            : 1);  # supremum, west and 1 up
  }
  sub _NumSeq_Delta_Dir4_integer {
    my ($self) = @_;
    return ($self->{'step'} == 0
            ? 1    # North only, integer
            : 0);  # otherwise fraction
  }

  sub _NumSeq_Delta_dX_non_decreasing {
    my ($self) = @_;
    return ($self->{'step'} == 0);  # step=0 is dX=0,dY=1 always
  }
  *_NumSeq_Delta_dY_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_Dir4_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_TDir6_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_Dist_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;
  *_NumSeq_Delta_TDist_non_decreasing = \&_NumSeq_Delta_dX_non_decreasing;

  use constant _NumSeq_Delta_oeis_anum =>
    {
     # PyramidRows step=0 is trivial X=0,Y=N
     do {
       my $href = { dX    => 'A000004',  # all zeros, X=0 always
                    dY    => 'A000012',  # all 1s
                    Dir4  => 'A000012',  # all 1s, North
                  };
       ('step=0,align=centre,n_start=1' => $href,
        'step=0,align=right,n_start=1'  => $href,
        'step=0,align=left,n_start=1'   => $href,
       );

       # OEIS-Other: A000004 planepath=PyramidRows,step=0 delta_type=dX
       # OEIS-Other: A000012 planepath=PyramidRows,step=0 delta_type=dY
       # OEIS-Other: A000012 planepath=PyramidRows,step=0 delta_type=Dir4
     },

     # PyramidRows step=1
     do {   # n_start=1
       my $href = { dDiffYX  => 'A127949',
                    dAbsDiff => 'A127949',  # Y>=X so same as dDiffYX
                  };
       ('step=1,align=centre,n_start=1' => $href,
        'step=1,align=right,n_start=1'  => $href,
       );
       # OEIS-Other: A127949 planepath=PyramidRows,step=1 delta_type=dDiffYX
       # OEIS-Other: A127949 planepath=PyramidRows,step=1 delta_type=dAbsDiff
       # OEIS-Other: A127949 planepath=PyramidRows,step=1,align=right delta_type=dDiffYX
       # OEIS-Other: A127949 planepath=PyramidRows,step=1,align=right delta_type=dAbsDiff
     },
     do {   # n_start=0
       my $href =
         { dY      => 'A023531',  # 1,0,1,0,0,1,etc, 1 if n==k(k+3)/2
           AbsdY   => 'A023531',  # abs(dy) same

           # Not quite, A167407 has an extra initial 0
           # dDiffXY => 'A167407',
         };
       ('step=1,align=centre,n_start=0' => $href,
        'step=1,align=right,n_start=0'  => $href,
       );
       # OEIS-Catalogue: A023531 planepath=PyramidRows,step=1,n_start=0 delta_type=dY
       # OEIS-Other:     A023531 planepath=PyramidRows,step=1,n_start=0 delta_type=AbsdY

       # OEIS-Other: A023531 planepath=PyramidRows,step=1,align=right,n_start=0 delta_type=dY
       # OEIS-Other: A023531 planepath=PyramidRows,step=1,align=right,n_start=0 delta_type=AbsdY
     },
     'step=1,align=left,n_start=0' =>
     { dY      => 'A023531',  # 1,0,1,0,0,1,etc, 1 if n==k(k+3)/2
       AbsdY   => 'A023531',  # abs(dy) same
       # OEIS-Other: A023531 planepath=PyramidRows,step=1,align=left,n_start=0 delta_type=dY
       # OEIS-Other: A023531 planepath=PyramidRows,step=1,align=left,n_start=0 delta_type=AbsdY
     },

     # 'step=2,align=centre,n_start=0' =>
     # {
     #  # Not quite, extra initial 0
     #  # dDiffXY      => 'A010052',
     # },
    };
}
{ package Math::PlanePath::PyramidSides;
  use constant _NumSeq_Delta_dSumAbs_min => 0; # unchanged on diagonal
  use constant _NumSeq_Delta_dSumAbs_max => 1; # step to next diagonal
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  use constant _NumSeq_Delta_dRadius_min => -1;
  use constant _NumSeq_Delta_dRadius_max => 1;
  use constant _NumSeq_dRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_dTRadius_min => - sqrt(3);
  use constant _NumSeq_Delta_dTRadius_max => sqrt(3);
  use constant _NumSeq_dTRadius_min_is_infimum => 1;
  use constant _NumSeq_dTRadius_max_is_supremum => 1;

  use constant _NumSeq_Delta_Dir4_integer => 0; # diagonals
  use constant _NumSeq_Delta_TDir6_integer => 1;

  use constant _NumSeq_Delta_oeis_anum =>
    { 'n_start=1' =>
      { AbsdY => 'A049240', # 0=square,1=non-square
        # OEIS-Catalogue: A049240 planepath=PyramidSides delta_type=AbsdY

        # Not quite, extra initial 1 in A010052
        # dSumAbs => 'A010052', 1 at n=square
      },
    };
}
{ package Math::PlanePath::CellularRule;
  sub _NumSeq_Delta_dSum_non_decreasing {
    my ($self) = @_;
    return (($self->{'rule'} & 0x5F) == 0x54  # right line 2
            ? 1                               #   is constant dSum=+1
            : undef);
  }

  sub _NumSeq_Delta_dSumAbs_min {
    my ($self) = @_;
    return (($self->{'rule'} & 0x5F) == 0x54  # right line 2
            ? 1                               #   is constant dSum=+1
            : ($self->{'rule'} & 0x5F) == 0x0E     # left line 2
            ? -1
            : $self->{'rule'} == 7 ? -1
            : $self->{'rule'} == 9 ? -2
            : $self->{'rule'}==11 || $self->{'rule'}==43 ? -1
            : $self->{'rule'} == 15 ? -1
            : $self->{'rule'}==19 ? -1
            : $self->{'rule'}==21 ? -1
            : ($self->{'rule'} & 0x9F) == 0x17     # 0x17,...,0x7F
            ? -1
            : $self->{'rule'}==31 ? -1
            : $self->{'rule'}==41 ? -1
            : $self->{'rule'}==47 ? -1
            : $self->{'rule'}==62 ? -2
            : $self->{'rule'}==65 ? -2
            : $self->{'rule'}==69 ? -2
            : $self->{'rule'}==70 || $self->{'rule'}==198 ? -2
            : $self->{'rule'}==77 ? -2
            : $self->{'rule'}==78 ? -2
            : undef);
  }
  sub _NumSeq_Delta_dSumAbs_max {
    my ($self) = @_;
    return (($self->{'rule'} & 0x5F) == 0x54  # right line 2
            ? 1                               #   is constant dSum=+1
            : ($self->{'rule'} & 0x5F) == 0x0E     # left line 2
            ? 3
            : $self->{'rule'} == 9 ? 3
            : $self->{'rule'}==11 || $self->{'rule'}==43 ? 3
            : $self->{'rule'} == 13 ? 2
            : $self->{'rule'} == 15 ? 3
            : $self->{'rule'}==28 || $self->{'rule'}==156 ? 2
            : $self->{'rule'}==47 ? 3
            : $self->{'rule'}==77 ? 3
            : undef);
  }

  sub _NumSeq_Delta_dAbsDiff_min {
    my ($self) = @_;
    return (($self->{'rule'} & 0x5F) == 0x54  # right line 2
            ? -1

            : ($self->{'rule'} & 0x5F) == 0x0E  # left line 2
            ? -1

            : ($self->{'rule'} & 0xDF) == 3  # rule=3,35
            ? -3

            : $self->{'rule'} == 5
            ? -2

            : $self->{'rule'} == 7
            ? -1

            : $self->{'rule'} == 9
            ? -2

            : ($self->{'rule'} & 0xDF) == 11  # rule=11,43
            ? -1

            : $self->{'rule'} == 13
            ? -2

            : $self->{'rule'} == 15
            ? -1

            : ($self->{'rule'} & 0xDF) == 17  # rule=17,49
            ? -3

            : $self->{'rule'} == 19
            ? -2

            : $self->{'rule'} == 21
            ? -1

            : ($self->{'rule'} & 0x97) == 23 # rule=23,31,55,63,87,95,119,127
            ? -1

            : $self->{'rule'} == 27
            ? -2

            : $self->{'rule'} == 29
            ? -2

            : undef);
  }
  sub _NumSeq_Delta_dAbsDiff_max {
    my ($self) = @_;
    return (($self->{'rule'} & 0x5F) == 0x54  # right line 2
            ? 1

            : ($self->{'rule'} & 0x5F) == 0x0E  # left line 2
            ? 3

            : undef);
  }

  sub _NumSeq_Delta_dTRadius_min {
    my ($self) = @_;
    return (
            # X=0,Y=1 TRadius=sqrt(3) to X=1,Y=1 TRadius=sqrt(1+3)=2
            ($self->{'rule'} & 0x5F) == 0x54  # right line 2
            ? 2-sqrt(3)

            : undef);
  }
  sub _NumSeq_Delta_dTRadius_max {
    my ($self) = @_;
    return (($self->{'rule'} & 0x5F) == 0x54  # right line 2
            ? sqrt(3)
            : undef);
  }
  sub _NumSeq_Delta_dTRSquared_min {
    my ($self) = @_;
    return (($self->{'rule'} & 0x5F) == 0x54  # right line 2
            ? 1
            : undef);
  }

  sub _NumSeq_Dir4_max_is_supremum {
    my ($self) = @_;
    return (($self->{'rule'} & 0x5F) == 0x54  # right line 2
            || ($self->{'rule'} & 0x5F) == 0x0E  # left line 2
            ? 0
            : 1);  # supremum
  }
  sub _NumSeq_Delta_Dir4_integer {
    my ($self) = @_;
    return (($self->{'rule'} & 0x5F) == 0x54  # right line 2
            ? 1    # N,E only
            : 0);  # various diagonals
  }

  sub _NumSeq_Delta_dY_non_decreasing {
    my ($self) = @_;
    return (($self->{'rule'} & 0x17) == 0        # single cell only
            ? 1
            : 0);
  }

  use constant _NumSeq_Delta_TDir6_integer => 0;  # usually
}
{ package Math::PlanePath::CellularRule::OneTwo;
  use constant _NumSeq_Dir4_max_is_supremum => 0;

  use constant _NumSeq_Delta_dSum_non_decreasing => 0;

  sub _NumSeq_Delta_dSumAbs_min {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? -1 : 1);
  }
  sub _NumSeq_Delta_dSumAbs_max {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? 3 : 2);
  }

  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  sub _NumSeq_Delta_dAbsDiff_max {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? 3 : 1);
  }

  {
    my %_NumSeq_Delta_dRadius_min = (left  => - sqrt(2)/2,
                                     right => sqrt(2)-1);
    sub _NumSeq_Delta_dRadius_min {
      my ($self) = @_;
      return $_NumSeq_Delta_dRadius_min{$self->{'align'}};
    }
  }
  {
    # left max
    # *
    #  \
    #   *---*
    #
    my %_NumSeq_Delta_dRadius_max = (left  => sqrt(2)*3/2,
                                     right => sqrt(2));
    sub _NumSeq_Delta_dRadius_max {
      my ($self) = @_;
      return $_NumSeq_Delta_dRadius_max{$self->{'align'}};
    }
  }
  sub _NumSeq_Delta_dRSquared_min {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? undef
            : 1);
  }

  # H = sqrt(dX^2 + 3*dY^2)
  # p/h = X/Y*sqrt(3) = sqrt(3)/S       S = Y/X slope
  # p = h*sqrt(3)/S
  # h^2 + p^2 = 3*dY^2
  # h^2 + h^2*3/S^2 = 3*dY^2
  # h^2(1 + 3/S^2) = 3*dY^2
  # h^2 = 3*dY^2 / (1 + 3/S^2)
  # h = dY * sqrt(3 / (1 + 3/S^2))
  # h = dY * sqrt(1 / (1/3 + 1/S^2))
  # dY=1, S=-1, h=sqrt(3)/2

  # Left horiz X=-k,Y=k to X=-k+1,Y=k
  # dTRadius = sqrt((k-1)^2 + 3k^2) - sqrt(k^2 + 3k^2)
  #          = sqrt(k^2-2k+1 + 3k^2) - sqrt(k^2 + 3k^2)
  #          = sqrt(4k^2 -2k + 1) - sqrt(4k^2)
  #
  #             *------------*
  #              .   1     + |
  #                .     +   |
  #                 .  + p   |sqrt(3)
  #                   .      |
  #     H=sqrt(1+3)    .     |
  #     H=2              .   |
  #                        . |
  #                     h    *
  #
  # p/h = 1/sqrt(3)
  # p = h / sqrt(3)
  # h^2 + p^2 = 3
  # h^2 + h^2*1/3 = 3
  # h^2*4/3 = 3
  # h^2 = 9/4
  # h  = 3/2
  # H-h = 2 - 3/2 = 1/2
  #
  sub _NumSeq_Delta_dTRadius_min {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? -1/2
            : undef);
  }
  use constant _NumSeq_dTRadius_min_is_infimum => 1;

  # Left 2,1 up
  #                 dX=2
  #           * _            *
  #            .  ---___         dY*sqrt(3)
  #        H     .      ---__
  #      whole    .          *
  #                 .1     + |
  #                  .   +   |
  #                    + p   | dX*S*sqrt(3) - dY*sqrt(3)
  #                      .   |
  #                      h.  |
  #                         .|
  #                          *
  # H^2 = dX^2 + (sqrt(3)*S*dX)^2
  #     = 4 + 3*4 = 16    H=4
  #
  # p/h = 1/(S/sqrt(3)) = sqrt(3)/S
  # p = h*S/sqrt(3)
  # h^2 + p^2 = (dX*S*sqrt(3) - dY*sqrt(3))^2
  # h^2 + p^2 = 3*(dX*S - dY)^2
  # h^2 + S^2/3 * h^2 = 3*(dX*S - dY)^2
  # h^2 = 3*(dX*S - dY)^2 / (1 + S^2/3)
  # h^2 = 9/4
  # H-h = sqrt(dX^2 + 3*(dX*S)^2) - sqrt(3*(dX*S - dY)^2 / (1 + S^2/3))
  #
  sub _NumSeq_Delta_dTRadius_max {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? 5/2
            : 2);  # at N=3 NE diagonal up
  }
  sub _NumSeq_dTRadius_max_is_supremum {
    my ($self) = @_;
    return ($self->{'align'} eq 'left');
  }

  sub _NumSeq_Delta_dTRSquared_min {
    my ($self) = @_;
    return ($self->{'align'} eq 'right' ? 1 : undef);
  }

  use constant _NumSeq_Delta_oeis_anum =>
    { 'align=right,n_start=0' =>
      { dSumAbs => 'A177702', # 1,1,2 repeating, OFFSET=0
        # OEIS-Catalogue: A177702 planepath=CellularRule,rule=20,n_start=0 delta_type=dSumAbs
      },
      'align=left,n_start=0' =>
      { AbsdX   => 'A177702', # 1,1,2 repeating, OFFSET=0
        dSum    => 'A102283', # 0,1,-1 repeating, OFFSET=0
        dSumAbs => 'A131756', # 2,-1,3 repeating, OFFSET=0
        # OEIS-Other: A177702 planepath=CellularRule,rule=6,n_start=0 delta_type=AbsdX
        # OEIS-Catalogue: A102283 planepath=CellularRule,rule=6,n_start=0 delta_type=dSum
        # OEIS-Catalogue: A131756 planepath=CellularRule,rule=6,n_start=0 delta_type=dSumAbs
      },
    };
}
{ package Math::PlanePath::CellularRule::Two;
  use constant _NumSeq_Dir4_max_is_supremum => 0;

  use constant _NumSeq_Delta_dSum_non_decreasing => 0;

  sub _NumSeq_Delta_dSumAbs_min {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? -1 : 1);
  }
  sub _NumSeq_Delta_dSumAbs_max {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? 3 : 1);
  }

  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  sub _NumSeq_Delta_dAbsDiff_max {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? 3 : 1);
  }

  {
    my %_NumSeq_Delta_dRadius_min = (left  => - sqrt(2)/2,
                                     right => sqrt(2)-1);
    sub _NumSeq_Delta_dRadius_min {
      my ($self) = @_;
      return $_NumSeq_Delta_dRadius_min{$self->{'align'}};
    }
  }
  {
    my %_NumSeq_Delta_dRadius_max = (left  => sqrt(2)*3/2,
                                     right => 1);  # at N=1
    sub _NumSeq_Delta_dRadius_max {
      my ($self) = @_;
      return $_NumSeq_Delta_dRadius_max{$self->{'align'}};
    }
  }
  # dRsquared  2*k^2 - ((k-1)^2 + k^2) = 2*k-1
  #            (k^2 + (k+1)^2) - 2*k^2  = 2*k-1
  sub _NumSeq_Delta_dRSquared_min {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? undef
            : 1);
  }
  sub _NumSeq_Delta_dRSquared_non_decreasing {
    my ($self) = @_;
    return ($self->{'align'} eq 'right');
  }

  sub _NumSeq_Delta_dTRadius_min {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? -1/2
            : undef);
  }
  use constant _NumSeq_dTRadius_min_is_infimum => 1;

  sub _NumSeq_Delta_dTRadius_max {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? 5/2
            : 2);  # at N=3 NE diagonal up
  }
  sub _NumSeq_dTRadius_max_is_supremum {
    my ($self) = @_;
    return ($self->{'align'} eq 'left');
  }

  sub _NumSeq_Delta_dTRSquared_min {
    my ($self) = @_;
    return ($self->{'align'} eq 'right' ? 1 : undef);
  }

  sub _NumSeq_Delta_Dir4_integer {
    my ($self) = @_;
    return ($self->{'align'} eq 'right');
  }


  use constant _NumSeq_Delta_oeis_anum =>
    {
     'align=left,n_start=0' =>
     { dSum => 'A062157', # 0 then 1,-1 repeating
       # OEIS-Catalogue: A062157 planepath=CellularRule,rule=14,n_start=0 delta_type=dSum
       # OEIS-Other:     A062157 planepath=CellularRule,rule=174,n_start=0 delta_type=dSum
     },
     'align=right,n_start=0' =>
     { dRSquared => 'A109613', # 1,1,3,3,5,5 odd repeat, OFFSET+0
       # OEIS-Catalogue: A109613 planepath=CellularRule,rule=84,n_start=0 delta_type=dRSquared
       # OEIS-Other:     A109613 planepath=CellularRule,rule=244,n_start=0 delta_type=dRSquared
     },
    };
}
{ package Math::PlanePath::CellularRule::Line;
  sub _NumSeq_Delta_dSumAbs_min {
    my ($self) = @_;
    return abs($self->{'sign'}) + 1;  # dX=abs(sign),dY=1 always
  }
  *_NumSeq_Delta_dSumAbs_max = \&_NumSeq_Delta_dSumAbs_min;

  # constant left   => 2
  #          centre => 1
  #          right  => 0
  sub _NumSeq_Delta_dAbsDiff_min {
    my ($self) = @_;
    return 1-$self->{'sign'};
  }
  *_NumSeq_Delta_dAbsDiff_max = \&_NumSeq_Delta_dAbsDiff_min;

  sub _NumSeq_Delta_dTRadius_min {
    my ($self) = @_;
    return ($self->{'align'} eq 'centre' ? sqrt(3)  # centre     => sqrt(3) constant
            : 2);                                   # left,right => 2       constant
  }
  *_NumSeq_Delta_dTRadius_max = \&_NumSeq_Delta_dTRadius_min;
  sub _NumSeq_Delta_dTRadius_integer {
    my ($self) = @_;
    return ($self->{'align'} ne 'centre');
  }

  sub _NumSeq_Delta_dTRSquared_min {
    my ($self) = @_;
    return ($self->{'align'} eq 'centre' ? 3  # centre     => 3
            : 4);                             # left,right => 4
  }
  use constant _NumSeq_Delta_dTRSquared_increasing => 1;

  sub _NumSeq_Delta_DSquared_min {
    my ($path) = @_;
    return abs($path->{'sign'}) + 1;
  }
  *_NumSeq_Delta_DSquared_max = \&_NumSeq_Delta_DSquared_min;

  use constant _NumSeq_Dir4_max_is_supremum => 0;
  use constant _NumSeq_TDir6_max_is_supremum => 0;

  sub _NumSeq_Delta_Dir4_integer {
    my ($self) = @_;
    return ($self->{'sign'} == 0
            ? 1    # vertical Dir4=1
            : 0);  # left,right Dir4=0.5 or 1.5
  }
  sub _NumSeq_Delta_TDir6_integer {
    my ($self) = @_;
    return ($self->{'sign'} == 0
            ? 0    # vertical TDir6=1.5
            : 1);  # left,right Tdir6=1 or 2
  }

  use constant _NumSeq_Delta_dX_non_decreasing => 1; # constant
  use constant _NumSeq_Delta_dY_non_decreasing => 1; # constant
  use constant _NumSeq_Delta_AbsdX_non_decreasing => 1; # constant
  use constant _NumSeq_Delta_AbsdY_non_decreasing => 1; # constant
  use constant _NumSeq_Delta_dSum_non_decreasing => 1; # constant
  use constant _NumSeq_Delta_dSumAbs_non_decreasing => 1; # constant
  use constant _NumSeq_Delta_dDiffXY_non_decreasing => 1; # constant
  use constant _NumSeq_Delta_dDiffYX_non_decreasing => 1; # constant
  use constant _NumSeq_Delta_dAbsDiff_non_decreasing => 1; # constant
  use constant _NumSeq_Delta_Dir4_non_decreasing => 1; # constant
  use constant _NumSeq_Delta_TDir6_non_decreasing => 1; # constant
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDist_non_decreasing => 1;
}
{ package Math::PlanePath::CellularRule::OddSolid;
  use constant _NumSeq_Delta_dSumAbs_min => -2;
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  use constant _NumSeq_Delta_IntXY_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Dir4_max_is_supremum => 1;
  use constant _NumSeq_Delta_Dir4_integer => 0; # between rows
  use constant _NumSeq_Delta_DSquared_min => 2;
  use constant _NumSeq_Delta_TDir6_integer => 0;  # between rows
}
{ package Math::PlanePath::CellularRule54;
  use constant _NumSeq_Dir4_max_is_supremum => 1;
  use constant _NumSeq_Delta_Dir4_integer => 0;  # between rows
  use constant _NumSeq_Delta_TDir6_integer => 0;  # between rows
}
{ package Math::PlanePath::CellularRule57;
  use constant _NumSeq_Delta_dAbsDiff_min => -3;
  use constant _NumSeq_Dir4_max_is_supremum => 1;
  use constant _NumSeq_Delta_Dir4_integer => 0;  # between rows
  use constant _NumSeq_Delta_TDir6_integer => 0;  # between rows
}
{ package Math::PlanePath::CellularRule190;
  use constant _NumSeq_Delta_dSumAbs_min => -2; # towards Y axis dX=+2
  use constant _NumSeq_Delta_dSumAbs_max => 2;  # away Y axis dX=+2
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Dir4_max_is_supremum => 1;
  use constant _NumSeq_Delta_Dir4_integer => 0;  # between rows
  use constant _NumSeq_Delta_TDir6_integer => 0;  # between rows
}
{ package Math::PlanePath::UlamWarburton;
  # minimum dir=0 at N=1
  use constant _NumSeq_Delta_DSquared_min => 2;  # diagonal
  use constant _NumSeq_Delta_TDSquared_min => 4;  # diagonal

  # always diagonal slope=+/-1 within depth level.  parts=2 is horizontal
  # between levels, but parts=1 or parts=4 are other slopes between levels.
  sub _NumSeq_Delta_TDir6_integer {
    my ($self) = @_;
    return ($self->{'parts'} eq '2');
  }
}
{ package Math::PlanePath::UlamWarburtonQuarter;
  use constant _NumSeq_Delta_Dir4_integer => 0;  # N=1 North-East
  use constant _NumSeq_Delta_TDir6_integer => 0; # N=3 North
}
{ package Math::PlanePath::CoprimeColumns;
  use constant _NumSeq_Delta_TDir6_integer => 0; # between verticals
}
{ package Math::PlanePath::DivisibleColumns;
  use constant _NumSeq_Delta_TDir6_integer => 0; # between verticals
}
# { package Math::PlanePath::File;
#   # FIXME: analyze points for dx/dy min/max etc
# }
{ package Math::PlanePath::QuintetCurve;  # NSEW
  # inherit QuintetCentres, except

  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;
}
{ package Math::PlanePath::QuintetCentres;  # NSEW+diag
  use constant _NumSeq_Delta_dSumAbs_min => -2;
  use constant _NumSeq_Delta_dSumAbs_max => 2;
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;

  use constant _NumSeq_Delta_DSquared_max => 2;
}
{ package Math::PlanePath::QuintetReplicate;

  # N=1874 Dir4=3.65596
  # N=9374 Dir4=3.96738, etc
  # Dir4 supremum at 244...44 base 5
  use constant _NumSeq_Dir4_max_is_supremum => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;
}
{ package Math::PlanePath::AR2W2Curve;     # NSEW+diag
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;
  use constant _NumSeq_Delta_DSquared_max => 2;
}
{ package Math::PlanePath::KochelCurve;     # NSEW
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;
}
{ package Math::PlanePath::BetaOmega;    # NSEW
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;
}
{ package Math::PlanePath::DekkingCurve;    # NSEW
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;

  # segments on the X or Y axes always step away from the origin, so
  # dRadius_max==1 and dRadius_min only approaches -1
  use constant _NumSeq_Delta_dRadius_min => -1;
  use constant _NumSeq_Delta_dRadius_max => 1;
  use constant _NumSeq_dRadius_min_is_infimum => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;
}
{ package Math::PlanePath::DekkingCentres;   # NSEW+diag
  use constant _NumSeq_Delta_dAbsDiff_min => -2;
  use constant _NumSeq_Delta_dAbsDiff_max => 2;
  use constant _NumSeq_Delta_DSquared_max => 2;

  # The X=Y leading diagonal has both forward and backward segments.
  # First forward is at X=Y=22.  First reverse is at X=Y=12.
  use constant _NumSeq_Delta_dRadius_min => -sqrt(2);
  use constant _NumSeq_Delta_dRadius_max => sqrt(2);
}
{ package Math::PlanePath::CincoCurve;    # NSEW
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;
}
{ package Math::PlanePath::WunderlichMeander;    # NSEW
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;
}
{ package Math::PlanePath::HIndexing;   # NSEW
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;
}
{ package Math::PlanePath::DigitGroups;
  use constant _NumSeq_Dir4_max_is_supremum => 1; # almost full way
}
# { package Math::PlanePath::CornerReplicate;
#   sub _UNTESTED__NumSeq_Delta_dSum_pred {
#     my ($path, $value) = @_;
#     # target 1,-1,-3,-7,-15,etc
#     # negatives value = -(2^k-1) for k>=1 so -1,-3,-7,-15,etc
#     #           -value = 2^k-1
#     #           1-value = 2^k = 2,4,8,etc
#     $value = 1-$value;  # 0,2,4,8,16,etc
#     if ($value == 0) { return 1; }  # original $value=1
#     return ($value >= 2 && _is_pow2($value));
#   }
#   sub _is_pow2 {
#     my ($n) = @_;
#     my ($pow,$exp) = round_down_pow ($n, 2);
#     return ($n == $pow);
#   }
# }
{ package Math::PlanePath::SquareReplicate;
  use constant _NumSeq_Delta_Dir4_integer => 0;
}
{ package Math::PlanePath::FibonacciWordFractal;  # NSEW
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_DSquared_max => 1;  # NSEW only
  use constant _NumSeq_Delta_Dist_non_decreasing => 1;
  use constant _NumSeq_Delta_TDSquared_max => 3;

  use constant _NumSeq_Delta_oeis_anum =>
    { '' =>
      { AbsdX => 'A171587', # diagonal variant
        # OEIS-Catalogue: A171587 planepath=FibonacciWordFractal delta_type=AbsdX
      },
    };
}
{ package Math::PlanePath::LTiling;
  use constant _NumSeq_Dir4_max_is_supremum => 1; # almost full way
  sub _NumSeq_Delta_DSquared_min {
    my ($self) = @_;
    return ($self->{'L_fill'} eq 'middle'
            ? 5    # N=2 dX=2,dY=1
            : 1);
  }
  sub _NumSeq_Delta_TDSquared_min {
    my ($self) = @_;
    return ($self->{'L_fill'} eq 'middle'
            ? 7    # N=2 dX=2,dY=1
            : 1);
  }
}
{ package Math::PlanePath::WythoffArray;
  use constant _NumSeq_Delta_TDSquared_min => 1;
}
{ package Math::PlanePath::WythoffPreliminaryTriangle;
  use constant _NumSeq_Dir4_min_is_infimum => 1;
}
{ package Math::PlanePath::PowerArray;

  # at N=1to2 either dX=1,dY=0 if radix=2 or dX=0,dY=1 if radix>2
  sub _NumSeq_Delta_TDSquared_min {
    my ($self) = @_;
    return ($self->{'radix'} == 2
            ? 1    # dX=1,dY=0
            : 3);  # dX=0,dY=1
  }

  use constant _NumSeq_Delta_oeis_anum =>
    { 'radix=2' =>
      {
       # Not quite, OFFSET=0
       # AbsdX => 'A050603', # add1c(n,2)
       # # OEIS-Catalogue: A050603 planepath=PowerArray,radix=2 delta_type=AbsdX

       #  # # Not quite, starts OFFSET=0 (even though A001511 starts OFFSET=1)
       #  # # vs n_start=1 here
       #  # dX => 'A094267', # first diffs of count low 0s
       #  #  # OEIS-Catalogue: A094267 planepath=PowerArray,radix=2
       #
       #  # # Not quite, starts OFFSET=0 values 0,1,-1,2 as diffs of A025480
       #  # # 0,0,1,0,2, vs n_start=1 here doesn't include 0
       #  # dY => 'A108715', # first diffs of odd part of n
       #  # # OEIS-Catalogue: A108715 planepath=PowerArray,radix=2 delta_type=dY
      },
    };
}

{ package Math::PlanePath::ToothpickTree;
  {
    my %_NumSeq_Dir4_max_is_supremum = (3         => 1,
                                        2         => 1,
                                        1         => 1,
                                       );
    sub _NumSeq_Dir4_max_is_supremum {
      my ($self) = @_;
      return $_NumSeq_Dir4_max_is_supremum{$self->{'parts'}};
    }
  }
  use constant _NumSeq_Delta_Dir4_integer => 0;
}
{ package Math::PlanePath::ToothpickReplicate;
  use constant _NumSeq_Dir4_max_is_supremum => 1;
}
{ package Math::PlanePath::ToothpickUpist;
  use constant _NumSeq_Delta_Dir4_integer => 0; # diagonal between rows
  use constant _NumSeq_Delta_TDir6_integer => 0; # diagonal between rows
}
{ package Math::PlanePath::LCornerTree;
  {
    my %_NumSeq_Dir4_max_is_supremum
      = (4       => 0,
         3       => 1,
         2       => 1,
         1       => 1,
         octant  => 0,
        );
    sub _NumSeq_Dir4_max_is_supremum {
      my ($self) = @_;
      return $_NumSeq_Dir4_max_is_supremum{$self->{'parts'}};
    }
  }
  use constant _NumSeq_Delta_Dir4_integer => 0;
  use constant _NumSeq_Delta_TDir6_integer => 0;
}
{ package Math::PlanePath::ToothpickSpiral;
  use constant _NumSeq_Delta_dSumAbs_min => -1;
  use constant _NumSeq_Delta_dSumAbs_max => 1;
  use constant _NumSeq_Delta_dAbsDiff_min => -1;
  use constant _NumSeq_Delta_dAbsDiff_max => 1;

  use constant _NumSeq_Delta_dTRadius_min => - sqrt(3);
  use constant _NumSeq_Delta_dTRadius_max => sqrt(3);
  use constant _NumSeq_dTRadius_min_is_infimum => 1;
  use constant _NumSeq_dTRadius_max_is_supremum => 1;

  use constant _NumSeq_Delta_oeis_anum =>
    { 'n_start=0' =>
      { AbsdX => 'A000035',  # 0,1 repeating
        AbsdY => 'A059841',  # 1,0 repeating
      },
    };
}
{ package Math::PlanePath::LCornerReplicate;
  use constant _NumSeq_Dir4_max_is_supremum => 1;
}
{ package Math::PlanePath::OneOfEight;
  {
    my %_NumSeq_Dir4_max_is_supremum
      = (4       => 0,
         1       => 1,
         octant  => 0,
         '3mid'  => 1,
         '3side' => 1,
        );
    sub _NumSeq_Dir4_max_is_supremum {
      my ($self) = @_;
      return $_NumSeq_Dir4_max_is_supremum{$self->{'parts'}};
    }
  }
  use constant _NumSeq_Delta_Dir4_integer => 0;
  use constant _NumSeq_Delta_TDir6_integer => 0;
}

1;
__END__


# sub pred {
#   my ($self, $value) = @_;
#
#   my $planepath_object = $self->{'planepath_object'};
#   my $figure = $planepath_object->figure;
#   if ($figure eq 'square') {
#     if ($value != int($value)) {
#       return 0;
#     }
#   } elsif ($figure eq 'circle') {
#     return 1;
#   }
#
#   my $delta_type = $self->{'delta_type'};
#   if ($delta_type eq 'X') {
#     if ($planepath_object->x_negative) {
#       return 1;
#     } else {
#       return ($value >= 0);
#     }
#   } elsif ($delta_type eq 'Y') {
#     if ($planepath_object->y_negative) {
#       return 1;
#     } else {
#       return ($value >= 0);
#     }
#   } elsif ($delta_type eq 'Sum') {
#     if ($planepath_object->x_negative || $planepath_object->y_negative) {
#       return 1;
#     } else {
#       return ($value >= 0);
#     }
#   }
#
#   return undef;
# }


=for stopwords Ryde dX dY dX+dY dX-dY dSum dDiffXY DiffXY dDiffYX dAbsDiff AbsDiff TDir6 Math-NumSeq Math-PlanePath NumSeq SquareSpiral PlanePath AbsdX AbsdY NSEW boolean dSumAbs SumAbs ENWS dRadius dRSquared RSquared supremum OEIS

=head1 NAME

Math::NumSeq::PlanePathDelta -- sequence of changes and directions of PlanePath coordinates

=head1 SYNOPSIS

 use Math::NumSeq::PlanePathDelta;
 my $seq = Math::NumSeq::PlanePathDelta->new
             (planepath => 'SquareSpiral',
              delta_type => 'dX');
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is a tie-in to present coordinate changes and directions from a
C<Math::PlanePath> module in the form of a NumSeq sequence.

The C<delta_type> choices are

    "dX"         change in X coordinate
    "dY"         change in Y coordinate
    "AbsdX"      abs(dX)
    "AbsdY"      abs(dY)
    "dSum"       change in X+Y, equals dX+dY
    "dSumAbs"    change in abs(X)+abs(Y)
    "dDiffXY"    change in X-Y, equals dX-dY
    "dDiffYX"    change in Y-X, equals dY-dX
    "dAbsDiff"   change in abs(X-Y)
    "dRadius"    change in Radius sqrt(X^2+Y^2)
    "dRSquared"  change in RSquared X^2+Y^2
    "Dir4"       direction 0=East, 1=North, 2=West, 3=South
    "TDir6"      triangular 0=E, 1=NE, 2=NW, 3=W, 4=SW, 5=SE

In each case the value at i is per C<$path-E<gt>n_to_dxdy($i)>, being the
change from N=i to N=i+1, or from N=i to N=i+arms for paths with multiple
"arms" (thus following the arm).  i values start from the usual
C<$path-E<gt>n_start()>.

=head2 AbsdX,AbsdY

If a path always steps NSEW by 1 then AbsdX and AbsdY behave as a boolean
indicating horizontal or vertical step,

    NSEW steps by 1 gives

    AbsdX = 0 vertical            AbsdY = 0 horizontal
            1 horizontal                  1 vertical

If a path includes diagonal steps by 1 then those diagonals are a non-zero
delta, so the indication is then

    NSEW and diagonals steps by 1 gives

    AbsdX = 0 vertical            AbsdY = 0 horizontal
            1 non-vertical                1 non-horizontal
              ie. horiz or diag             ie. vert or diag

=head2 dSum

"dSum" is the change in X+Y and is also simply dX+dY since

    dSum = (Xnext+Ynext) - (X+Y)
         = (Xnext-X) + (Ynext-Y)
         = dX + dY

The sum X+Y counts anti-diagonals, as described in
L<Math::NumSeq::PlanePathCoord>.  dSum is therefore a move between
diagonals, or 0 if a step stays within the same diagonal.

               \
                \  ^  dSum > 0      dSum = step dist to North-East
                 \/
                 /\
    dSum < 0    v  \
                    \

=head2 dSumAbs

"dSumAbs" is the change in the abs(X)+abs(Y) sum,

    dSumAbs = (abs(Xnext)+abs(Ynext)) - (abs(X)+abs(Y))

As described in L<Math::NumSeq::PlanePathCoord/SumAbs>, SumAbs is a
"Manhattan" or "taxi-cab" distance from the origin, or equivalently a move
between diamond-shaped rings.

For example C<DiamondSpiral> follows a diamond shape ring around and so has
dSumAbs=0 until stepping out to each next diamond with dSumAbs=1.

A path might make a big X,Y jump which is only a small change in SumAbs.
For example C<PyramidRows> in its default step=2 from the end of one row to
the start of the next has dSumAbs=2.

=head2 dDiffXY and dDiffYX

"dDiffXY" is the change in DiffXY = X-Y, which is also simply dX-dY since

    dDiffXY = (Xnext-Ynext) - (X-Y)
            = (Xnext-X) - (Ynext-Y)
            = dX - dY

The difference X-Y counts diagonals downwards to the south-east as described
in L<Math::NumSeq::PlanePathCoord/Sum and Diff>.  dDiffXY is therefore
movement between those diagonals, or 0 if a step stays within the same
diagonal.

    dDiffXY < 0       /
                  \  /             dDiffXY = step dist to South-East
                   \/
                   /\
                  /  v
                 /      dDiffXY > 0

"dDiffYX" is the negative of dDiffXY.  Whether X-Y or Y-X is desired depends
on which way you want to measure diagonals, or which way around to have the
sign for the changes.  dDiffYX is based on Y-X and so counts diagonals
upwards to the North-West.

=head2 dAbsDiff

"dAbsDiff" is the change in AbsDiff = abs(X-Y).  AbsDiff can be interpreted
geometrically as distance from the leading diagonal, as described in
L<Math::NumSeq::PlanePathCoord/AbsDiff>.  dAbsDiff is therefore movement
closer to or further away from that leading diagonal, measuring
perpendicular to it.

                / X=Y line
               /
              /  ^
             /    \
            /      *  dAbsDiff move towards or away from X=Y line
          |/        \
        --o--        v
         /|
        /

When an X,Y jumps from one side of the diagonal to the other dAbsDiff is
still the change in distance from the diagonal.  So for example if X,Y is
followed by the mirror point Y,X then dAbsDiff=0.  That sort of thing
happens for example in the C<Diagonals> path when jumping from the end of
one run to the start of the next.  In the C<Diagonals> case it's a move just
1 further away from the X=Y centre line even though it's a big jump in
overall distance.

=head2 dRadius, dRSquared

"dRadius" and "dRSquared" are the change in the Radius and RSquared as
described in L<Math::NumSeq::PlanePathCoord/Radius and RSquared>.

    dRadius   = next_Radius   - Radius
    dRSquared = next_RSquared - RSquared

dRadius can be interpreted geometrically as movement towards (negative
values) or away from (positive values) the origin, ignoring direction.

Notice that dRadius is not sqrt(dRSquared), since sqrt(n^2-t^2) != n-t
unless n or t is zero.  Here would mean a step either going to or coming
from the origin 0,0.

=head2 Dir4

"Dir4" is the curve step direction as an angle in the range 0 E<lt>= Dir4
E<lt> 4.  The cardinal directions E,N,W,S are 0,1,2,3.  Angles in between
are a fraction.

    Dir4 = atan2(dY,dX)  scaled as range 0 <= Dir4 < 4

    1.5   1   0.5
        \ | /
         \|/
    2 ----o---- 0
         /|\
        / | \
    2.5   3   3.5

If a row such as Y=-1,XE<gt>0 just below the X axis is visited then the Dir4
approaches 4, without ever reaching it.  The C<$seq-E<gt>value_maximum()> is
4 in this case, as a supremum.

=head2 TDir6

"TDir6" is the curve step direction 0 E<lt>= TDir6 E<lt> 6 taken in the
triangular style of L<Math::PlanePath/Triangular Lattice>.  So dX=1,dY=1 is
taken to be 60 degrees which is TDir6=1.

      2   1.5   1        TDir6
         \ | /
          \|/
      3 ---o--- 0
          /|\
         / | \
      4   4.5   5

Angles in between the six cardinal directions are fractions.  North is 1.5
and South is 4.5.

The direction angle is calculated as if dY was scaled by a factor sqrt(3) to
make the lattice into equilateral triangles, or equivalently as a circle
stretched vertically by sqrt(3) to become an ellipse.

    TDir6 = atan2(dY*sqrt(3), dX)      in range 0 <= TDir6 < 6

Notice that angles on the axes dX=0 or dY=0 are not changed by the sqrt(3)
factor.  So TDir6 has ENWS 0, 1.5, 3, 4.5 which is steps of 1.5.  Verticals
North and South normally don't occur in the triangular lattice paths which
go by unit steps, but TDir6 can be applied on any path.

The sqrt(3) factor increases angles in the middle of the quadrants.  For
example dX=1,dY=1 becomes TDir6=1 whereas a plain angle would be only
45/360*6=0.75 in the same 0 to 6 scale.  The sqrt(3) is a continuous
scaling, so a plain angle and a TDir6 are a one-to-one mapping.  As the
direction progresses through the quadrant TDir6 grows first faster and then
slower than the plain angle.

=cut

# TDir6 = atan2(dY*sqrt(3), dX)
# Dir6  = atan2(dY, dX)
# TDir6 = Dir6 * atan2(dY*sqrt(3), dX)/atan2(dY, dX)

=pod

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::PlanePathDelta-E<gt>new (key=E<gt>value,...)>

Create and return a new sequence object.  The options are

    planepath          string, name of a PlanePath module
    planepath_object   PlanePath object
    delta_type         string, as described above

C<planepath> can be either the module part such as "SquareSpiral" or a
full class name "Math::PlanePath::SquareSpiral".

=item C<$value = $seq-E<gt>ith($i)>

Return the change at N=$i in the PlanePath.

=item C<$i = $seq-E<gt>i_start()>

Return the first index C<$i> in the sequence.  This is the position
C<$seq-E<gt>rewind()> returns to.

This is C<$path-E<gt>n_start()> from the PlanePath.

=back

=head1 BUGS

Some path sequences don't have C<oeis_anum()> and are not available through
L<Math::NumSeq::OEIS> entry due to the path C<n_start()> not matching
the OEIS "offset".  Paths with an C<n_start> parameter have suitable
adjustments applied, but those without are omitted from the
L<Math::NumSeq::OEIS> mechanism presently.

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::PlanePathCoord>,
L<Math::NumSeq::PlanePathTurn>,
L<Math::NumSeq::PlanePathN>

L<Math::PlanePath>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
