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


# Maybe:
# "Turn"   N of turn positions
# $path->n_next_turn($n)


package Math::NumSeq::PlanePathN;
use 5.004;
use strict;
use Carp 'croak';
use constant 1.02;

use vars '$VERSION','@ISA';
$VERSION = 124;
use Math::NumSeq;
@ISA = ('Math::NumSeq');

use Math::NumSeq::PlanePathCoord;

# uncomment this to run the ### lines
# use Smart::Comments;


sub description {
  my ($self) = @_;
  if (ref $self) {
    return "N values on $self->{'line_type'} of path $self->{'planepath'}";
  } else {
    # class method
    return 'N values from a PlanePath';
  }
}

use constant::defer parameter_info_array =>
  sub {
    return [
            Math::NumSeq::PlanePathCoord::_parameter_info_planepath(),

            { name    => 'line_type',
              display => 'Line Type',
              type    => 'enum',
              default => 'X_axis',
              choices => ['X_axis',
                          'Y_axis',
                          'X_neg',
                          'Y_neg',
                          'Diagonal',
                          'Diagonal_NW',
                          'Diagonal_SW',
                          'Diagonal_SE',
                          'Depth_start',
                          'Depth_end',
                         ],
              description => 'The axis or line to take path N values from.',
            },
           ];
  };

#------------------------------------------------------------------------------

my %oeis_anum =
  (
   # MultipleRings,step=0 -- integers 1,2,3, etc, but starting i=0
  );

sub oeis_anum {
  my ($self) = @_;
  ### PlanePathN oeis_anum() ...

  my $planepath_object = $self->{'planepath_object'};
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
    ### whole table: $planepath_object->_NumSeq_N_oeis_anum
    ### key href: $planepath_object->_NumSeq_N_oeis_anum->{$key}

    if (my $anum = $planepath_object->_NumSeq_N_oeis_anum->{$key}->{$self->{'line_type'}}) {
      return $anum;
    }
    if (my $anum = $planepath_object->_NumSeq_N_oeis_all_anum->{$self->{'line_type'}}) {
      return $anum;
    }
  }
  {
    my $key = Math::NumSeq::PlanePathCoord::_planepath_oeis_key($planepath_object);
    my $i_start = $self->i_start;
    if ($i_start != $self->default_i_start) {
      ### $i_start
      ### cf n_start: $planepath_object->n_start
      $key .= ",i_start=$i_start";
    }
    ### $key
    ### hash: $oeis_anum{$key}
    return $oeis_anum{$key}->{$self->{'line_type'}};
  }
}

#------------------------------------------------------------------------------

sub default_i_start {
  my ($self) = @_;

  my $planepath_object = $self->{'planepath_object'}
    # nasty hack allow no 'planepath_object' when SUPER::new() calls rewind()
    || return 0;

  my $method = "_NumSeq_$self->{'line_type'}_i_start";
  if (my $func = $planepath_object->can($method)) {
    return $planepath_object->$func();
  }
  return 0;
}
sub new {
  my $self = shift->SUPER::new(@_);

  my $planepath_object = ($self->{'planepath_object'}
                          ||= Math::NumSeq::PlanePathCoord::_planepath_name_to_object($self->{'planepath'}));
  ### $planepath_object

  my $line_type = $self->{'line_type'};

  ### i_func name: "i_func_$line_type"
  $self->{'i_func'}
    = $self->can("i_func_$line_type")
      || croak "Unrecognised line_type: ",$line_type;

  $self->{'pred_func'}
    = $self->can("pred_func_$line_type")
      || croak "Unrecognised line_type: ",$line_type;

  if (my $func
      = $planepath_object->can("_NumSeq_${line_type}_step")) {
    $self->{'i_step'} = $planepath_object->$func();
  } elsif ($planepath_object->_NumSeq_A2()
           && ($line_type eq 'X_axis'
               || $line_type eq 'Y_axis'
               || $line_type eq 'X_neg'
               || $line_type eq 'Y_neg')) {
    $self->{'i_step'} = 2;
  } else {
    $self->{'i_step'} = 1;
  }
  ### i_step: $self->{'i_step'}

  # for use in pred()
  $self->{'i_start'} = $self->i_start;

  $self->rewind;
  return $self;
}

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
}

sub next {
  my ($self) = @_;
  ### NumSeq-PlanePathN next(): "i=$self->{'i'}"

  my $i = $self->{'i'};
  my $n = &{$self->{'i_func'}} ($self, $i);
  ### $n
  if (! defined $n) {
    ### i_func returns undef, no value ...
    return;
  }
  # secret experimental automatic bigint to preserve precision
  if (! ref $n && $n > 0xFF_FFFF) {
    $n = &{$self->{'i_func'}}($self,_to_bigint($i));
  }
  return ($self->{'i'}++, $n);
}
sub _to_bigint {
  my ($n) = @_;
  # stringize to avoid UV->BigInt bug in Math::BigInt::GMP version 1.37
  return _bigint()->new("$n");
}
# or maybe check for new enough for uv->mpz fix
use constant::defer _bigint => sub {
  # Crib note: don't change the back-end if already loaded
  unless (Math::BigInt->can('new')) {
    require Math::BigInt;
    eval { Math::BigInt->import (try => 'GMP') };
  }
  return 'Math::BigInt';
};

sub ith {
  my ($self, $i) = @_;
  ### NumSeq-PlanePathN ith(): $i
  return &{$self->{'i_func'}}($self, $i);
}

sub i_func_X_axis {
  my ($self, $i) = @_;
  my $path_object = $self->{'planepath_object'};
  return $path_object->xy_to_n ($i * $self->{'i_step'},
                                $path_object->_NumSeq_X_axis_at_Y);
}
sub i_func_Y_axis {
  my ($self, $i) = @_;
  ### i_func_Y_axis(): "i=$i"
  ### X: $self->{'planepath_object'}->_NumSeq_Y_axis_at_X
  ### Y: $i * $self->{'i_step'}
  my $path_object = $self->{'planepath_object'};
  return $path_object->xy_to_n ($path_object->_NumSeq_Y_axis_at_X,
                                $i * $self->{'i_step'});
}
sub i_func_X_neg {
  my ($self, $i) = @_;
  ### i_func_X_neg(): $i
  my $path_object = $self->{'planepath_object'};
  return $path_object->xy_to_n (-$i * $self->{'i_step'},
                                $path_object->_NumSeq_X_axis_at_Y);
}
sub i_func_Y_neg {
  my ($self, $i) = @_;
  my $path_object = $self->{'planepath_object'};
  return $path_object->xy_to_n ($path_object->_NumSeq_Y_axis_at_X,
                                - $i * $self->{'i_step'});
}
sub i_func_Diagonal {
  my ($self, $i) = @_;
  my $path_object = $self->{'planepath_object'};
  return $path_object->xy_to_n ($i + $path_object->_NumSeq_Diagonal_X_offset,
                                $i);
}
sub i_func_Diagonal_NW {
  my ($self, $i) = @_;
  my $path_object = $self->{'planepath_object'};
  return $path_object->xy_to_n (-$i + $path_object->_NumSeq_Diagonal_X_offset,
                                $i);
}
sub i_func_Diagonal_SW {
  my ($self, $i) = @_;
  my $path_object = $self->{'planepath_object'};
  return $path_object->xy_to_n (-$i + $path_object->_NumSeq_Diagonal_X_offset,
                                -$i);
}
sub i_func_Diagonal_SE {
  my ($self, $i) = @_;
  my $path_object = $self->{'planepath_object'};
  return $path_object->xy_to_n ($i + $path_object->_NumSeq_Diagonal_X_offset,
                                -$i);
}

sub i_func_Depth_start {
  my ($self, $i) = @_;
  ### i_func_Depth_start(): "i=$i"
  return $self->{'planepath_object'}->tree_depth_to_n($i);
}
sub i_func_Depth_end {
  my ($self, $i) = @_;
  return $self->{'planepath_object'}->tree_depth_to_n_end($i);
}

#------------------------------------------------------------------------------

sub pred {
  my ($self, $value) = @_;
  ### PlanePathN pred(): $value
  my $planepath_object = $self->{'planepath_object'};
  unless ($value == int($value)) {
    return 0;
  }
  my ($x,$y) = $planepath_object->n_to_xy($value)
    or return 0;
  return &{$self->{'pred_func'}} ($self, $x,$y, $value);
}
sub pred_func_X_axis {
  my ($self, $x,$y) = @_;
  return ($x >= $self->{'i_start'}
          && $y == $self->{'planepath_object'}->_NumSeq_X_axis_at_Y);
}
sub pred_func_Y_axis {
  my ($self, $x,$y) = @_;
  return ($x == $self->{'planepath_object'}->_NumSeq_Y_axis_at_X
          && $y >= $self->{'i_start'});
}
sub pred_func_X_neg {
  my ($self, $x,$y) = @_;
  return ($x <= - $self->{'i_start'} && $y == 0);
}
sub pred_func_Y_neg {
  my ($self, $x,$y) = @_;
  return ($x == 0 && $y <= - $self->{'i_start'});
}
sub pred_func_Diagonal {
  my ($self, $x,$y) = @_;
  $x -= $self->{'planepath_object'}->_NumSeq_Diagonal_X_offset;
  return ($x >= $self->{'i_start'} && $x == $y);
}
sub pred_func_Diagonal_NW {
  my ($self, $x,$y) = @_;
  return ($x <= - $self->{'i_start'} && $x == -$y);
}
sub pred_func_Diagonal_SW {
  my ($self, $x,$y) = @_;
  return ($x <= - $self->{'i_start'} && $x == $y);
}
sub pred_func_Diagonal_SE {
  my ($self, $x,$y) = @_;
  return ($x >= $self->{'i_start'} && $x == -$y);
}

sub pred_func_Depth_start {
  my ($self, $x,$y, $n) = @_;
  return path_tree_n_is_depth_start($self->{'planepath_object'}, $n);
}
sub pred_func_Depth_end {
  my ($self, $x,$y, $n) = @_;
  return path_tree_n_is_depth_end($self->{'planepath_object'}, $n);
}

# Return true if $n is the start of a depth level.
sub path_tree_n_is_depth_start {
  my ($path, $n) = @_;
  my $depth = $path->tree_n_to_depth($n);
  return (defined $depth && $n == $path->tree_depth_to_n($depth));
}
# Return true if $n is the end of a depth level.
sub path_tree_n_is_depth_end {
  my ($path, $n) = @_;
  my $depth = $path->tree_n_to_depth($n);
  return (defined $depth && $n == $path->tree_depth_to_n_end($depth));
}

#------------------------------------------------------------------------------

use constant characteristic_integer => 1; # integer Ns

sub characteristic_increasing {
  my ($self) = @_;
  ### PlanePathN characteristic_increasing(): $self

  my $method = "_NumSeq_$self->{'line_type'}_increasing";
  my $planepath_object = $self->{'planepath_object'};

  ### planepath_object: ref $planepath_object
  ### $method
  ### can code: $planepath_object->can($method)
  ### result: $planepath_object->can($method) && $planepath_object->$method()

  return $planepath_object->can($method) && $planepath_object->$method();
}
sub characteristic_increasing_from_i {
  my ($self) = @_;
  ### PlanePathN characteristic_increasing_from_i(): $self

  my $planepath_object = $self->{'planepath_object'};
  my $method = "_NumSeq_$self->{'line_type'}_increasing_from_i";
  ### $method

  if ($method = $planepath_object->can($method)) {
    ### can: $method
    return $planepath_object->$method();
  }
  return ($self->characteristic('increasing')
          ? $self->i_start
          : undef);
}

sub characteristic_non_decreasing {
  my ($self) = @_;
  ### PlanePathN characteristic_non_decreasing() ...
  my $planepath_object = $self->{'planepath_object'};
  my $method = "_NumSeq_$self->{'line_type'}_non_decreasing";
  return (($planepath_object->can($method) && $planepath_object->$method())
          || $self->characteristic_increasing);
}

sub values_min {
  my ($self) = @_;
  ### PlanePathN values_min() ...
  my $method = "_NumSeq_$self->{'line_type'}_min";
  my $planepath_object = $self->{'planepath_object'};
  if (my $coderef = $planepath_object->can($method)) {
    ### $coderef
    return $planepath_object->$coderef();
  }
  return $self->ith($self->i_start);
}
sub values_max {
  my ($self) = @_;
  my $method = "_NumSeq_$self->{'line_type'}_max";
  my $planepath_object = $self->{'planepath_object'};
  if (my $coderef = $planepath_object->can($method)) {
    return $planepath_object->$coderef();
  }
  return undef;
}

{ package Math::PlanePath;
  sub _NumSeq_X_axis_i_start {
    my ($self) = @_;
    my $x_minimum = $self->x_minimum;
    if (defined $x_minimum && $x_minimum > 0) {
      return int($x_minimum);
    }
    return 0;
  }
  sub _NumSeq_Y_axis_i_start {
    my ($self) = @_;
    ### _NumSeq_Y_axis_i_start() ...
    my $y_minimum = $self->y_minimum;
    if (defined $y_minimum && $y_minimum > 0) {
      return int($y_minimum);
    }
    return 0;
  }
  sub _NumSeq_Y_axis_at_X {
    my ($self) = @_;
    my $x_minimum = $self->x_minimum;
    if (defined $x_minimum && $x_minimum > 0) {
      return $x_minimum;
    }
    return 0;
  }
  sub _NumSeq_X_axis_at_Y {
    my ($self) = @_;
    my $y_minimum = $self->y_minimum;
    if (defined $y_minimum && $y_minimum > 0) {
      return $y_minimum;
    }
    return 0;
  }

  # i_start = Xminimum - Xoffset
  # gives Xstart = i_start + Xoffset = Xminimum to start at Xminimum
  use List::Util;
  sub _NumSeq_Diagonal_i_start {
    my ($self) = @_;
    my $x_minimum = $self->x_minimum;
    my $y_minimum = $self->y_minimum;
    return List::Util::max
      (int(($x_minimum||0) - $self->_NumSeq_Diagonal_X_offset),
       int($y_minimum||0),
       0);
  }
  use constant _NumSeq_Diagonal_X_offset => 0;
  use constant _NumSeq_N_oeis_anum => {};
  use constant _NumSeq_N_oeis_all_anum => {};
  use constant _NumSeq_Depth_start_increasing => 1;
  use constant _NumSeq_Depth_end_increasing => 1;

  # sub _NumSeq_pred_X_axis {
  #   my ($path, $value) = @_;
  #   return ($value == int($value)
  #           && ($path->x_negative || $value >= 0));
  # }
  # sub _NumSeq_pred_Y_axis {
  #   my ($path, $value) = @_;
  #   return ($value == int($value)
  #           && ($path->y_negative || $value >= 0));
  # }
}

{ package Math::PlanePath::SquareSpiral;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  sub _NumSeq_X_neg_increasing {
    my ($self) = @_;
    return ($self->{'wider'} == 0);
  }
  sub _NumSeq_X_neg_increasing_from_i {
    my ($self) = @_;
    ### SquareSpiral _NumSeq_X_neg_increasing_from_i(): $self
    # wider=0 from X=0
    # wider=1 from X=-1
    # wider=2 from X=-1
    return int(($self->{'wider'}+1)/2);
  }
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  sub _NumSeq_X_neg_min { # not the value at X=0,Y=0 if wider>0
    my ($self) = @_;
    return $self->n_start;
  }

  use constant _NumSeq_N_oeis_anum =>
    { 'wider=0,n_start=1' =>
      { X_axis      => 'A054552', # spoke E, 4n^2 - 3n + 1
        Y_neg       => 'A033951', # spoke S, 4n^2 + 3n + 1
        Diagonal_NW => 'A053755', # 4n^2 + 1
        Diagonal_SE => 'A016754', # (2n+1)^2
        # OEIS-Catalogue: A054552 planepath=SquareSpiral
        # OEIS-Catalogue: A033951 planepath=SquareSpiral line_type=Y_neg
        # OEIS-Catalogue: A053755 planepath=SquareSpiral line_type=Diagonal_NW
        # OEIS-Catalogue: A016754 planepath=SquareSpiral line_type=Diagonal_SE
        #
        # OEIS-Other: A054552 planepath=GreekKeySpiral,turns=0
        # OEIS-Other: A033951 planepath=GreekKeySpiral,turns=0 line_type=Y_neg
        # OEIS-Other: A053755 planepath=GreekKeySpiral,turns=0 line_type=Diagonal_NW
        # OEIS-Other: A016754 planepath=GreekKeySpiral,turns=0 line_type=Diagonal_SE

        # Not quite, these have OFFSET=1 whereas path start X=0
        # # Y_axis   => 'A054556', # spoke N
        # # X_neg   => 'A054567', # spoke W
        # # Diagonal => 'A054554', # spoke NE
        # # Diagonal_SW => 'A054569', # spoke NE
        # # # OEIS-Catalogue: A054556 planepath=SquareSpiral line_type=Y_axis
        # # # OEIS-Catalogue: A054554 planepath=SquareSpiral line_type=Diagonal
      },
      'wider=0,n_start=0' =>
      { X_axis      => 'A001107',
        Y_axis      => 'A033991',
        Y_neg       => 'A033954', # second 10-gonals
        Diagonal    => 'A002939',
        Diagonal_NW => 'A016742', # 10-gonals average, 4*n^2
        Diagonal_SW => 'A002943',
        # OEIS-Other: A001107 planepath=SquareSpiral,n_start=0
        # OEIS-Catalogue: A033991 planepath=SquareSpiral,n_start=0 line_type=Y_axis
        # OEIS-Other: A033954 planepath=SquareSpiral,n_start=0 line_type=Y_neg
        # OEIS-Catalogue: A002939 planepath=SquareSpiral,n_start=0 line_type=Diagonal
        # OEIS-Other: A016742 planepath=SquareSpiral,n_start=0 line_type=Diagonal_NW
        # OEIS-Catalogue: A002943 planepath=SquareSpiral,n_start=0 line_type=Diagonal_SW
      },

      'wider=1,n_start=1' =>
      { Diagonal_SW => 'A069894',
        # OEIS-Catalogue: A069894 planepath=SquareSpiral,wider=1 line_type=Diagonal_SW
      },
      'wider=1,n_start=0' =>
      { Diagonal_SW => 'A016754', # odd squares
        # OEIS-Other: A016754 planepath=SquareSpiral,wider=1,n_start=0 line_type=Diagonal_SW
      },
    };
}
{ package Math::PlanePath::GreekKeySpiral;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  sub _NumSeq_X_neg_increasing {
    my ($self) = @_;
    return ($self->{'turns'} == 0);  # when SquareSpiral style
  }
  *_NumSeq_Y_neg_increasing = \&_NumSeq_X_neg_increasing;
  sub _NumSeq_Diagonal_increasing {
    my ($self) = @_;
    return ($self->{'turns'} <= 1);
  }
  sub _NumSeq_Diagonal_NW_increasing {
    my ($self) = @_;
    return ($self->{'turns'} == 0);
  }
  *_NumSeq_Diagonal_SW_increasing = \&_NumSeq_Diagonal_increasing;
  sub _NumSeq_Diagonal_SE_increasing {
    my ($self) = @_;
    return ($self->{'turns'} <= 2);
  }

  use constant _NumSeq_N_oeis_anum =>
    { 'turns=0' =>
      (Math::PlanePath::SquareSpiral
       ->_NumSeq_N_oeis_anum->{'wider=0,n_start=1'}
       || die "Oops, SquareSpiral NumSeq PlanePathN not found"),
    };
}
{ package Math::PlanePath::PyramidSpiral;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'n_start=1' =>
      { X_axis      => 'A054552', # square spiral spoke E, 4n^2 - 3n + 1
        Diagonal_SE => 'A033951', # square spiral spoke S, 4n^2 + 3n + 1
        # OEIS-Other: A054552 planepath=PyramidSpiral
        # OEIS-Other: A033951 planepath=PyramidSpiral line_type=Diagonal_SE
      },
      'n_start=0' =>
      { X_axis      => 'A001107', # decagonal
        Y_axis      => 'A002939',
        X_neg       => 'A033991',
        Y_neg       => 'A002943',
        Diagonal_SW => 'A007742',
        Diagonal_SE => 'A033954', # decagonal second kind
        # OEIS-Other: A001107 planepath=PyramidSpiral,n_start=0
        # OEIS-Other: A002939 planepath=PyramidSpiral,n_start=0 line_type=Y_axis
        # OEIS-Other: A033991 planepath=PyramidSpiral,n_start=0 line_type=X_neg
        # OEIS-Other: A002943 planepath=PyramidSpiral,n_start=0 line_type=Y_neg
        # OEIS-Other: A007742 planepath=PyramidSpiral,n_start=0 line_type=Diagonal_SW
        # OEIS-Other: A033954 planepath=PyramidSpiral,n_start=0 line_type=Diagonal_SE
      },
      'n_start=2' =>
      { Diagonal_SE      => 'A185669',
        # OEIS-Catalogue: A185669 planepath=PyramidSpiral,n_start=2 line_type=Diagonal_SE
      },
    };
}
{ package Math::PlanePath::TriangleSpiral;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'n_start=1' =>
      { X_axis      => 'A117625', # step by 2 each time
        Y_neg       => 'A006137', # step by 2 each time
        Diagonal_SW => 'A064225',
        Diagonal_SE => 'A081267',
        # OEIS-Other: A117625 planepath=TriangleSpiral
        # OEIS-Other: A064225 planepath=TriangleSpiral line_type=Diagonal_SW
        # OEIS-Other: A081267 planepath=TriangleSpiral line_type=Diagonal_SE

        # # Not quite, starts value=3 at n=0 which is path Y=1
        # Diagonal => 'A064226', # and duplicate in A081269
      },
      'n_start=0' =>
      { Y_axis      => 'A062741', # 3*pentagonal, Y even
        Diagonal    => 'A062708', # reading in direction 0,2,...
        Diagonal_SW => 'A062725', # reading in direction 0,7,...
        Diagonal_SE => 'A062728', # 11-gonal "second" per Math::NumSeq::Polygonal
        # OEIS-Catalogue: A062741 planepath=TriangleSpiral,n_start=0 line_type=Y_axis
        # OEIS-Catalogue: A062708 planepath=TriangleSpiral,n_start=0 line_type=Diagonal
        # OEIS-Catalogue: A062725 planepath=TriangleSpiral,n_start=0 line_type=Diagonal_SW
        # OEIS-Other:     A062728 planepath=TriangleSpiral,n_start=0 line_type=Diagonal_SE

        # but spaced 2 apart ...
        # X_axis      => 'A051682', # 11-gonals per Math::NumSeq::Polygonal
        # # OEIS-Other: A051682 planepath=TriangleSpiral,n_start=0 # X_axis
      },
    };
}
{ package Math::PlanePath::TriangleSpiralSkewed;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  # ENHANCE-ME: All these variously rotated for skew=right,up,down
  use constant _NumSeq_N_oeis_anum =>
    { 'skew=left,n_start=1' =>
      { X_axis      => 'A117625',
        X_neg       => 'A006137',
        Y_neg       => 'A064225',
        Diagonal    => 'A081589',
        Diagonal_SW => 'A038764',
        Diagonal_SE => 'A081267',
        # OEIS-Catalogue: A117625 planepath=TriangleSpiralSkewed
        # OEIS-Catalogue: A006137 planepath=TriangleSpiralSkewed line_type=X_neg
        # OEIS-Catalogue: A064225 planepath=TriangleSpiralSkewed line_type=Y_neg
        # OEIS-Catalogue: A081589 planepath=TriangleSpiralSkewed line_type=Diagonal
        # OEIS-Catalogue: A038764 planepath=TriangleSpiralSkewed line_type=Diagonal_SW
        # OEIS-Catalogue: A081267 planepath=TriangleSpiralSkewed line_type=Diagonal_SE
        # OEIS-Catalogue: A081274 planepath=TriangleSpiralSkewed line_type=Diagonal_SW

        # # Not quite, starts OFFSET=0 value=3 but that is at path Y=1
        # Y_axis      => 'A064226', # and duplicate in A081269
      },
      'skew=left,n_start=0' =>
      { X_axis      => 'A051682', # 11-gonals per Math::NumSeq::Polygonal
        Y_axis      => 'A062708', # reading in direction 0,2,...
        Y_neg       => 'A062725', # reading in direction 0,7,...
        Diagonal_SE => 'A062728', # 11-gonal "second" per Math::NumSeq::Polygonal
        Diagonal_SW => 'A081266',
        # OEIS-Other:     A051682 planepath=TriangleSpiralSkewed,n_start=0 # X_axis
        # OEIS-Other:     A062708 planepath=TriangleSpiralSkewed,n_start=0 line_type=Y_axis
        # OEIS-Other:     A062725 planepath=TriangleSpiralSkewed,n_start=0 line_type=Y_neg
        # OEIS-Other:     A062728 planepath=TriangleSpiralSkewed,n_start=0 line_type=Diagonal_SE
        # OEIS-Catalogue: A081266 planepath=TriangleSpiralSkewed,n_start=0 line_type=Diagonal_SW
      },
    };
}
{ package Math::PlanePath::DiamondSpiral;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'n_start=1' =>
      { X_axis => 'A130883', # 2*n^2-n+1
        X_neg  => 'A084849', # 2*n^2+n+1
        Y_axis => 'A058331', # 2*n^2 + 1
        Y_neg  => 'A001844', # centred squares 2n(n+1)+1
        # OEIS-Catalogue: A130883 planepath=DiamondSpiral
        # OEIS-Other:     A084849 planepath=DiamondSpiral line_type=X_neg
        # OEIS-Catalogue: A058331 planepath=DiamondSpiral line_type=Y_axis
        # OEIS-Other:     A001844 planepath=DiamondSpiral line_type=Y_neg
      },
      'n_start=0' =>
      { X_axis => 'A000384', # 2*n^2-n, hexagonal numbers
        X_neg  => 'A014105', # 2*n^2+n, hexagonal numbers second kind
        Y_axis => 'A001105', # 2*n^2
        Y_neg  => 'A046092', # 2n(n+1) = 4*triangular
        # OEIS-Other: A000384 planepath=DiamondSpiral,n_start=0
        # OEIS-Other: A014105 planepath=DiamondSpiral,n_start=0 line_type=X_neg
        # OEIS-Other: A001105 planepath=DiamondSpiral,n_start=0 line_type=Y_axis
        # OEIS-Other: A046092 planepath=DiamondSpiral,n_start=0 line_type=Y_neg
      },
    };
}
{ package Math::PlanePath::DiamondArms;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
}
{ package Math::PlanePath::AztecDiamondRings;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'n_start=1' =>
      { X_axis => 'A001844',  # centred squares 2n(n+1)+1
        # OEIS-Other: A001844 planepath=AztecDiamondRings

        # Not quite, A000384 has extra value=0
        # Y_axis => 'A000384', # hexagonal numbers
      },
      'n_start=0' =>
      { X_axis   => 'A046092',  # 4*triangular
        Diagonal => 'A139277',  # x*(8*x+5)
        # OEIS-Other: A046092 planepath=AztecDiamondRings,n_start=0
        # OEIS-Other: A139277 planepath=AztecDiamondRings,n_start=0 line_type=Diagonal
      },
    };
}
{ package Math::PlanePath::PentSpiral;
  use constant _NumSeq_X_axis_step => 2;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'n_start=1' =>
      { X_axis      => 'A192136', # (5*n^2-3*n+2)/2
        X_neg       => 'A116668', # (5n^2 + n + 2)/2
        Diagonal_SE => 'A005891', # centred pentagonal (5n^2+5n+2)/2
        # OEIS-Other: A192136 planepath=PentSpiral
        # OEIS-Other: A116668 planepath=PentSpiral line_type=X_neg
        # OEIS-Other: A005891 planepath=PentSpiral line_type=Diagonal_SE

        # Not quite, A134238 OFFSET=1 vs start X=0 here
        # Diagonal_SW => 'A134238',
      },

      'n_start=0' =>
      { X_axis      => 'A000566', # heptagonals
        Y_axis      => 'A005476',
        Diagonal_SE => 'A028895', # 5*triangular
        # OEIS-Other: A000566 planepath=PentSpiral,n_start=0
        # OEIS-Other: A005476 planepath=PentSpiral,n_start=0 line_type=Y_axis
        # OEIS-Other: A028895 planepath=PentSpiral,n_start=0 line_type=Diagonal_SE
      },
    };
}
{ package Math::PlanePath::PentSpiralSkewed;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'n_start=1' =>
      { X_axis      => 'A192136', # (5*n^2-3*n+2)/2
        X_neg       => 'A116668', # (5n^2 + n + 2)/2
        Diagonal_NW => 'A158187', # 10*n^2 + 1
        Diagonal_SE => 'A005891', # centred pentagonal (5n^2+5n+2)/2
        # OEIS-Catalogue: A192136 planepath=PentSpiralSkewed
        # OEIS-Catalogue: A116668 planepath=PentSpiralSkewed line_type=X_neg
        # OEIS-Catalogue: A158187 planepath=PentSpiralSkewed line_type=Diagonal_NW
        # OEIS-Catalogue: A005891 planepath=PentSpiralSkewed line_type=Diagonal_SE

        # Not quite, A140066 OFFSET=1 but path start Y=0 here
        # Y_axis => 'A140066', # (5n^2-11n+8)/2 but from Y=0 so using (n-1)

        # Not quite, A134238 OFFSET=1 but path start Y=0 here
        # Y_neg       => 'A134238',
        # # OEIS-Catalogue: A134238 planepath=PentSpiralSkewed line_type=Y_neg
      },

      'n_start=0' =>
      { X_axis      => 'A000566', # heptagonals
        Y_axis      => 'A005476',
        X_neg       => 'A005475',
        Diagonal_NW => 'A033583', # 10*n^2
        Diagonal_SE => 'A028895', # 5*triangular
        # OEIS-Other:     A000566 planepath=PentSpiralSkewed,n_start=0
        # OEIS-Catalogue: A005476 planepath=PentSpiralSkewed,n_start=0 line_type=Y_axis
        # OEIS-Catalogue: A005475 planepath=PentSpiralSkewed,n_start=0 line_type=X_neg
        # OEIS-Other:     A033583 planepath=PentSpiralSkewed,n_start=0 line_type=Diagonal_NW
        # OEIS-Catalogue: A028895 planepath=PentSpiralSkewed,n_start=0 line_type=Diagonal_SE

        # Not quite, A147875 OFFSET=1 vs start Y=0 here
        # Y_neg => 'A147875', # second heptagonals
        # # OEIS-Other: A147875 planepath=PentSpiralSkewed,n_start=0 line_type=Y_neg
      },
    };
}
{ package Math::PlanePath::HexSpiral;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  *_NumSeq_X_neg_increasing
    = \&Math::PlanePath::SquareSpiral::_NumSeq_X_neg_increasing;
  *_NumSeq_X_neg_increasing_from_i
    = \&Math::PlanePath::SquareSpiral::_NumSeq_X_neg_increasing_from_i;
  *_NumSeq_X_neg_min
    = \&Math::PlanePath::SquareSpiral::_NumSeq_X_neg_min;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'wider=0,n_start=1' =>
      { X_axis      => 'A056105', # first spoke 3n^2-2n+1
        Diagonal    => 'A056106', # second spoke 3n^2-n+1
        Diagonal_NW => 'A056107', # third spoke 3n^2+1
        X_neg       => 'A056108', # fourth spoke 3n^2+n+1
        Diagonal_SW => 'A056109', # fifth spoke 3n^2+2n+1
        Diagonal_SE => 'A003215', # centred hexagonal numbers
        # OEIS-Other:     A056105 planepath=HexSpiral
        # OEIS-Other:     A056106 planepath=HexSpiral line_type=Diagonal
        # OEIS-Other:     A056107 planepath=HexSpiral line_type=Diagonal_NW
        # OEIS-Other:     A056108 planepath=HexSpiral line_type=X_neg
        # OEIS-Other:     A056109 planepath=HexSpiral line_type=Diagonal_SW
        # OEIS-Other:     A003215 planepath=HexSpiral line_type=Diagonal_SE
      },
      'wider=0,n_start=0' =>
      { X_axis      => 'A000567', # octagonal numbers
        X_neg       => 'A049451',
        Diagonal    => 'A049450',
        Diagonal_NW => 'A033428', # octagonal numbers first,second average
        Diagonal_SW => 'A045944', # octagonal numbers second
        Diagonal_SE => 'A028896',
        # OEIS-Other:     A000567 planepath=HexSpiral,n_start=0
        # OEIS-Other:     A049451 planepath=HexSpiral,n_start=0 line_type=X_neg
        # OEIS-Catalogue: A049450 planepath=HexSpiral,n_start=0 line_type=Diagonal
        # OEIS-Other:     A033428 planepath=HexSpiral,n_start=0 line_type=Diagonal_NW
        # OEIS-Other:     A045944 planepath=HexSpiral,n_start=0 line_type=Diagonal_SW
        # OEIS-Catalogue: A028896 planepath=HexSpiral,n_start=0 line_type=Diagonal_SE
      },
    };
}
{ package Math::PlanePath::HexSpiralSkewed;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  *_NumSeq_X_neg_increasing
    = \&Math::PlanePath::SquareSpiral::_NumSeq_X_neg_increasing;
  *_NumSeq_X_neg_increasing_from_i
    = \&Math::PlanePath::SquareSpiral::_NumSeq_X_neg_increasing_from_i;
  *_NumSeq_X_neg_min
    = \&Math::PlanePath::SquareSpiral::_NumSeq_X_neg_min;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'wider=0,n_start=1' =>
      { X_axis      => 'A056105', # first spoke 3n^2-2n+1
        Y_axis      => 'A056106', # second spoke 3n^2-n+1
        Diagonal_NW => 'A056107', # third spoke 3n^2+1
        X_neg       => 'A056108', # fourth spoke 3n^2+n+1
        Y_neg       => 'A056109', # fifth spoke 3n^2+2n+1
        Diagonal_SE => 'A003215', # centred hexagonal numbers
        # OEIS-Catalogue: A056105 planepath=HexSpiralSkewed
        # OEIS-Catalogue: A056106 planepath=HexSpiralSkewed line_type=Y_axis
        # OEIS-Catalogue: A056108 planepath=HexSpiralSkewed line_type=X_neg
        # OEIS-Catalogue: A056109 planepath=HexSpiralSkewed line_type=Y_neg
        # OEIS-Catalogue: A056107 planepath=HexSpiralSkewed line_type=Diagonal_NW
        # OEIS-Other:     A003215 planepath=HexSpiralSkewed line_type=Diagonal_SE
      },
      'wider=0,n_start=0' =>
      { X_axis      => 'A000567', # octagonal numbers
        Y_axis      => 'A049450',
        X_neg       => 'A049451',
        Y_neg       => 'A045944', # octagonal numbers second
        Diagonal    => 'A062783',
        Diagonal_NW => 'A033428', # octagonal numbers first,second average
        Diagonal_SW => 'A063436',
        Diagonal_SE => 'A028896',
        # OEIS-Other:     A000567 planepath=HexSpiralSkewed,n_start=0
        # OEIS-Other:     A049450 planepath=HexSpiralSkewed,n_start=0 line_type=Y_axis
        # OEIS-Catalogue: A049451 planepath=HexSpiralSkewed,n_start=0 line_type=X_neg
        # OEIS-Other:     A045944 planepath=HexSpiralSkewed,n_start=0 line_type=Y_neg
        # OEIS-Catalogue: A062783 planepath=HexSpiralSkewed,n_start=0 line_type=Diagonal
        # OEIS-Other:     A033428 planepath=HexSpiralSkewed,n_start=0 line_type=Diagonal_NW
        # OEIS-Catalogue: A063436 planepath=HexSpiralSkewed,n_start=0 line_type=Diagonal_SW
        # OEIS-Other:     A028896 planepath=HexSpiralSkewed,n_start=0 line_type=Diagonal_SE
      },

      # wider=1 X_axis almost 3*n^2 but not initial X=0 value
      # wider=1 Y_axis almost A049451 twice pentagonal but not initial X=0
      # wider=2 Y_axis almost A028896 6*triangular but not initial Y=0
    };
}
{ package Math::PlanePath::HexArms;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
}
{ package Math::PlanePath::HeptSpiralSkewed;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    {
     # 'n_start=1' =>
     # {
     #  # Not quite, OFFSET=1 vs path start X=Y=0
     #  # Y_axis => 'A140065', # (7n^2 - 17n + 12)/2 but starting Y=0 not n=1
     #  # Diagonal_NW => 'A140063',
     #  # Diagonal_SE => 'A069099',
     # },

     'n_start=0' =>
     { X_axis      => 'A001106',  # 9-gonals
       Y_axis      => 'A218471',
       X_neg       => 'A022265',
       Y_neg       => 'A179986',  # second 9-gonals
       Diagonal    => 'A195023',
       Diagonal_NW => 'A022264',
       Diagonal_SW => 'A186029',
       Diagonal_SE => 'A024966',
       # OEIS-Other:     A001106 planepath=HeptSpiralSkewed,n_start=0
       # OEIS-Catalogue: A022265 planepath=HeptSpiralSkewed,n_start=0 line_type=X_neg
       # OEIS-Catalogue: A218471 planepath=HeptSpiralSkewed,n_start=0 line_type=Y_axis
       # OEIS-Other:     A179986 planepath=HeptSpiralSkewed,n_start=0 line_type=Y_neg
       # OEIS-Catalogue: A195023 planepath=HeptSpiralSkewed,n_start=0 line_type=Diagonal
       # OEIS-Catalogue: A022264 planepath=HeptSpiralSkewed,n_start=0 line_type=Diagonal_NW
       # OEIS-Catalogue: A186029 planepath=HeptSpiralSkewed,n_start=0 line_type=Diagonal_SW
       # OEIS-Catalogue: A024966 planepath=HeptSpiralSkewed,n_start=0 line_type=Diagonal_SE
     },
    };
}
{ package Math::PlanePath::OctagramSpiral;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    {
     'n_start=1' =>
     { Diagonal_SE => 'A194268',
       # OEIS-Other: A194268 planepath=OctagramSpiral line_type=Diagonal_SE

       # Not quite, but A125201 doesn't have initial N=1 for path origin
       # X_axis => 'A125201'
     },

     'n_start=0' =>
     { X_axis      => 'A051870',  # 18-gonals
       Y_axis      => 'A139273',
       X_neg       => 'A139275',
       Y_neg       => 'A139277',
       Diagonal    => 'A139272',
       Diagonal_NW => 'A139274',
       Diagonal_SW => 'A139276',
       Diagonal_SE => 'A139278',  # second 18-gonals
       # OEIS-Other:     A051870 planepath=OctagramSpiral,n_start=0
       # OEIS-Catalogue: A139273 planepath=OctagramSpiral,n_start=0 line_type=Y_axis
       # OEIS-Catalogue: A139275 planepath=OctagramSpiral,n_start=0 line_type=X_neg
       # OEIS-Catalogue: A139277 planepath=OctagramSpiral,n_start=0 line_type=Y_neg
       # OEIS-Catalogue: A139272 planepath=OctagramSpiral,n_start=0 line_type=Diagonal
       # OEIS-Catalogue: A139274 planepath=OctagramSpiral,n_start=0 line_type=Diagonal_NW
       # OEIS-Catalogue: A139276 planepath=OctagramSpiral,n_start=0 line_type=Diagonal_SW
       # OEIS-Other:     A139278 planepath=OctagramSpiral,n_start=0 line_type=Diagonal_SE
     },
    };
}
{ package Math::PlanePath::AnvilSpiral;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  *_NumSeq_X_neg_increasing
    = \&Math::PlanePath::SquareSpiral::_NumSeq_X_neg_increasing;
  *_NumSeq_X_neg_increasing_from_i
    = \&Math::PlanePath::SquareSpiral::_NumSeq_X_neg_increasing_from_i;
  *_NumSeq_X_neg_min
    = \&Math::PlanePath::SquareSpiral::_NumSeq_X_neg_min;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'wider=0,n_start=1' =>
      { X_axis      => 'A033570', # odd pentagonals (2n+1)*(3n+1)
        Diagonal    => 'A033568', # odd second pentagonals
        Diagonal_SE => 'A085473',
        # OEIS-Catalogue: A033570 planepath=AnvilSpiral
        # OEIS-Catalogue: A033568 planepath=AnvilSpiral line_type=Diagonal
        # OEIS-Catalogue: A085473 planepath=AnvilSpiral line_type=Diagonal_SE

        # Not quite, A136392 OFFSET=1 value=1 whereas path start Y=0 value=1
        # Y_neg       => 'A136392', # 1,9,29,61, 6n^2-10n+5
      },
      'wider=0,n_start=1,i_start=1' =>
      { Y_axis   => 'A126587', # points within 3,4,5 triangle, starting value=3
        # OEIS-Catalogue: A126587 planepath=AnvilSpiral line_type=Y_axis i_start=1
      },

      'wider=0,n_start=0' =>
      { X_axis      => 'A211014', # 14-gonal second
        Y_axis      => 'A139267', # 2*octagonal
        X_neg       => 'A049452', # alternate pentagonals
        Y_neg       => 'A033580', # 4*second pentagonals
        Diagonal    => 'A051866', # 14-gonals
        Diagonal_NW => 'A094159', # 3*hexagonal
        Diagonal_SW => 'A049453',
        Diagonal_SE => 'A195319', # 3*second hexagonal
        # OEIS-Other:     A211014 planepath=AnvilSpiral,n_start=0
        # OEIS-Other:     A051866 planepath=AnvilSpiral,n_start=0 line_type=Diagonal
        # OEIS-Catalogue: A139267 planepath=AnvilSpiral,n_start=0 line_type=Y_axis
        # OEIS-Catalogue: A049452 planepath=AnvilSpiral,n_start=0 line_type=X_neg
        # OEIS-Catalogue: A033580 planepath=AnvilSpiral,n_start=0 line_type=Y_neg
        # OEIS-Catalogue: A094159 planepath=AnvilSpiral,n_start=0 line_type=Diagonal_NW
        # OEIS-Catalogue: A049453 planepath=AnvilSpiral,n_start=0 line_type=Diagonal_SW
        # OEIS-Catalogue: A195319 planepath=AnvilSpiral,n_start=0 line_type=Diagonal_SE
      },

      # Not quite, A051866 starts value=0 which is at X=-1
      # 'wider=1,n_start=0' =>
      # { X_axis   => 'A051866',
      #   # OEIS-Other: A051866 planepath=AnvilSpiral,wider=1,n_start=0
      # },
      # 'wider=1,n_start=0' =>
      # { Diagonal_NW_minus_1  => 'A033569', # (2*n-1)*(3*n+1) starting -1
      #   # XX-Other: A033569 planepath=AnvilSpiral,wider=1,n_start=-1 line_type=Diagonal_NW
      # },

      # 'wider=2,n_start=1' =>
      # {
      #   Not quite, A033581 initial value=2 whereas path start N=0
      #   #   Y_axis => 'A033581', # 6*n^2 is 14-gonals pairs average in Math::NumSeq::Polygonal
      #   #   # OEIS-Other: A033581 planepath=AnvilSpiral,wider=2 line_type=Y_axis
      # },
    };
}
{ package Math::PlanePath::KnightSpiral;
  use constant _NumSeq_Diagonal_increasing => 1; # low then high
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
}
{ package Math::PlanePath::CretanLabyrinth;
  use constant _NumSeq_X_axis_increasing => 1;
}
{ package Math::PlanePath::SquareArms;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
}
{ package Math::PlanePath::SacksSpiral;
  use constant _NumSeq_X_axis_increasing   => 1;
  use constant _NumSeq_Y_axis_increasing   => 1; # when touched
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1; # when touched
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  # SacksSpiral X_axis -- squares (i-1)^2, starting from i=1 value=0
}
{ package Math::PlanePath::VogelFloret;
  use constant _NumSeq_X_axis_increasing   => 1; # when touched
  use constant _NumSeq_Y_axis_increasing   => 1; # when touched
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1; # when touched
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
}
{ package Math::PlanePath::TheodorusSpiral;
  use constant _NumSeq_X_axis_increasing   => 1; # when touched
  use constant _NumSeq_Y_axis_increasing   => 1; # when touched
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1; # when touched
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
}
{ package Math::PlanePath::ArchimedeanChords;
  use constant _NumSeq_X_axis_increasing   => 1; # when touched
  use constant _NumSeq_Y_axis_increasing   => 1; # when touched
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1; # when touched
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
}
{ package Math::PlanePath::MultipleRings;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1; # when touched
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1; # when touched
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
}
{ package Math::PlanePath::PixelRings;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1; # where covered
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
}
{ package Math::PlanePath::FilledRings;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  # use constant _NumSeq_N_oeis_anum =>
  #   {
  #    # Not quite, A036704 OFFSET=0 value=1,9,21 vs X=0 value=0,1,9,21
  #    'n_start=0' =>
  #    { X_axis => 'A036704', # count points norm <= n+1/2
  #    },
  #   };
}
{ package Math::PlanePath::Hypot;
  sub _NumSeq_X_axis_i_start {
    my ($self) = @_;
    ### _NumSeq_X_axis_i_start() ...
    return ($self->{'points'} eq 'odd'
            ? 1    # X=0,Y=0 not visited
            : 0);
  }
  sub _NumSeq_X_neg_i_start {
    my ($self) = @_;
    ### _NumSeq_X_axis_i_start() ...
    return ($self->{'points'} eq 'odd'
            ? -1    # X=0,Y=0 not visited
            : 0);
  }
  *_NumSeq_Y_axis_i_start = \&_NumSeq_X_axis_i_start;
  *_NumSeq_Y_neg_i_start  = \&_NumSeq_X_neg_i_start;

  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'points=all,n_start=0' =>
      { X_axis => 'A051132', # count points < n^2
        # OEIS-Catalogue: A051132 planepath=Hypot,n_start=0
      },
    };
}
{ package Math::PlanePath::HypotOctant;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  *_NumSeq_X_axis_i_start = \&Math::PlanePath::Hypot::_NumSeq_X_axis_i_start;

  use constant _NumSeq_N_oeis_anum =>
    { 'points=even' =>
      { Diagonal => 'A036702',  # count points |z|<=n for 0<=b<=a
        # OEIS-Catalogue: A036702 planepath=HypotOctant,points=even line_type=Diagonal
      },
    };
}
{ package Math::PlanePath::TriangularHypot;
  sub _NumSeq_X_axis_i_start {
    my ($self) = @_;
    return ($self->{'points'} eq 'odd' || $self->{'points'} eq 'hex_centred'
            ? 1    # X=0,Y=0 not visited
            : 0);
  }
  *_NumSeq_Diagonal_i_start = \&_NumSeq_X_axis_i_start;
  *_NumSeq_Diagonal_SE_i_start = \&_NumSeq_X_axis_i_start;
  sub _NumSeq_X_neg_i_start {
    my ($self) = @_;
    return - $self->_NumSeq_X_axis_i_start;
  }
  *_NumSeq_Diagonal_NW_i_start = \&_NumSeq_X_axis_i_start;
  *_NumSeq_Diagonal_SW_i_start = \&_NumSeq_X_axis_i_start;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
}
{ package Math::PlanePath::PythagoreanTree;
  use constant _NumSeq_X_axis_increasing => 1;

  use constant _NumSeq_N_oeis_all_anum =>
    { Depth_start => 'A007051', # (3^n+1)/2
      # OEIS-Catalogue: A007051 planepath=PythagoreanTree line_type=Depth_start

      # Not quite, Depth_end=(3^(n+1)-1)/2, so is n+1
      # Depth_end   => 'A003462', # (3^n-1)/2
    };
}
{ package Math::PlanePath::RationalsTree;
  use constant _NumSeq_X_axis_increasing => 1;

  sub _NumSeq_Y_axis_increasing {
    my ($self) = @_;
    return ($self->{'tree_type'} eq 'L' ? 0 : 1);
  }
  sub _NumSeq_Y_axis_increasing_from_i {
    my ($self) = @_;
    return ($self->{'tree_type'} eq 'L' ? 2 : 1);
  }
  use constant _NumSeq_Y_axis_min => 1;
  use constant _NumSeq_Diagonal_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'tree_type=SB' =>
      { Depth_start => 'A000079', # powers-of-2
        # RationalsTree SB -- X_axis 2^n-1 but starting X=1
        # RationalsTree SB,CW -- Y_axis A000079 2^n but starting Y=1
      },

      'tree_type=CW' =>
      { Depth_start => 'A000079', # powers-of-2
      },

      'tree_type=Bird' =>
      { X_axis      => 'A081254', # local max sumdisttopow2(m)/m^2
        Depth_start => 'A000079', # powers-of-2
        # OEIS-Catalogue: A081254 planepath=RationalsTree,tree_type=Bird
        # OEIS-Other:     A000079 planepath=RationalsTree,tree_type=Bird line_type=Depth_start

        # RationalsTree Bird -- Y_axis almost A000975 10101 101010 no
        # consecutive equal bits, but start=1
      },

      'tree_type=Drib' =>
      { X_axis      => 'A086893', # pos of fibonacci F(n+1)/F(n) in Stern diatomic
        Depth_start => 'A000079', # powers-of-2
        # OEIS-Catalogue: A086893 planepath=RationalsTree,tree_type=Drib

        # Drib Y_axis
        # Not quite, A061547 OFFSET=1 value=0 cf path Y=1 value N=1
        # Y_axis => 'A061547'# derangements or alternating bits plus pow4
      },

      'tree_type=AYT' =>
      { Depth_start => 'A000079', # powers-of-2
        # RationalsTree AYT -- Y_axis A083318 2^n+1 but starting Y=1
      },

      'tree_type=HCS' =>
      { Depth_start => 'A000079', # powers-of-2

        # RationalsTree HCS
        # Not quite, A000079 OFFSET=0 value=1 cf here X=1 N=1
        # X_axis => 'A000079',  # powers 2^X
        # Not quite, A007283 OFFSET=0 and doesn't have extra N=1 at Y=1
        # Y_axis => 'A007283', # 3*2^n starting OFFSET=0 value=3
      },
    };
}
{ package Math::PlanePath::FractionsTree;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_X_offset => -1;

  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Y_axis_i_start => 2;
}
{ package Math::PlanePath::ChanTree;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_X_axis_i_start => 1;

  use constant _NumSeq_Y_axis_i_start => 1;  # start at Y=1
  use constant _NumSeq_Y_axis_increasing => 1;

  use constant _NumSeq_Diagonal_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'k=2,n_start=1' =>
      { Depth_start => 'A000079', # powers-of-2
        # OEIS-Other: A000079 planepath=ChanTree,n_start=1,k=2 line_type=Depth_start

        # Depth_end is 2^k-1 A000225, or 2^k-2 A000918, but without initial
        # 0 or -1.
      },
      'k=2,n_start=0' =>
      { Depth_start => 'A000225', # 2^k-1
        # OEIS-Other: A000225 planepath=ChanTree,k=2 line_type=Depth_start
      },

      'k=3,n_start=1' =>
      { Depth_start => 'A000244', # powers-of-3
        # OEIS-Other: A000244 planepath=ChanTree,n_start=1 line_type=Depth_start
      },
      'k=4,n_start=1' =>
      { Depth_start => 'A000302', # powers-of-4
        # OEIS-Other: A000302 planepath=ChanTree,n_start=1,k=4 line_type=Depth_start
      },
      'k=5,n_start=1' =>
      { Depth_start => 'A000351', # powers-of-5
        # OEIS-Other: A000351 planepath=ChanTree,n_start=1,k=5 line_type=Depth_start
      },
      'k=10,n_start=1' =>
      { Depth_start => 'A011557', # powers-of-10
        # OEIS-Other: A011557 planepath=ChanTree,n_start=1,k=10 line_type=Depth_start
      },
    };
}
{ package Math::PlanePath::DiagonalRationals;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_axis_i_start => 1;
  use constant _NumSeq_Y_axis_i_start => 1;

  # Diagonal => 'A002088', # cumulative totient
  # Not quite, start X=1 value=1 cf seq OFFSET=0 value=0
}
{ package Math::PlanePath::FactorRationals;
  use constant _NumSeq_X_axis_i_start => 1;
  sub _NumSeq_X_axis_increasing {
    my ($self) = @_;
    # perfect squares along X axis of even/odd
    return $self->{'factor_coding'} eq 'even/odd';
  }

  use constant _NumSeq_Y_axis_i_start => 1;
  sub _NumSeq_Y_axis_increasing {
    my ($self) = @_;
    # perfect squares along Y axis of odd/even
    return $self->{'factor_coding'} eq 'odd/even';
  }

  use constant _NumSeq_N_oeis_anum =>
    { 'factor_coding=even/odd' =>
      { Y_axis => 'A102631', # n^2/(squarefree kernel)
        # OEIS-Catalogue: A102631 planepath=FactorRationals line_type=Y_axis

        # # Not quite, OFFSET=0 value 0 whereas start X=Y=1 value 1 here
        # X_axis => 'A000290',  # squares 0,1,4,9
        # # OEIS-Other: A000290 planepath=FactorRationals
      },
      'factor_coding=odd/even' =>
      { X_axis => 'A102631', # n^2/(squarefree kernel)
        # OEIS-Other: A102631 planepath=FactorRationals,factor_coding=odd/even
      },
    };
}
{ package Math::PlanePath::GcdRationals;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_axis_i_start => 1;
  use constant _NumSeq_Y_axis_i_start => 1;

  # GcdRationals
  # Not quite, starts X=1
  # X_axis => triangular row
  # Not quite, starts X=1 here cf OFFSET=0 in A000124
  # Y_axis => 'A000124', # triangular+1
  #
  # GcdRationals,pairs_order=diagonals_down
  # Not quite, start X=1 here cf A000290 starts OFFSET=1
  # X_axis => 'A000290', # Y=1 row, perfect squares
  # Not quite, A033638 starts two ones 1,1,...
  # Y_axis => 'A033638', # quarter-squares + 1
  #
  # GcdRationals,pairs_order=diagonals_up
  # Not quite, A002061 starts two ones 1,1,
  # X_axis => 'A002061',
  # Not quite, X=1 column squares+pronic, but no initial 0,0 of A002620
  # Y_axis => 'A002620', # X=1 column
  # Not quite, starting value=2 here
  # Diagonal_above => 'A002522', # Y=X+1 diagonal, squares+1
}
{ package Math::PlanePath::CfracDigits;
  #                          1
  # diagonal Y/(Y+1) = 0 + -----
  #                        1 + 1/Y
  # q0=1 q1=Y
  # N = 3,Y-1   in 1,2,3
  #   = 1,0,Y-1   in 0,1,2
  #
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_X_offset => -1;
  use constant _NumSeq_Y_axis_increasing => 1;  # radix without digit 0
}
{ package Math::PlanePath::PeanoCurve;
  sub _NumSeq_X_axis_increasing {
    my ($self) = @_;
    return ($self->{'radix'} % 2);
  }
  *_NumSeq_Y_axis_increasing = \&_NumSeq_X_axis_increasing;

  use constant _NumSeq_N_oeis_anum =>
    { 'radix=3' =>
      { X_axis   => 'A163480', # axis same as initial direction
        Y_axis   => 'A163481', # axis opp to initial direction
        Diagonal => 'A163343',
      },
      # OEIS-Catalogue: A163480 planepath=PeanoCurve
      # OEIS-Catalogue: A163481 planepath=PeanoCurve line_type=Y_axis
      # OEIS-Catalogue: A163343 planepath=PeanoCurve line_type=Diagonal

      # OEIS-Other: A163480 planepath=GrayCode,apply_type=TsF,radix=3
      # OEIS-Other: A163481 planepath=GrayCode,apply_type=TsF,radix=3 line_type=Y_axis
      # OEIS-Other: A163343 planepath=GrayCode,apply_type=TsF,radix=3 line_type=Diagonal

      # OEIS-Other: A163480 planepath=GrayCode,apply_type=FsT,radix=3
      # OEIS-Other: A163481 planepath=GrayCode,apply_type=FsT,radix=3 line_type=Y_axis
      # OEIS-Other: A163343 planepath=GrayCode,apply_type=FsT,radix=3 line_type=Diagonal
    };
}
{ package Math::PlanePath::WunderlichSerpentine;
  sub _NumSeq_X_axis_increasing {
    my ($self) = @_;
    if ($self->{'radix'} % 2) {
      return 1;  # odd radix always increasing
    }
    # FIXME: depends on the serpentine_type bits
    return 0;
  }
  sub _NumSeq_Y_axis_increasing {
    my ($self) = @_;
    if ($self->{'radix'} % 2) {
      return 1;  # odd radix always increasing
    }
    # FIXME: depends on the serpentine_type bits
    return 0;
  }
}
{ package Math::PlanePath::HilbertCurve;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { '' =>
      { X_axis   => 'A163482',
        Y_axis   => 'A163483',
        Diagonal => 'A062880', # base 4 digits 0,2 only
        # OEIS-Catalogue: A163482 planepath=HilbertCurve
        # OEIS-Catalogue: A163483 planepath=HilbertCurve line_type=Y_axis
        # OEIS-Other:     A062880 planepath=HilbertCurve line_type=Diagonal
      },
    };
}
{ package Math::PlanePath::HilbertSides;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { '' =>
      { Diagonal => 'A062880', # base 4 digits 0,2 only
        # OEIS-Other: A062880 planepath=HilbertSides line_type=Diagonal
      },
    };
}
{ package Math::PlanePath::HilbertSpiral;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
}
{ package Math::PlanePath::ZOrderCurve;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'radix=2' =>
      { X_axis   => 'A000695',  # base 4 digits 0,1 only (RadixConversion)
        Y_axis   => 'A062880',  # base 4 digits 0,2 only
        Diagonal => 'A001196',  # base 4 digits 0,3 only
        # OEIS-Other:     A000695 planepath=ZOrderCurve
        # OEIS-Catalogue: A062880 planepath=ZOrderCurve line_type=Y_axis
        # OEIS-Catalogue: A001196 planepath=ZOrderCurve line_type=Diagonal
      },
      'radix=3,i_start=1' =>
      { X_axis => 'A037314',  # base 9 digits 0,1,2 only, starting OFFSET=1 value=1
        Y_axis => 'A208665',  # base 9 digits 0,3,6 only, starting OFFSET=1 value=3
        # OEIS-Catalogue: A037314 planepath=ZOrderCurve,radix=3 i_start=1
        # OEIS-Catalogue: A208665 planepath=ZOrderCurve,radix=3 i_start=1 line_type=Y_axis

        # ZOrderCurve dir=2  radix,3: match 6,27,30,33,54,57,60,243,246,249,270,273,276,297,300
        # A208665 Numbers that match odd ternary polynomials; see Comments.
        # A208665 ,3,6,27,30,33,54,57,60,243,246,249,270,273,276,297,300,303,486,489,492,513,516,519,540,543,546,2187,2190,2193,2214,2217,2220,2241,2244,2247,2430,2433,2436,2457,2460,2463,2484,2487,2490,2673,2676,2679,
        # base 9 digits 0,3,6 only
      },
      'radix=10' =>
      { X_axis => 'A051022',  # base 10 insert 0s, for digits 0 to 9 base 100
        # OEIS-Catalogue: A051022 planepath=ZOrderCurve,radix=10
      },
    };
}
{ package Math::PlanePath::GrayCode;

  # X axis increasing for:
  # radix=2 TsF,Fs
  # radix=3 reflected TsF,FsT
  #  radix=3 modular TsF,Fs
  # radix=4 reflected TsF,Fs
  #  radix=4 modular TsF,Fs
  # radix=5 reflected TsF,FsT
  #  radix=5 modular TsF,Fs
  #
  sub _NumSeq_X_axis_increasing {
    my ($self) = @_;
    if ($self->{'gray_type'} eq 'modular' || $self->{'radix'} == 2) {
      return ($self->{'apply_type'} eq 'TsF'
              || $self->{'apply_type'} eq 'Fs');
    }
    if ($self->{'radix'} & 1) {
      return ($self->{'apply_type'} eq 'TsF'
              || $self->{'apply_type'} eq 'FsT');
    } else {
      return ($self->{'apply_type'} eq 'TsF'
              || $self->{'apply_type'} eq 'Fs');
    }
  }
  *_NumSeq_Y_axis_increasing = \&_NumSeq_X_axis_increasing;

  # Diagonal increasing for:
  # radix=2 FsT,Ts
  # radix=3 reflected Ts,Fs
  #  radix=3 modular FsT
  # radix=4 reflected FsT,Ts
  #  radix=4 modular FsT
  # radix=5 reflected Ts,Fs
  #  radix=5 modular FsT
  sub _NumSeq_Diagonal_increasing {
    my ($self) = @_;
    if ($self->{'radix'} & 1) {
      if ($self->{'gray_type'} eq 'modular') {
        return ($self->{'apply_type'} eq 'FsT');  # odd modular
      } else {
        return ($self->{'apply_type'} eq 'Ts'
                || $self->{'apply_type'} eq 'Fs');  # odd reflected
      }
    }
    if ($self->{'gray_type'} eq 'reflected' || $self->{'radix'} == 2) {
      return ($self->{'apply_type'} eq 'FsT'
              || $self->{'apply_type'} eq 'Ts');  # even reflected
    } else {
      return ($self->{'apply_type'} eq 'FsT');  # even modular
    }
  }

  use constant _NumSeq_N_oeis_anum =>
    {
     'apply_type=TsF,gray_type=reflected,radix=3' =>
     (Math::PlanePath::PeanoCurve->_NumSeq_N_oeis_anum->{'radix=3'}
      || die "Oops, SquareSpiral NumSeq PlanePathN not found"),
     'apply_type=FsT,gray_type=reflected,radix=3' =>
     (Math::PlanePath::PeanoCurve->_NumSeq_N_oeis_anum->{'radix=3'}
      || die "Oops, SquareSpiral NumSeq PlanePathN not found"),

     # GrayCode radix=2 TsF==Fs reflected==modular
     do {
       my $href =
         { Y_axis => 'A001196',  # base 4 digits 0,3 only
         };
       ('apply_type=TsF,gray_type=reflected,radix=2' => $href,
        'apply_type=Fs,gray_type=reflected,radix=2' => $href,
        'apply_type=TsF,gray_type=modular,radix=2' => $href,
        'apply_type=Fs,gray_type=modular,radix=2' => $href,
       );
       # OEIS-Other: A001196 planepath=GrayCode,apply_type=TsF line_type=Y_axis
       # OEIS-Other: A001196 planepath=GrayCode,apply_type=Fs line_type=Y_axis
       # OEIS-Other: A001196 planepath=GrayCode,apply_type=TsF,gray_type=modular line_type=Y_axis
       # OEIS-Other: A001196 planepath=GrayCode,apply_type=Fs,gray_type=modular line_type=Y_axis
     },
     # GrayCode radix=2 Ts==FsT reflected==modular
     do {
       my $href =
         { Diagonal => 'A062880',  # base 4 digits 0,2 only
         };
       ('apply_type=Ts,gray_type=reflected,radix=2' => $href,
        'apply_type=Ts,gray_type=modular,radix=2' => $href,
        'apply_type=FsT,gray_type=reflected,radix=2' => $href,
        'apply_type=FsT,gray_type=modular,radix=2' => $href,
       );
       # OEIS-Other: A062880 planepath=GrayCode,apply_type=Ts line_type=Diagonal
       # OEIS-Other: A062880 planepath=GrayCode,apply_type=Ts,gray_type=modular line_type=Diagonal
       # OEIS-Other: A062880 planepath=GrayCode,apply_type=FsT line_type=Diagonal
       # OEIS-Other: A062880 planepath=GrayCode,apply_type=FsT,gray_type=modular line_type=Diagonal
     },

     # GrayCode radix=3 sT==sF reflected
     # N split then toGray giving Y=0 means N ternary 010202 etc
     # N split then toGray giving X=Y means N ternary pairs 112200
     do {
       my $href =
         { X_axis   => 'A163344',  # central Peano/4, base9 digits 0,1,2 only
           Diagonal => 'A163343',  # central diagonal of Peano, base9 0,4,8
         };
       ('apply_type=sT,gray_type=reflected,radix=3' => $href,
        'apply_type=sF,gray_type=reflected,radix=3' => $href,
       );
       # OEIS-Catalogue: A163344 planepath=GrayCode,apply_type=sT,radix=3
       # OEIS-Other:     A163344 planepath=GrayCode,apply_type=sF,radix=3

       # OEIS-Other: A163343 planepath=GrayCode,apply_type=sT,radix=3 line_type=Diagonal
       # OEIS-Other: A163343 planepath=GrayCode,apply_type=sF,radix=3 line_type=Diagonal
     },

     'apply_type=FsT,gray_type=modular,radix=3,i_start=1' =>
     { Diagonal => 'A208665',  # base 9 digits 0,3,6
       # OEIS-Other: A208665 planepath=GrayCode,apply_type=FsT,gray_type=modular,radix=3 line_type=Diagonal i_start=1
     },
    };
}
# { package Math::PlanePath::ImaginaryBase;
# }
{ package Math::PlanePath::ImaginaryHalf;
  use constant _NumSeq_Y_axis_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'radix=2,digit_order=YXX' =>
      { Y_axis   => 'A033045',  # base 8 digits 0,1 only
        # OEIS-Other: A033045 planepath=ImaginaryHalf,digit_order=YXX line_type=Y_axis
      },
      'radix=2,digit_order=YXnX' =>
      { Y_axis   => 'A033045',  # base 8 digits 0,1 only
        # OEIS-Other: A033045 planepath=ImaginaryHalf,digit_order=YXnX line_type=Y_axis
      },
    };
}
# { package Math::PlanePath::CubicBase;
# }
{ package Math::PlanePath::DekkingCurve;
  sub _NumSeq_X_axis_increasing {
    my ($self) = @_;
    # arms=4 has various interleaving
    return $self->{'arms'} < 4;
  }
  sub _NumSeq_X_neg_increasing {
    my ($self) = @_;
    # arms=3 has various interleaving
    return $self->{'arms'} < 3;
  }
  sub _NumSeq_Y_axis_increasing {
    my ($self) = @_;
    # arms=2 has various interleaving
    return $self->{'arms'} < 2;
  }
  sub _NumSeq_Y_neg_increasing {
    my ($self) = @_;
    # arms=4 has various interleaving
    return $self->{'arms'} < 4;
  }
}
{ package Math::PlanePath::DekkingCentres;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
}
{ package Math::PlanePath::CincoCurve;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
}
{ package Math::PlanePath::BetaOmega;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
}
{ package Math::PlanePath::KochelCurve;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
}
{ package Math::PlanePath::AR2W2Curve;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
}
{ package Math::PlanePath::WunderlichMeander;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
}
# { package Math::PlanePath::Flowsnake;
# }
# { package Math::PlanePath::FlowsnakeCentres;
#   # inherit from Flowsnake
# }
# { package Math::PlanePath::GosperIslands;
# }
# { package Math::PlanePath::GosperSide;
# }
{ package Math::PlanePath::KochCurve;
  use constant _NumSeq_X_axis_increasing   => 1; # when touched
  use constant _NumSeq_Y_axis_increasing   => 1; # when touched
  use constant _NumSeq_Diagonal_increasing => 1; # when touched
}
{ package Math::PlanePath::KochPeaks;
  use constant _NumSeq_X_axis_increasing => 1; # when touched
  use constant _NumSeq_Y_axis_increasing => 1; # when touched
  use constant _NumSeq_X_neg_increasing  => 1; # when touched
  # Diagonal never touched
}
{ package Math::PlanePath::KochSnowflakes;
  use constant _NumSeq_X_axis_increasing   => 1; # when touched
  use constant _NumSeq_Y_axis_increasing   => 1; # when touched
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1; # when touched
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
}
{ package Math::PlanePath::KochSquareflakes;
  use constant _NumSeq_X_axis_increasing   => 1; # when touched
  use constant _NumSeq_Y_axis_increasing   => 1; # when touched
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1; # when touched
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
}
{ package Math::PlanePath::QuadricCurve;
  use constant _NumSeq_X_axis_increasing   => 1; # when touched
  use constant _NumSeq_Diagonal_increasing => 1; # two values only
}
{ package Math::PlanePath::QuadricIslands;
  # FIXME: pred() on Diagonal_SW doesn't notice 0.5 square
  use constant _NumSeq_X_axis_increasing   => 1; # when touched
  use constant _NumSeq_Y_axis_increasing   => 1;

  use constant _NumSeq_X_neg_increasing => 1;

  use constant _NumSeq_Y_neg_increasing        => 0;
  use constant _NumSeq_Y_neg_increasing_from_i => 1; # after 3,2,8
  use constant _NumSeq_Y_neg_min => 2; # at X=-1,Y=0 rather than X=0,Y=0
  use constant _NumSeq_Diagonal_SW_increasing => 0;
  use constant _NumSeq_Diagonal_SW_min => 1;
}
{ package Math::PlanePath::SierpinskiTriangle;
  use constant _NumSeq_X_axis_increasing   => 1; # for "diagonal" style
  use constant _NumSeq_Y_axis_increasing   => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;

  # low 10111=23 increment to 11000=24
  # 10111 ones=4 width=2^4

  # cf A160722 is 3*A006046-2*n, drawing three Sierpinski triangles
  #    http://www.polprimos.com/imagenespub/polca722.jpg
  #
  use constant _NumSeq_N_oeis_anum =>
    {
     #---------
     # i_start=0, n_start=0

     'align=triangular,n_start=0' =>
     { Diagonal_NW => 'A006046',
       Depth_start => 'A006046',
       # OEIS-Other: A006046 planepath=SierpinskiTriangle line_type=Diagonal_NW
       # OEIS-Other: A006046 planepath=SierpinskiTriangle line_type=Depth_start
     },
     'align=right,n_start=0' =>
     { Y_axis      => 'A006046',
       Depth_start => 'A006046',
       # OEIS-Catalogue: A006046 planepath=SierpinskiTriangle,align=diagonal,n_start=0 line_type=Y_axis
     },
     'align=left,n_start=0' =>
     { Diagonal_NW => 'A006046',
       Depth_start => 'A006046',
       # OEIS-Other: A006046 planepath=SierpinskiTriangle,align=left,n_start=0 line_type=Diagonal_NW
     },
     'align=diagonal,n_start=0' =>
     { Y_axis      => 'A006046',
       Depth_start => 'A006046',
       # OEIS-Other: A006046 planepath=SierpinskiTriangle,align=diagonal,n_start=0 line_type=Y_axis
     },

     #---------
     # i_start=1, n_start=0

     # starting OFFSET=1 value=2,4,8,10 so missing N=0 at Y=0, hence i_start=1
     'align=triangular,n_start=0,i_start=1' =>
     { Diagonal  => 'A074330',
       Depth_end => 'A074330',
       # OEIS-Catalogue: A074330 planepath=SierpinskiTriangle line_type=Diagonal i_start=1
       # OEIS-Other:     A074330 planepath=SierpinskiTriangle line_type=Depth_end i_start=1
     },
     'align=right,n_start=0,i_start=1' =>
     { Diagonal  => 'A074330',
       Depth_end => 'A074330',
       # OEIS-Other: A074330 planepath=SierpinskiTriangle,align=right line_type=Diagonal i_start=1
     },
     'align=left,n_start=0,i_start=1' =>
     { Y_axis    => 'A074330',
       Depth_end => 'A074330',
       # OEIS-Other: A074330 planepath=SierpinskiTriangle,align=left line_type=Y_axis i_start=1
     },
     'align=diagonal,n_start=0,i_start=1' =>
     { X_axis    => 'A074330',
       Depth_end => 'A074330',
       # OEIS-Other: A074330 planepath=SierpinskiTriangle,align=diagonal i_start=1
     },
    };
}
{ package Math::PlanePath::SierpinskiArrowhead;
  use constant _NumSeq_Y_axis_increasing   => 1; # when touched
  use constant _NumSeq_Diagonal_increasing => 1; # when touched
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  # align="diagonal" is X increasing, other align is single origin point only
  use constant _NumSeq_X_axis_increasing => 1;
}
{ package Math::PlanePath::SierpinskiArrowheadCentres;
  use constant _NumSeq_Y_axis_increasing   => 1; # never touched ?
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  # align="diagonal" is X increasing, other align is single origin point only
  use constant _NumSeq_X_axis_increasing => 1;
}
{ package Math::PlanePath::SierpinskiCurve;
  use constant _NumSeq_X_axis_increasing => 1; # when touched
  use constant _NumSeq_X_axis_i_start => 1;  # but not all cells visited

  use constant _NumSeq_Y_axis_increasing => 1; # when touched
  use constant _NumSeq_Y_axis_i_start => 1;  # but not all cells visited

  use constant _NumSeq_X_neg_increasing => 1; # arms
  use constant _NumSeq_Y_neg_increasing => 1; # arms

  use constant _NumSeq_Diagonal_increasing => 1; # when touched
  use constant _NumSeq_Diagonal_NW_increasing => 1;

  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
}
{ package Math::PlanePath::SierpinskiCurveStair;
  use constant _NumSeq_X_axis_increasing => 1; # when touched
  use constant _NumSeq_Y_axis_increasing => 1; # when touched
  use constant _NumSeq_X_neg_increasing => 1; # arms
  use constant _NumSeq_Y_neg_increasing => 1; # arms
  use constant _NumSeq_Diagonal_increasing => 1; # when touched
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
}
{ package Math::PlanePath::HIndexing;
  use constant _NumSeq_X_axis_increasing => 1; # when touched
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1; # when touched
}
# { package Math::PlanePath::DragonCurve;
# }
# { package Math::PlanePath::DragonRounded;
# }
# { package Math::PlanePath::DragonMidpoint;
# }
{ package Math::PlanePath::AlternatePaper;
  use constant _NumSeq_X_axis_increasing   => 1;
  use constant _NumSeq_Y_axis_increasing   => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1; # arms
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
  # selecting the smaller N on the negative axes gives increasing, maybe
  use constant _NumSeq_X_neg_increasing   => 1;
  use constant _NumSeq_Y_neg_increasing   => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'arms=1' =>
      { X_axis   => 'A000695',  # base 4 digits 0,1 only
        Diagonal => 'A062880',  # base 4 digits 0,2 only
        # OEIS-Other: A000695 planepath=AlternatePaper
        # OEIS-Other: A062880 planepath=AlternatePaper line_type=Diagonal
      },
      # FIXME: not sure what to do when multiple-visited points on axes
      # 'arms=2' =>
      # { X_axis   => 'A062880',  # base 4 digits 0,2 only
      #   Y_axis   => 'A145812',  # base 4 digits 0,2 only except low digit 1,3 only
      #   # OEIS-Other:     A062880 planepath=AlternatePaper,arms=2
      #   # OEIS-Catalogue: A145812 planepath=AlternatePaper,arms=2 line_type=Y_axis
      # },
      # 'arms=3' =>
      # { X_axis   => 'A001196',  # base 4 digits 0,3 only
      #   # OEIS-Other: A001196 planepath=AlternatePaper,arms=3
      # },
      #
      # alt paper arms=4 diagonal, arms=8 x axis
      # A127988 # base 8 digits 0,4 only
    };
}
{ package Math::PlanePath::AlternatePaperMidpoint;
  use constant _NumSeq_X_axis_increasing   => 1;
  use constant _NumSeq_Y_axis_increasing   => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1; # arms
  use constant _NumSeq_Diagonal_SE_increasing => 1; # arms
}
# { package Math::PlanePath::TerdragonCurve;
# }
# { package Math::PlanePath::TerdragonRounded;
# }
# { package Math::PlanePath::TerdragonMidpoint;
# }
# { package Math::PlanePath::R5DragonCurve;
# }
# { package Math::PlanePath::R5DragonMidpoint;
# }
# { package Math::PlanePath::CCurve;
# }
# { package Math::PlanePath::ComplexPlus;
# }
{ package Math::PlanePath::ComplexMinus;
  use constant _NumSeq_N_oeis_anum =>
    { 'realpart=1' =>
      { X_axis => 'A066321', # binary base i-1
        X_neg  => 'A256441', # binary base i-1
        # OEIS-Catalogue: A066321 planepath=ComplexMinus
        # OEIS-Catalogue: A256441 planepath=ComplexMinus line_type=X_neg
        # cf A066323 count of 1-bits in N on X axis
      },
    };
}
# { package Math::PlanePath::ComplexRevolving;
# }
{ package Math::PlanePath::Rows;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Y_neg_min => undef; # negatives
  use constant _NumSeq_Y_neg_max => 1;     # negatives

  # secret negatives
  # (w-1)*(w-1)-1
  # = w^2-2w+1-1
  # = w(w-2)
  sub _NumSeq_Diagonal_SE_min {
    my ($self) = @_;
    return ($self->{'width'}-2)*$self->{'width'};
  }

  use constant _NumSeq_N_oeis_anum =>
    {
     'n_start=0,width=1' =>
     { X_axis   => 'A001477',  # integers 0,1,2,3,etc
       # OEIS-Other: A001477 planepath=Rows,width=1,n_start=0
     },
     'n_start=1,width=2' =>
     { Y_axis   => 'A005408',  # odd 2n+1
       # OEIS-Other: A005408 planepath=Rows,width=2 line_type=Y_axis
     },
     'n_start=1,width=3' =>
     { Y_axis   => 'A016777',  # 3n+1
       # OEIS-Catalogue: A016777 planepath=Rows,width=3 line_type=Y_axis
     },
     'n_start=1,width=4' =>
     { Y_axis   => 'A016813',  # 4n+1
       # OEIS-Catalogue: A016813 planepath=Rows,width=4 line_type=Y_axis
     },

     'n_start=1,width=5' =>
     { Y_axis   => 'A016861',  # 5n+1
       # OEIS-Catalogue: A016861 planepath=Rows,width=5 line_type=Y_axis
     },
     'n_start=1,width=6' =>
     { Y_axis   => 'A016921',  # 6n+1
       # OEIS-Catalogue: A016921 planepath=Rows,width=6 line_type=Y_axis
     },
     'n_start=1,width=7' =>
     { Y_axis   => 'A016993',  # 7n+1
       # OEIS-Catalogue: A016993 planepath=Rows,width=7 line_type=Y_axis
     },
    };
}
{ package Math::PlanePath::Columns;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_X_neg_min => undef; # negatives
  use constant _NumSeq_X_neg_max => 1;     # negatives

  sub _NumSeq_Diagonal_NW_min {
    my ($self) = @_;
    # secret negatives
    return ($self->{'height'}-2)*$self->{'height'};
  }
  use constant _NumSeq_N_oeis_anum =>
    {
     'n_start=0,height=1' =>
     { X_axis   => 'A001477',  # integers 0,1,2,3,etc
       # OEIS-Other: A001477 planepath=Columns,height=1,n_start=0
     },
     'n_start=1,height=2' =>
     { X_axis   => 'A005408',  # odd 2n+1
       # OEIS-Other: A005408 planepath=Columns,height=2
     },
     'n_start=1,height=3' =>
     { X_axis   => 'A016777',  # 3n+1
       # OEIS-Other: A016777 planepath=Columns,height=3
     },
     'n_start=1,height=4' =>
     { X_axis   => 'A016813',  # 4n+1
       # OEIS-Other: A016813 planepath=Columns,height=4
     },
     'n_start=1,height=5' =>
     { X_axis   => 'A016861',  # 5n+1
       # OEIS-Other: A016861 planepath=Columns,height=5
     },
     'n_start=1,height=6' =>
     { X_axis   => 'A016921',  # 6n+1
       # OEIS-Other: A016921 planepath=Columns,height=6
     },
     'n_start=1,height=7' =>
     { X_axis   => 'A016993',  # 7n+1
       # OEIS-Other: A016993 planepath=Columns,height=7
     },
    };
}
{ package Math::PlanePath::Diagonals;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'direction=down,n_start=1,x_start=0,y_start=0' =>
      {
       # Diagonals X_axis -- triangular 1,3,6,etc, but starting i=0 value=1
       Y_axis   => 'A000124',  # triangular+1 = n*(n+1)/2+1
       Diagonal => 'A001844',  # centred squares 2n(n+1)+1
       # OEIS-Catalogue: A000124 planepath=Diagonals line_type=Y_axis
       # OEIS-Catalogue: A001844 planepath=Diagonals line_type=Diagonal
      },
      'direction=up,n_start=1,x_start=0,y_start=0' =>
      {
       X_axis   => 'A000124',  # triangular+1 = n*(n+1)/2+1
       Diagonal => 'A001844',  # centred squares 2n(n+1)+1
       # OEIS-Other: A000124 planepath=Diagonals,direction=up
       # OEIS-Other: A001844 planepath=Diagonals,direction=up line_type=Diagonal
      },

      'direction=down,n_start=0,x_start=0,y_start=0' =>
      {
       X_axis   => 'A000096',  # n*(n+3)/2
       Y_axis   => 'A000217',  # triangular n*(n+1)/2
       # OEIS-Other: A000096 planepath=Diagonals,n_start=0
       # OEIS-Other: A000217 planepath=Diagonals,n_start=0 line_type=Y_axis
      },
      'direction=up,n_start=0,x_start=0,y_start=0' =>
      {
       X_axis   => 'A000217',  # triangular n*(n+1)/2
       Y_axis   => 'A000096',  # n*(n+3)/2
       # OEIS-Other: A000217 planepath=Diagonals,direction=up,n_start=0
       # OEIS-Other: A000096 planepath=Diagonals,direction=up,n_start=0 line_type=Y_axis
      },
    };
}
{ package Math::PlanePath::DiagonalsAlternating;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'n_start=1' =>
      { Diagonal => 'A001844',  # centred squares 2n(n+1)+1
        # OEIS-Other: A001844 planepath=DiagonalsAlternating line_type=Diagonal

        # Not quite, extra initial 1 or 0
        # X_axis => 'A128918',
        # Y_axis => 'A131179',
      },
      'n_start=0' =>
      { Diagonal => 'A046092',  # 2*triangular
        # OEIS-Other: A046092 planepath=DiagonalsAlternating,n_start=0 line_type=Diagonal
      },
    };
}
{ package Math::PlanePath::DiagonalsOctant;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    {
     # 'direction=down,n_start=1' =>
     # {
     # Not quite, starting i=0 for square=1 cf A000290 starts 0
     # # Diagonal => 'A000290', # squares
     #
     # Not quite, A033638 extra initial 1
     # # Y_axis => 'A033638', # quarter squares + 1, 1,1,2,3,5,7,10,13
     # }

     # 'direction=up,n_start=1' =>
     # {
     # # Not quite, A002061 extra initial 1
     # # Diagonal => 'A002061', # 1,1,3,7,13,21,31,43
     # }

     'direction=down,n_start=0' =>
     { Diagonal => 'A005563', # n*(n+2)  0,3,8,15,24
       # OEIS-Other: A005563 planepath=DiagonalsOctant,n_start=0 line_type=Diagonal

       # # Not quite, extra initial 0
       # # Y_axis => 'A002620', # quarter squares 0,0,1,2,4,6,9,12,
     },

     'direction=up,n_start=0' =>
     { Diagonal => 'A002378', # pronic 0,2,6,12,20
       # OEIS-Other: A002378 planepath=DiagonalsOctant,direction=up,n_start=0 line_type=Diagonal

       # # Not quite, starts n=1 value=0 whereas start Y=0 value=0 here
       # # Y_axis   => 'A024206',  # 0,1,3,5,8,11,15
     },
    };
}
{ package Math::PlanePath::MPeaks;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing        => 0;
  use constant _NumSeq_X_neg_increasing_from_i => 1;
  use constant _NumSeq_X_neg_min => 1; # at X=-1,Y=0 rather than X=0,Y=0
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing_from_i => 1;
  use constant _NumSeq_Diagonal_NW_min => 2; # at X=-1,Y=1

  # MPeaks -- X_axis A045944 matchstick n(3n+2) but initial N=3
  # MPeaks -- Diagonal,Y_axis hexagonal first,second spoke, but starting
  # from 3
}
{ package Math::PlanePath::Staircase;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    {
     'n_start=1' =>
     { Diagonal => 'A084849',
       # OEIS-Other: A084849 planepath=Staircase line_type=Diagonal
     },

     'n_start=0' =>
     { Diagonal => 'A014105', # second hexagonals
       # OEIS-Other: A014105 planepath=Staircase,n_start=0 line_type=Diagonal
     },

     'n_start=2' =>
     { Diagonal => 'A096376',
       # OEIS-Catalogue: A096376 planepath=Staircase,n_start=2 line_type=Diagonal

       # Not quite, A128918 has extra initial 1,1
       # X_axis => 'A128918',
     },
    };
}
{ package Math::PlanePath::StaircaseAlternating;
  sub _NumSeq_X_axis_increasing {
    my ($self) = @_;
    return ($self->{'end_type'} eq 'square'
            ? 1
            : 0); # backs-up
  }
  *_NumSeq_Y_axis_increasing = \&_NumSeq_X_axis_increasing;
  use constant _NumSeq_Diagonal_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    {
     'end_type=jump,n_start=1' =>
     { Diagonal => 'A084849',
       # OEIS-Other: A084849 planepath=StaircaseAlternating line_type=Diagonal
     },
     'end_type=jump,n_start=0' =>
     { Diagonal => 'A014105', # second hexagonals
       # OEIS-Other: A014105 planepath=StaircaseAlternating,n_start=0 line_type=Diagonal
     },
     'end_type=jump,n_start=2' =>
     { Diagonal => 'A096376',
       # OEIS-Other: A096376 planepath=StaircaseAlternating,n_start=2 line_type=Diagonal
     },

     'end_type=square,n_start=1' =>
     { Diagonal => 'A058331',
       # OEIS-Other: A058331 planepath=StaircaseAlternating,end_type=square line_type=Diagonal
     },
     'end_type=square,n_start=0' =>
     { Diagonal => 'A001105',
       # OEIS-Other: A001105 planepath=StaircaseAlternating,end_type=square,n_start=0 line_type=Diagonal
     },
    };
}
{ package Math::PlanePath::Corner;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'wider=0,n_start=1' =>
      { Y_axis   => 'A002522',  # n^2+1
        # OEIS-Other: A002522 planepath=Corner line_type=Y_axis
      },
      'wider=0,n_start=0' =>
      { X_axis   => 'A005563',  # (n+1)^2-1
        Y_axis   => 'A000290',  # squares
        Diagonal => 'A002378',  # pronic
        # OEIS-Other: A005563 planepath=Corner,n_start=0
        # OEIS-Other: A000290 planepath=Corner,n_start=0 line_type=Y_axis
        # OEIS-Other: A002378 planepath=Corner,n_start=0 line_type=Diagonal
      },
      'wider=0,n_start=2' =>
      { Y_axis   => 'A059100',  # n^2+2
        Diagonal => 'A014206',  # pronic+2
        # OEIS-Catalogue: A059100 planepath=Corner,n_start=2 line_type=Y_axis
        # OEIS-Catalogue: A014206 planepath=Corner,n_start=2 line_type=Diagonal
      },

      'wider=1,n_start=0' =>
      { Y_axis   => 'A002378',  # pronic
        Diagonal => 'A005563',  # (n+1)^2-1
        # OEIS-Other: A002378 planepath=Corner,wider=1,n_start=0 line_type=Y_axis
        # OEIS-Other: A005563 planepath=Corner,wider=1,n_start=0 line_type=Diagonal
      },
      'wider=1,n_start=2' =>
      { Y_axis   => 'A014206',  # pronic+2
        # OEIS-Other: A014206 planepath=Corner,wider=1,n_start=2 line_type=Y_axis
      },

      'wider=2,n_start=0' =>
      { Y_axis   => 'A005563',  # (n+1)^2-1
        Diagonal => 'A028552',  # n(n+3)
        # OEIS-Other:     A005563 planepath=Corner,wider=2,n_start=0 line_type=Y_axis
        # OEIS-Catalogue: A028552 planepath=Corner,wider=2,n_start=0 line_type=Diagonal
      },
      'wider=2,n_start=1' =>
      { Diagonal => 'A028387',  # n(n+3)+1 = n + (n+1)^2
        # OEIS-Catalogue: A028387 planepath=Corner,wider=2,n_start=1 line_type=Diagonal
      },

      'wider=3,n_start=0' =>
      { Y_axis   => 'A028552',  # n(n+3)
        # OEIS-Other: A028552 planepath=Corner,wider=3,n_start=0 line_type=Y_axis
      },
    };
}
{ package Math::PlanePath::PyramidRows;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1; # when covered, or single
  use constant _NumSeq_Diagonal_NW_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    {
     # PyramidRows step=1
     do {
       my $href =
         { Y_axis   => 'A000124',  # triangular+1 = n*(n+1)/2+1
         };
       ('step=1,align=centre,n_start=1' => $href,
        'step=1,align=right,n_start=1'  => $href);

       # OEIS-Other: A000124 planepath=PyramidRows,step=1 line_type=Y_axis
       # OEIS-Other: A000124 planepath=PyramidRows,step=1,align=right line_type=Y_axis
     },
     'step=1,align=left,n_start=1' =>
     { Diagonal_NW => 'A000124',  # triangular+1 = n*(n+1)/2+1
       # OEIS-Other: A000124 planepath=PyramidRows,step=1,align=left line_type=Diagonal_NW
     },
     do {
       my $href =
         { Y_axis   => 'A000217',  # triangular
         };
       ('step=1,align=centre,n_start=0' => $href,
        'step=1,align=right,n_start=0'  => $href);

       # OEIS-Other: A000217 planepath=PyramidRows,step=1,n_start=0 line_type=Y_axis
       # OEIS-Other: A000217 planepath=PyramidRows,step=1,align=right,n_start=0 line_type=Y_axis
     },

     'step=2,align=centre,n_start=1' =>
     { Diagonal_NW => 'A002522',  # n^2+1
       # OEIS-Other: A002522 planepath=PyramidRows,step=2 line_type=Diagonal_NW

       # Not quite, n_start=1 means squares starting from 1 whereas A000290
       # starts from 0
       # Diagonal => 'A000290',
     },
     'step=2,align=centre,n_start=0' =>
     { Y_axis      => 'A002378', # pronic
       Diagonal    => 'A005563',
       Diagonal_NW => 'A000290', # squares
       # OEIS-Other: A002378 planepath=PyramidRows,step=2,n_start=0 line_type=Y_axis
       # OEIS-Other: A005563 planepath=PyramidRows,step=2,n_start=0 line_type=Diagonal
       # OEIS-Other: A000290 planepath=PyramidRows,step=2,n_start=0 line_type=Diagonal_NW
     },
     'step=2,align=right,n_start=0' =>
     { Y_axis   => 'A000290', # squares
       Diagonal => 'A002378', # pronic
       # OEIS-Other: A000290 planepath=PyramidRows,step=2,align=right,n_start=0 line_type=Y_axis
       # OEIS-Other: A002378 planepath=PyramidRows,step=2,align=right,n_start=0 line_type=Diagonal
     },
     'step=2,align=left,n_start=0' =>
     { Y_axis      => 'A005563',
       Diagonal_NW => 'A002378', # pronic
       # OEIS-Other: A005563 planepath=PyramidRows,step=2,align=left,n_start=0 line_type=Y_axis
       # OEIS-Other: A002378 planepath=PyramidRows,step=2,align=left,n_start=0 line_type=Diagonal_NW
     },
     'step=2,align=centre,n_start=2' =>
     { Diagonal_NW => 'A059100', # n^2+2
       # OEIS-Other: A059100 planepath=PyramidRows,step=2,n_start=2 line_type=Diagonal_NW
     },
     'step=2,align=right,n_start=2' =>
     { Y_axis => 'A059100', # n^2+2
       # OEIS-Other: A059100 planepath=PyramidRows,step=2,align=right,n_start=2 line_type=Y_axis
     },

     'step=3,align=centre,n_start=1' =>
     { Y_axis      => 'A104249',
       Diagonal_NW => 'A143689',
       # OEIS-Catalogue: A104249 planepath=PyramidRows,step=3 line_type=Y_axis
       # OEIS-Catalogue: A143689 planepath=PyramidRows,step=3 line_type=Diagonal_NW
       # Not quite OFFSET=1 cf start i=0 here
       # Diagonal    => 'A005448',
       # # OEIS-Catalogue: A005448 planepath=PyramidRows,step=3 line_type=Diagonal
     },
     'step=3,align=right,n_start=1' =>
     { Y_axis   => 'A143689',
       Diagonal => 'A104249',
       # OEIS-Other: A143689 planepath=PyramidRows,step=3,align=right line_type=Y_axis
       # OEIS-Other: A104249 planepath=PyramidRows,step=3,align=right line_type=Diagonal

       # Not quite OFFSET=1 cf start i=0 here
       # Diagonal    => 'A005448',
       # # OEIS-Catalogue: A005448 planepath=PyramidRows,step=3 line_type=Diagonal
     },
     'step=3,align=centre,n_start=0' =>
     { Y_axis      => 'A005449', # second pentagonal n*(3n+1)/2
       Diagonal_NW => 'A000326', # pentagonal n(3n-1)/2
       # OEIS-Other: A005449 planepath=PyramidRows,step=3,n_start=0 line_type=Y_axis
       # OEIS-Other: A000326 planepath=PyramidRows,step=3,n_start=0 line_type=Diagonal_NW
     },
     'step=3,align=right,n_start=0' =>
     { Y_axis   => 'A000326', # pentagonal n(3n-1)/2
       Diagonal => 'A005449', # second pentagonal n*(3n+1)/2
       # OEIS-Other: A000326 planepath=PyramidRows,step=3,align=right,n_start=0 line_type=Y_axis
       # OEIS-Other: A005449 planepath=PyramidRows,step=3,align=right,n_start=0 line_type=Diagonal
     },

     'step=4,align=centre,n_start=1' =>
     { Y_axis      => 'A084849',
       Diagonal    => 'A001844',
       Diagonal_NW => 'A058331',
       # OEIS-Catalogue: A084849 planepath=PyramidRows,step=4 line_type=Y_axis
       # OEIS-Other: A001844 planepath=PyramidRows,step=4 line_type=Diagonal
       # OEIS-Other: A058331 planepath=PyramidRows,step=4 line_type=Diagonal_NW
     },
     'step=4,align=right,n_start=1' =>
     { Diagonal => 'A058331',
       # OEIS-Other: A058331 planepath=PyramidRows,step=4,align=right line_type=Diagonal
     },
     'step=4,align=left,n_start=1' =>
     { Diagonal_NW => 'A001844',
       # OEIS-Other: A001844 planepath=PyramidRows,step=4,align=left line_type=Diagonal_NW
     },
     'step=4,align=centre,n_start=0' =>
     { Y_axis      => 'A014105', # second hexagonal
       Diagonal    => 'A046092', # 4*triangular
       Diagonal_NW => 'A001105', # 2*n^2
       # OEIS-Other:     A014105 planepath=PyramidRows,step=4,n_start=0 line_type=Y_axis
       # OEIS-Catalogue: A046092 planepath=PyramidRows,step=4,n_start=0 line_type=Diagonal
       # OEIS-Other:     A001105 planepath=PyramidRows,step=4,n_start=0 line_type=Diagonal_NW
     },
     'step=4,align=right,n_start=0' =>
     { Y_axis   => 'A000384', # 2*n^2-n, hexagonal numbers
       Diagonal => 'A001105',
       # OEIS-Other: A000384 planepath=PyramidRows,step=4,align=right,n_start=0 line_type=Y_axis
       # OEIS-Other: A001105 planepath=PyramidRows,step=4,align=right,n_start=0 line_type=Diagonal
     },
     'step=4,align=left,n_start=0' =>
     { Diagonal_NW => 'A046092', # 4*triangular
       # OEIS-Other: A046092 planepath=PyramidRows,step=4,align=left,n_start=0 line_type=Diagonal_NW
     },

     # TODO PyramidRows,step=5 n_start=0

     'step=5,align=centre,n_start=1' =>
     { Y_axis      => 'A116668',
       # OEIS-Other: A116668 planepath=PyramidRows,step=5 line_type=Y_axis
     },
     'step=6,align=centre,n_start=1' =>
     { Diagonal_NW => 'A056107',
       Y_axis      => 'A056108',
       Diagonal    => 'A056109',
       # OEIS-Other: A056107 planepath=PyramidRows,step=6 line_type=Diagonal_NW
       # OEIS-Other: A056108 planepath=PyramidRows,step=6 line_type=Y_axis
       # OEIS-Other: A056109 planepath=PyramidRows,step=6 line_type=Diagonal
     },
     'step=8,align=centre,n_start=1' =>
     { Diagonal_NW => 'A053755',
       # OEIS-Other: A053755 planepath=PyramidRows,step=8 line_type=Diagonal_NW
     },
     'step=9,align=centre,n_start=1' =>
     { Y_axis   => 'A006137',
       Diagonal => 'A038764',
       # OEIS-Other: A006137 planepath=PyramidRows,step=9 line_type=Y_axis
       # OEIS-Other: A038764 planepath=PyramidRows,step=9 line_type=Diagonal
     },
    };
}
{ package Math::PlanePath::PyramidSides;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'n_start=1' =>
      { X_neg    => 'A002522',
        Diagonal => 'A033951',
        # OEIS-Catalogue: A002522 planepath=PyramidSides line_type=X_neg
        # OEIS-Other:     A033951 planepath=PyramidSides line_type=Diagonal
        #
        # X_axis -- squares (x+1)^2, but starting i=0 value=1
      } };
}
{ package Math::PlanePath::CellularRule;
  use constant _NumSeq_Y_axis_increasing   => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'rule=5,n_start=1' =>
      { Y_axis   => 'A061925',  # ceil(n^2/2)+1
        # OEIS-Catalogue: A061925 planepath=CellularRule,rule=5 line_type=Y_axis
      },

      # rule 84,116,212,244 two-wide right line
      do {
        my $tworight
          = { Diagonal   => 'A005408',  # odds 2n+1
            };
        ('rule=84,n_start=1'  => $tworight,
         'rule=116,n_start=1' => $tworight,
         'rule=212,n_start=1' => $tworight,
         'rule=244,n_start=1' => $tworight,
        );

        # OEIS-Other: A005408 planepath=CellularRule,rule=84 line_type=Diagonal
        # OEIS-Other: A005408 planepath=CellularRule,rule=116 line_type=Diagonal
        # OEIS-Other: A005408 planepath=CellularRule,rule=212 line_type=Diagonal
        # OEIS-Other: A005408 planepath=CellularRule,rule=244 line_type=Diagonal
      },
      'rule=77,n_start=1' =>
      { Y_axis   => 'A000124',  # triangular+1
        # OEIS-Other: A000124 planepath=CellularRule,rule=77 line_type=Y_axis
      },
      'rule=177,n_start=1' =>
      { Diagonal   => 'A000124',  # triangular+1
        # OEIS-Other: A000124 planepath=CellularRule,rule=177 line_type=Diagonal
      },
      'rule=185,n_start=1' =>
      { Diagonal   => 'A002522',  # n^2+1
        # OEIS-Other: A002522 planepath=CellularRule,rule=185 line_type=Diagonal
      },
      'rule=189,n_start=1' =>
      { Y_axis   => 'A002522',  # n^2+1
        # OEIS-Other: A002522 planepath=CellularRule,rule=189 line_type=Y_axis
      },
      # PyramidRows step=1,align=left
      # OEIS-Other: A000124 planepath=CellularRule,rule=206 line_type=Diagonal_NW
      # OEIS-Other: A000124 planepath=CellularRule,rule=238 line_type=Diagonal_NW

      do {
        my $solidgapright
          = { Diagonal   => 'A002522',  # n^2+1
            };
        ('rule=209,n_start=1' => $solidgapright,
         'rule=241,n_start=1' => $solidgapright,
        );
        # OEIS-Other: A002522 planepath=CellularRule,rule=209 line_type=Diagonal
        # OEIS-Other: A002522 planepath=CellularRule,rule=241 line_type=Diagonal
      },
      'rule=29,n_start=1' =>
      { Y_axis   => 'A000124',  # triangular+1
        # OEIS-Other: A000124 planepath=CellularRule,rule=29 line_type=Y_axis
      },
      'rule=221,n_start=1' =>
      { Y_axis   => 'A002522',  # n^2+1
        # OEIS-Other: A002522 planepath=CellularRule,rule=221 line_type=Y_axis
      },
      'rule=229,n_start=1' =>
      { Y_axis   => 'A002522',  # n^2+1
        # OEIS-Other: A002522 planepath=CellularRule,rule=229 line_type=Y_axis
      },
      #
      # rule=13 Y axis
      #
      # rule=28,156
      # Y_axis => 'A002620',  quarter squares floor(n^2/4) but diff start
      # Diagonal => 'A024206', quarter squares - 1, but diff start
      #
      # A000027 naturals integers 1 upwards, but OFFSET=1 cf start Y=0  here
      # # central column only
      # 'rule=4' =>
      # { Y_axis   => 'A000027', # 1 upwards
      #   # OEIS-Other: A000027 planepath=CellularRule,rule=4 line_type=Y_axis
      # },
      #
      # # right line only rule=16,24,48,56,80,88,112,120,144,152,176,184,208,216,240,248
      # Not quite A000027 OFFSET=1 vs start X=Y=0 here
      # 'rule=16' =>
      # { Y_axis   => 'A000027', # 1 upwards
      #   # OEIS-Other: A000027 planepath=CellularRule,rule=16 line_type=Diagonal
      # },
    };
}
{
  package Math::PlanePath::CellularRule::Line;
  use constant _NumSeq_Y_axis_increasing  => 1;
  use constant _NumSeq_Diagonal_increasing  => 1;
  use constant _NumSeq_Diagonal_NW_increasing  => 1;
}
{
  package Math::PlanePath::CellularRule::OneTwo;
  use constant _NumSeq_Y_axis_increasing   => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;

  # use constant _NumSeq_N_oeis_anum =>
  #   { 'align=left,n_start=1' =>
  #     {
  # Not quite, OFFSET=1 cf coordinate X=0 here
  # Diagonal_NW => 'A001651', # not divisible by 3
  #     },

  #   { 'align=right,n_start=1' =>
  # Not quite, A032766  0 or 1 mod 3, but it starts OFFSET=0 value=0
  # whereas path start 1,3,4,etc without initial 0
  # Diagonal => 'A032766',
  #
  #   };
}
{
  package Math::PlanePath::CellularRule::Two;
  use constant _NumSeq_Y_axis_increasing   => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'align=right,n_start=1' =>
     { Diagonal => 'A005408',  # odd 2n+1
       # OEIS-Other: A005408 planepath=CellularRule,rule=84 line_type=Diagonal
     },
    };
}
{
  package Math::PlanePath::CellularRule::OddSolid;
  # rule=50,58,114,122,178,179,186,242,250 pyramid every second point

  use constant _NumSeq_Y_axis_increasing   => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'n_start=1' =>
      { Diagonal_NW => 'A000124',  # triangular+1
        # OEIS-Other: A000124 planepath=CellularRule,rule=50 line_type=Diagonal_NW
        # OEIS-Other: A000124 planepath=CellularRule,rule=58 line_type=Diagonal_NW
        # OEIS-Other: A000124 planepath=CellularRule,rule=114 line_type=Diagonal_NW
        # OEIS-Other: A000124 planepath=CellularRule,rule=122 line_type=Diagonal_NW
        # OEIS-Other: A000124 planepath=CellularRule,rule=178 line_type=Diagonal_NW
        # OEIS-Other: A000124 planepath=CellularRule,rule=179 line_type=Diagonal_NW
        # OEIS-Other: A000124 planepath=CellularRule,rule=186 line_type=Diagonal_NW
        # OEIS-Other: A000124 planepath=CellularRule,rule=242 line_type=Diagonal_NW
        # OEIS-Other: A000124 planepath=CellularRule,rule=250 line_type=Diagonal_NW
        #
        # Not quite, starts value=0
        # Diagonal => 'A000217', # triangular numbers but diff start
      },
    };
}
{ package Math::PlanePath::CellularRule54;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
}
{ package Math::PlanePath::CellularRule57;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
}
{ package Math::PlanePath::CellularRule190;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'mirror=0,n_start=0' =>
      { Diagonal_NW => 'A006578',  # triangular and quarter square
        # OEIS-Catalogue: A006578 planepath=CellularRule190,n_start=0 line_type=Diagonal_NW
      },
      'mirror=1,n_start=0' =>
      { Diagonal_NW => 'A006578',  # triangular and quarter square
        # OEIS-Other: A006578 planepath=CellularRule190,mirror=1,n_start=0 line_type=Diagonal_NW
      },
    };
}
{ package Math::PlanePath::UlamWarburton;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'parts=4,n_start=0' =>
      { Depth_start => 'A147562',  # cells ON after n stages
        # OEIS-Catalogue: A147562 planepath=UlamWarburton,n_start=0 line_type=Depth_start
      },
      'parts=2,n_start=0' =>
      { Depth_start => 'A183060',  # num cells ON, starting from 0
        X_axis      => 'A183060',  # X_axis == Depth_start
        # OEIS-Catalogue: A183060 planepath=UlamWarburton,parts=2,n_start=0 line_type=Depth_start
        # OEIS-Other:     A183060 planepath=UlamWarburton,parts=2,n_start=0
      },
      'parts=1,n_start=1' =>
      { Depth_end => 'A151922',  # num cells ON at end of depth=n
        Y_axis    => 'A151922',  # Y_axis == Depth_end
        # OEIS-Catalogue: A151922 planepath=UlamWarburton,parts=1,n_start=1 line_type=Depth_end
        # OEIS-Other:     A151922 planepath=UlamWarburton,parts=1,n_start=1 line_type=Y_axis
      },
    };
}
{ package Math::PlanePath::UlamWarburtonQuarter;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;

  # low 10111=23 increment to 11000=24
  # 4^2*3+4*3^2+1*3^3 = 111     123
  # 4^3*3 = 192                 150 +27 = 3^3

  use constant _NumSeq_N_oeis_anum =>
    { 'parts=1,n_start=1' =>
      { Depth_end => 'A151920', # 3^count1bits(n), OFFSET=0 1,2,5,6,9
        # OEIS-Catalogue: A151920 planepath=UlamWarburtonQuarter line_type=Depth_end
      },
    };
}
{ package Math::PlanePath::CoprimeColumns;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_X_offset => 1;

  # CoprimeColumns
  # X_axis => 'A002088', # cumulative totient but start X=1 value=0;
  #   Diagonal A015614 cumulative-1 but start X=1 value=1
}
{ package Math::PlanePath::DivisibleColumns;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;

  # Not quite, X_axis => 'A006218' but path start X=1 cf OFFSET=0,
  # Not quite, Diagonal => 'A077597' but path start X=1 cf OFFSET=0
}
# { package Math::PlanePath::File;
#   # File                   points from a disk file
#   # FIXME: analyze points for min/max
# }
# { package Math::PlanePath::QuintetCurve;
# }
# { package Math::PlanePath::QuintetCentres;
#   # inherit QuintetCurve
# }
{ package Math::PlanePath::CornerReplicate;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { '' =>
      { X_axis   => 'A000695',  # base 4 digits 0,1 only
        Y_axis   => 'A001196',  # base 4 digits 0,3 only
        Diagonal => 'A062880',  # base 4 digits 0,2 only
        # OEIS-Other: A000695 planepath=CornerReplicate
        # OEIS-Other: A001196 planepath=CornerReplicate line_type=Y_axis
        # OEIS-Other: A062880 planepath=CornerReplicate line_type=Diagonal
      },
    };
}
{ package Math::PlanePath::DigitGroups;
  use constant _NumSeq_Diagonal_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'radix=2,i_start=1' =>
      { X_axis => 'A084471', # 0 -> 00 in binary, starting OFFSET=1
        # OEIS-Catalogue: A084471 planepath=DigitGroups,radix=2 i_start=1
      },
    };
}
{ package Math::PlanePath::FibonacciWordFractal;
  use constant _NumSeq_X_axis_increasing   => 1; # when touched
  use constant _NumSeq_Y_axis_increasing   => 1; # when touched
  use constant _NumSeq_Diagonal_increasing => 1; # when touched
}
{ package Math::PlanePath::LTiling;
  use constant _NumSeq_Diagonal_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    { 'L_fill=middle' =>
      { Diagonal => 'A062880',  # base 4 digits 0,2 only
        # OEIS-Other: A062880 planepath=LTiling line_type=Diagonal
      },
    };
}
{ package Math::PlanePath::WythoffArray;
  use constant _NumSeq_X_axis_increasing   => 1;
  use constant _NumSeq_Y_axis_increasing   => 1;
  use constant _NumSeq_Diagonal_increasing => 1;

  use constant _NumSeq_N_oeis_anum =>
    {
     'x_start=1,y_start=1' =>
     { Y_axis   => 'A003622', # spectrum of phi 1,4,6,9
       Diagonal => 'A020941', # diagonal, OFFSET=1
       # OEIS-Catalogue: A003622 planepath=WythoffArray,x_start=1,y_start=1 line_type=Y_axis
       # OEIS-Catalogue: A020941 planepath=WythoffArray,x_start=1,y_start=1 line_type=Diagonal

       # Y=1 every second => 'A005248', # every second Lucas number
     },

     # # Not quite, extra initial 0,1 in A000045 Fibonaccis
     # # X_axis   => 'A000045',
     #
     # # Y=1 row X=0,2,4,etc => 'A005248', # every second Lucas number
    };
}
{ package Math::PlanePath::WythoffPreliminaryTriangle;
  use constant _NumSeq_Y_axis_i_start => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_N_oeis_anum =>
    {
     '' =>
     { Y_axis   => 'A173027',
       # OEIS-Other: A173027 planepath=WythoffPreliminaryTriangle line_type=Y_axis
     },
    };
}
{ package Math::PlanePath::PowerArray;
  use constant _NumSeq_X_axis_increasing   => 1;
  use constant _NumSeq_Y_axis_increasing   => 1;
  use constant _NumSeq_Diagonal_increasing => 1;

  # cf Not quite A168183 non-multiples-of-9, A168186 non-multiples-of-12
  # are values on Y axis, except OFFSET=1 value=1, whereas path start Y=0
  # value=1
  use constant _NumSeq_N_oeis_anum =>
    { 'radix=2' =>
      { X_axis   => 'A000079',  # powers 2^X
        Y_axis   => 'A005408',  # odd 2n+1
        Diagonal => 'A014480',  # (2n+1)*2^n starting n=0
        # OEIS-Other: A000079 planepath=PowerArray
        # OEIS-Other: A005408 planepath=PowerArray line_type=Y_axis
        # OEIS-Catalogue: A014480 planepath=PowerArray line_type=Diagonal
      },
      'radix=3' =>
      { X_axis   => 'A000244',  # powers 3^X
        # OEIS-Other: A000244 planepath=PowerArray,radix=3
        #
        # Not quite, OFFSET=1 cf path start Y=0
        # Y_axis => 'A001651', # non multiples of 3
      },
      'radix=4' =>
      { X_axis   => 'A000302',  # powers 4^X
        # OEIS-Other: A000302 planepath=PowerArray,radix=4
      },
      'radix=5' =>
      { X_axis   => 'A000351',  # powers 5^X
        # OEIS-Other: A000351 planepath=PowerArray,radix=5
      },
      'radix=10' =>
      { X_axis   => 'A011557',  # powers 10^X
        # OEIS-Other: A011557 planepath=PowerArray,radix=10

        # Not quite, A067251 OFFSET=1 value=1 whereas path Y=0 N=value=1
        # Y_axis   => 'A067251', # no trailing 0 digits
        # # OEIS-Catalogue: A067251 planepath=PowerArray,radix=10 line_type=Y_axis
      },
    };
}

#------------------------------------------------------------------------------
# Math-PlanePath-Toothpick

{ package Math::PlanePath::ToothpickTree;

  # X axis has N=0 or N=0,1 only, except for parts=octant axis at Y=1
  sub _NumSeq_X_axis_increasing {
    my ($self) = @_;
    return ($self->{'parts'} ne 'octant');
  }

  # Y axis has N=0,N=1 only, except for parts=octant_up axis at X=1
  sub _NumSeq_Y_axis_increasing {
    my ($self) = @_;
    return ($self->{'parts'} ne 'octant_up');
  }
  use constant _NumSeq_Y_neg_increasing => 1;  # N=0,N=2 only

  use constant _NumSeq_Diagonal_increasing => 1; # growth steps along diags
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;

  # catalogued in Math::NumSeq::OEIS::Catalogue::Plugin::PlanePathToothpick
  use constant _NumSeq_N_oeis_anum =>
    { 'parts=4' =>
      { Depth_start => 'A139250',
        # OEIS-Other: A139250 planepath=ToothpickTree,parts=4 line_type=Depth_start
      },
      'parts=3' =>
      { Depth_start => 'A153006',
        # OEIS-Other: A153006 planepath=ToothpickTree,parts=3 line_type=Depth_start
      },
      'parts=2' =>
      { Depth_start => 'A152998',
        # OEIS-Other: A152998 planepath=ToothpickTree,parts=2 line_type=Depth_start
      },
      'parts=1' =>
      { Depth_start => 'A153000',
        # OEIS-Other: A153000 planepath=ToothpickTree,parts=1 line_type=Depth_start
      },
      'parts=wedge' =>
      { Depth_start => 'A160406',
        # OEIS-Other: A160406 planepath=ToothpickTree,parts=wedge line_type=Depth_start
      },
      'parts=two_horiz' =>
      { Depth_start => 'A160158',
        # OEIS-Other: A160158 planepath=ToothpickTree,parts=two_horiz line_type=Depth_start
      },
    };
}
{ package Math::PlanePath::ToothpickReplicate;
  use constant _NumSeq_Y_axis_increasing => 1;  # N=0,N=1 only

  sub _NumSeq_Y_neg_increasing {
    my ($self) = @_;
    return ($self->{'parts'} == 3 ? 0  # replication twist
            : 1); # N=0,N=2 only
  }
  use constant _NumSeq_Diagonal_increasing => 1; # replicate along diags
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
}
{ package Math::PlanePath::ToothpickUpist;
  use constant _NumSeq_Y_axis_increasing => 1;  # rows increasing
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;

  # catalogued in Math::NumSeq::OEIS::Catalogue::Plugin::PlanePathToothpick
  use constant _NumSeq_N_oeis_anum =>
    { '' =>
      { Depth_start => 'A151566',
        # OEIS-Other: A151566 planepath=ToothpickUpist line_type=Depth_start
      },
    };
}
{ package Math::PlanePath::ToothpickSpiral;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  # catalogued in Math::NumSeq::OEIS::Catalogue::Plugin::PlanePathToothpick
  use constant _NumSeq_N_oeis_anum =>
    { 'n_start=1' =>
      { Diagonal    => 'A014634',  # odd-index hexagonals
        Diagonal_NW => 'A033567',  #
        Diagonal_SW => 'A185438',  #
        Diagonal_SE => 'A188135',  #
        # OEIS-Other: A014634 planepath=ToothpickSpiral line_type=Diagonal
        # OEIS-Other: A033567 planepath=ToothpickSpiral line_type=Diagonal_NW
        # OEIS-Other: A185438 planepath=ToothpickSpiral line_type=Diagonal_SW
        # OEIS-Other: A188135 planepath=ToothpickSpiral line_type=Diagonal_SE
      },
      'n_start=0' =>
      { Diagonal    => 'A033587',  # 
        Diagonal_SW => 'A014635',  # even-index hexagonals
        Diagonal_SE => 'A033585',  #
        # OEIS-Other: A033587 planepath=ToothpickSpiral,n_start=0 line_type=Diagonal
        # OEIS-Other: A014635 planepath=ToothpickSpiral,n_start=0 line_type=Diagonal_SW
        # OEIS-Other: A033585 planepath=ToothpickSpiral,n_start=0 line_type=Diagonal_SE
      },
    };
}

{ package Math::PlanePath::LCornerTree;
  sub _NumSeq_X_axis_increasing {
    my ($self) = @_;
    return $self->{'parts'} ne 'diagonal-1';
  }

  {
    my %_NumSeq_Y_axis_increasing = ('octant+1'    => 1, # two points only
                                     'diagonal-1'  => 1,
                                  );
    sub _NumSeq_Y_axis_increasing {
      my ($self) = @_;
      return $_NumSeq_Y_axis_increasing{$self->{'parts'}};
    }
  }

  sub _NumSeq_X_neg_increasing {
    my ($self) = @_;
    return ($self->{'parts'} eq 'wedge'       # two points N=0,N=1
            || $self->{'parts'} eq 'wedge+1'  # three points N=0,1,7
            || $self->{'parts'} eq 'diagonal');
  }

  # parts=diagonal has minimum N=0 at X=0,Y=-1, so explicit Y_neg minimum
  use constant _NumSeq_Y_neg_min => 0;
  sub _NumSeq_Y_neg_increasing {
    my ($self) = @_;
    return $self->{'parts'} ne 'diagonal';
  }
  use constant _NumSeq_Diagonal_increasing => 1; # growth along diags
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;

  # catalogued in Math::NumSeq::OEIS::Catalogue::Plugin::PlanePathToothpick
  use constant _NumSeq_N_oeis_anum =>
    { 'parts=4' =>
      { Depth_start => 'A160410', # 4 * cumulative 3^count1bits(n)
        # OEIS-Other: A160410 planepath=LCornerTree line_type=Depth_start
      },
      'parts=3' =>
      { Depth_start => 'A160412', # 3 * cumulative 3^count1bits(n)
        # OEIS-Other: A160412 planepath=LCornerTree,parts=3 line_type=Depth_start
      },
      'parts=diagonal-1' =>
      { Depth_start => 'A183148', # half-plane triplet toothpicks
        # OEIS-Other: A183148 planepath=LCornerTree,parts=diagonal-1 line_type=Depth_start

        # No, N=1 start of depth=1 is at X=1,Y=0 not on SE diagonal
        # Diagonal_SE => 'A183148',
      },

      # Not quite, A130665=1,4,7,16 offset=0 whereas Nend=0,1,4,7,16 depth=0
      # has extra initial 0.
      # 'parts=1' =>
      # { Depth_end => 'A130665', # cumulative 3^count1bits(d), starting a(0)=1
      #   # OEIS-Catalogue: A130665 planepath=LCornerTree,parts=1,n_start=-1 line_type=Depth_end i_offset=1
      # },
    };
}
{ package Math::PlanePath::LCornerReplicate;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1; # replicate along diags

  # catalogued in Math::NumSeq::OEIS::Catalogue::Plugin::PlanePathToothpick
  use constant _NumSeq_N_oeis_anum =>
    { '' =>
      { Diagonal => 'A062880', # base 4 digits 0,2 only
        # OEIS-Other: A062880 planepath=LCornerReplicate line_type=Diagonal
      },
    };
}

{ package Math::PlanePath::OneOfEight;
  use constant _NumSeq_X_axis_increasing => 1;
  use constant _NumSeq_X_neg_increasing => 1;
  use constant _NumSeq_Y_axis_increasing => 1;
  use constant _NumSeq_Y_neg_increasing => 1;
  use constant _NumSeq_Diagonal_increasing => 1;
  use constant _NumSeq_Diagonal_NW_increasing => 1;
  use constant _NumSeq_Diagonal_SW_increasing => 1;
  use constant _NumSeq_Diagonal_SE_increasing => 1;

  # catalogued in Math::NumSeq::OEIS::Catalogue::Plugin::PlanePathToothpick
  use constant _NumSeq_N_oeis_anum =>
    { 'parts=4' =>
      { Depth_start   => 'A151725',
        # OEIS-Other: A151725 planepath=OneOfEight line_type=Depth_start
      },
      'parts=1' =>
      { Depth_start   => 'A151735',
        # OEIS-Other: A151735 planepath=OneOfEight,parts=1 line_type=Depth_start
      },
      'parts=3mid' =>
      { Depth_start   => 'A170880',
        # OEIS-Other: A170880 planepath=OneOfEight,parts=3mid line_type=Depth_start
      },
      'parts=3side' =>
      { Depth_start   => 'A170879',
        # OEIS-Other: A170879 planepath=OneOfEight,parts=3side line_type=Depth_start
      },
    };
}

{ package Math::PlanePath::HTree;
  # clockwise around each sub-tree so N increases along X axis
  use constant _NumSeq_X_axis_increasing => 1;
}

#------------------------------------------------------------------------------
{ package Math::PlanePath;
  use constant _NumSeq_A2 => 0;
}
{ package Math::PlanePath::TriangleSpiral;
  use constant _NumSeq_A2 => 1;
}
{ package Math::PlanePath::HexSpiral;
  use constant _NumSeq_A2 => 1;
}
{ package Math::PlanePath::HexArms;
  use constant _NumSeq_A2 => 1;
}
{ package Math::PlanePath::TriangularHypot;
  use constant _NumSeq_A2 => 1;
}
{ package Math::PlanePath::Flowsnake;
  use constant _NumSeq_A2 => 1;
  # and FlowsnakeCentres inherits
}

1;
__END__

=for stopwords Ryde Math-PlanePath SquareSpiral lookup PlanePath ie

=head1 NAME

Math::NumSeq::PlanePathN -- sequence of N values from PlanePath module

=head1 SYNOPSIS

 use Math::NumSeq::PlanePathN;
 my $seq = Math::NumSeq::PlanePathN->new (planepath => 'SquareSpiral',
                                          line_type => 'X_axis');
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This module presents N values from a C<Math::PlanePath> as a sequence.  The
default is the X axis, or the C<line_type> parameter (a string) can choose
among

    "X_axis"        X axis
    "Y_axis"        Y axis
    "X_neg"         X negative axis
    "Y_neg"         Y negative axis
    "Diagonal"      leading diagonal X=i, Y=i
    "Diagonal_NW"   north-west diagonal X=-i, Y=i
    "Diagonal_SW"   south-west diagonal X=-i, Y=-i
    "Diagonal_SE"   south-east diagonal X=i, Y=-i
    "Depth_start"   first N at depth=i
    "Depth_end"     last N at depth=i

For example the C<SquareSpiral> X axis starts i=0 with values 1, 2, 11, 28,
53, 86, etc.

"X_neg", "Y_neg", "Diagonal_NW", etc, on paths which don't traverse negative
X or Y have just a single value from X=0,Y=0.

The behaviour on paths which visit only some of the points on the respective
axis is unspecified as yet, as is behaviour on paths with repeat points,
such as the C<DragonCurve>.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::PlanePathN-E<gt>new (key=E<gt>value,...)>

Create and return a new sequence object.  The options are

    planepath          string, name of a PlanePath module
    planepath_object   PlanePath object
    line_type          string, as described above

C<planepath> can be either the module part such as "SquareSpiral" or a
full class name "Math::PlanePath::SquareSpiral".

=item C<$value = $seq-E<gt>ith($i)>

Return the N value at C<$i> in the PlanePath.  C<$i> gives a position on the
respective C<line_type>, so the X,Y to lookup a C<$value=N> is

     X,Y       line_type
    -----      ---------
    $i, 0      "X_axis"
    0, $i      "Y_axis"
    -$i, 0     "X_neg"
    0, -$i     "Y_neg"
    $i, $i     "Diagonal"
    $i, -$i    "Diagonal_NW"
    -$i, -$i   "Diagonal_SW"
    $i, -$i    "Diagonal_SE"

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence.

This means C<$value> is an integer N which is on the respective
C<line_type>, ie. that C<($path-E<gt>n_to_xy($value)> is on the line type.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::PlanePathCoord>,
L<Math::NumSeq::PlanePathDelta>

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
