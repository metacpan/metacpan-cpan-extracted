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


package Math::NumSeq::PlanePathCoord;
use 5.004;
use strict;
use Carp 'croak';
use constant 1.02; # various underscore constants below
use List::Util;

#use List::Util 'max','min';
*max = \&Math::PlanePath::_max;
*min = \&Math::PlanePath::_min;

use vars '$VERSION','@ISA';
$VERSION = 126;
use Math::NumSeq;
@ISA = ('Math::NumSeq');

use Math::PlanePath 124;  # v.124 for n_to_n_list()
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite';

# uncomment this to run the ### lines
# use Smart::Comments;


sub description {
  my ($self) = @_;
  if (ref $self) {
    return "Coordinate $self->{'coordinate_type'} values from path $self->{'planepath'}";
  } else {
    # class method
    return 'Coordinate values from a PlanePath';
  }
}

use constant::defer parameter_info_array =>
  sub {
    my $choices = [
                   'X', 'Y',
                   'Sum', 'SumAbs',
                   'Product',
                   'DiffXY', 'DiffYX', 'AbsDiff',
                   'Radius', 'RSquared',
                   'TRadius', 'TRSquared',
                   'IntXY', 'FracXY',
                   'BitAnd', 'BitOr', 'BitXor',
                   'Min','Max',
                   'MinAbs','MaxAbs',
                   'GCD',
                   'Depth', 'SubHeight',
                   'NumChildren','NumSiblings',
                   'RootN',
                   'IsLeaf','IsNonLeaf',

                   # Maybe:
                   # 'ExperimentalRowOffset',
                   # 'ExperimentalMinAbsTri','ExperimentalMaxAbsTri',
                   # 'ExperimentalAbsX',
                   # 'ExperimentalAbsY',
                   # 'DiffXY/2',
                   # 'ExperimentalDiffXYsquared',
                   # 'ExperimentalDiffYXsquares',
                   # 'ExperimentalParity',
                   # 'ExperimentalNumerator','ExperimentalDenominator',
                   # 'ExperimentalLeafDistance',
                   # 'ExperimentalGcdDivisions',
                   # 'ExperimentalKroneckerSymbol',
                   # 'ExperimentalMulDist',
                   # 'ExperimentalHammingDist',
                   # 'ExperimentalNumOverlap',
                   #
                   # 'ExperimentalNeighbours3',    # NumNeighbours
                   # 'ExperimentalNeighbours4',
                   # 'ExperimentalNeighbours4d',
                   # 'ExperimentalNeighbours6',
                   # 'ExperimentalNeighbours8',
                   #
                   # 'ExperimentalVisitNum',
                   # 'ExperimentalVisitCount',
                   # 'ExperimentalRevisit',
                   'ExperimentalPairsXY','ExperimentalPairsYX',
                  ];
    return [
            _parameter_info_planepath(),
            { name            => 'coordinate_type',
              display         => 'Coordinate Type',
              type            => 'enum',
              default         => 'X',
              choices         => $choices,
              choices_display => $choices,
              description     => 'The coordinate or combination to take from the path.',
            },
           ];
  };

use constant::defer _parameter_info_planepath => sub {
  # require Module::Util;
  # cf ...::Generator->path_choices() order
  # my @choices = sort map { s/.*:://;
  #                          if (length() > $width) { $width = length() }
  #                          $_ }
  #   Module::Util::find_in_namespace('Math::PlanePath');

  # my @choices = Module::Find::findsubmod('Math::PlanePath');
  # @choices = grep {$_ ne 'Math::PlanePath'} @choices;

  # my $choices = ...::Generator->path_choices_array;
  # foreach (@$choices) {
  #   if (length() > $width) { $width = length() }
  # }

  require File::Spec;
  require Scalar::Util;
  my $width = 0;
  my %names;

  foreach my $dir (@INC) {
    next if ! defined $dir || ref $dir;
    # next if ref $dir eq 'CODE'  # subr
    #   || ref $dir eq 'ARRAY'    # array of subr and more
    #     || Scalar::Util::blessed($dir);

    opendir DIR, File::Spec->catdir ($dir, 'Math', 'PlanePath') or next;
    while (my $name = readdir DIR) {
      # basename of .pm files, and not emacs .#Foo.pm lockfiles
      $name =~ s/^([^.].*)\.pm$/$1/
        or next;
      if (length($name) > $width) { $width = length($name) }
      $names{$name} = 1;
    }
    closedir DIR;
  }
  my $choices = [ sort keys %names ];

  return { name        => 'planepath',
           display     => 'PlanePath Class',
           type        => 'string',
           default     => $choices->[0],
           choices     => $choices,
           width       => $width + 5,
           description => 'PlanePath module name.',
         };
};

#------------------------------------------------------------------------------

sub oeis_anum {
  my ($self) = @_;
  ### PlanePathCoord oeis_anum() ...

  my $planepath_object = $self->{'planepath_object'};
  my $coordinate_type = $self->{'coordinate_type'};

  if ($coordinate_type eq 'ExperimentalAbsX') {
    if (! $planepath_object->x_negative) { $coordinate_type = 'X'; }
  } elsif ($coordinate_type eq 'ExperimentalAbsY') {
    if (! $planepath_object->y_negative) { $coordinate_type = 'Y'; }
  }

  if ($planepath_object->isa('Math::PlanePath::Rows')) {
    if ($coordinate_type eq 'X') {
      return _oeis_anum_modulo($planepath_object->{'width'});
    }

  } elsif ($planepath_object->isa('Math::PlanePath::Columns')) {
    if ($coordinate_type eq 'Y') {
      return _oeis_anum_modulo($planepath_object->{'height'});
    }
  }

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
    ### whole table: $planepath_object->_NumSeq_Coord_oeis_anum
    ### key href: $planepath_object->_NumSeq_Coord_oeis_anum->{$key}

    if (my $anum = $planepath_object->_NumSeq_Coord_oeis_anum->{$key}->{$coordinate_type}) {
      return $anum;
    }
  }

  # all-zeros
  if (defined (my $values_min = $self->values_min)) {
    if (defined (my $values_max = $self->values_max)) {
      if ($values_min == 0 && $values_max == 0) {
        return 'A000004';  # all 0s
      }
      if ($values_min == 2 && $values_max == 2) {
        return 'A007395';  # all 2s
      }
    }
  }

  return undef;
}
sub _oeis_anum_modulo {
  my ($modulus) = @_;
  require Math::NumSeq::Modulo;
  return Math::NumSeq::Modulo->new(modulus=>$modulus)->oeis_anum;
}

sub _planepath_oeis_key {
  my ($path) = @_;
  ### PlanePathCoord _planepath_oeis_key() ...

  return join(',',
              ref($path),

              (map {
                # nasty hack to exclude SierpinskiCurveStair diagonal_length
                $_->{'name'} eq 'diagonal_length'
                  ? ()
                    : do {
                      my $value = $path->{$_->{'name'}};
                      if ($_->{'type'} eq 'boolean') {
                        $value = ($value ? 1 : 0);
                      }
                      ### $_
                      ### $value
                      ### gives: "$_->{'name'}=$value"
                      (defined $value ? "$_->{'name'}=$value" : ())
                    }
                  }
               _planepath_oeis_anum_parameter_info_list($path)));
}
sub _planepath_oeis_anum_key {
  my ($path) = @_;
  ### PlanePathCoord _planepath_oeis_key() ...
  return join(',',
              (map {
                # nasty hack to exclude SierpinskiCurveStair diagonal_length
                $_->{'name'} eq 'diagonal_length'
                  ? ()
                    : do {
                      my $value = $path->{$_->{'name'}};
                      if ($_->{'type'} eq 'boolean') {
                        $value = ($value ? 1 : 0);
                      }
                      ### $_
                      ### $value
                      ### gives: "$_->{'name'}=$value"
                      (defined $value ? "$_->{'name'}=$value" : ())
                    }
                  }
               _planepath_oeis_anum_parameter_info_list($path)));
}

sub _planepath_oeis_anum_parameter_info_list {
  my ($path) = @_;
  my @parameter_info_list = $path->_NumSeq_override_parameter_info_list;
  unless (@parameter_info_list) {
    @parameter_info_list = ($path->parameter_info_list,
                            $path->_NumSeq_extra_parameter_info_list);
  }
  return @parameter_info_list;
}

#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);

  my $planepath_object = ($self->{'planepath_object'}
                          ||= _planepath_name_to_object($self->{'planepath'}));

  ### coordinate func: '_coordinate_func_'.$self->{'coordinate_type'}
  {
    my $key = $self->{'coordinate_type'};
    $key =~ s{/}{div};
    $self->{'coordinate_func'}
      = $planepath_object->can("_NumSeq_Coord_${key}_func")
        || $self->can("_coordinate_func_$key")
          || croak "Unrecognised coordinate_type: ",$self->{'coordinate_type'};
  }
  $self->rewind;

  ### $self
  return $self;
}

sub _planepath_name_to_object {
  my ($name) = @_;
  ### PlanePathCoord _planepath_name_to_object(): $name
  ($name, my @args) = split /,+/, $name;
  unless ($name =~ /^Math::PlanePath::/) {
    $name = "Math::PlanePath::$name";
  }
  ### $name
  require Module::Load;
  Module::Load::load ($name);
  return $name->new (map {/(.*?)=(.*)/} @args);

  # width => $options{'width'},
  # height => $options{'height'},
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
  return (defined $self->{'i_start'}
          ? $self->{'i_start'}
          # nasty hack allow no 'planepath_object' when SUPER::new() calls
          # rewind()
          : $self->{'planepath_object'} &&
          $self->{'planepath_object'}->n_start);
}
sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
}
sub next {
  my ($self) = @_;
  ### NumSeq-PlanePathCoord next(): "i=$self->{'i'}"
  my $i = $self->{'i'}++;
  if (defined (my $value = &{$self->{'coordinate_func'}}($self, $i))) {
    return ($i, $value);
  } else {
    return;
  }
}
sub ith {
  my ($self, $i) = @_;
  ### NumSeq-PlanePathCoord ith(): $i
  return &{$self->{'coordinate_func'}}($self,$i);
}

use constant _INFINITY => do {
  my $x = 999;
  foreach (1 .. 20) {
    $x *= $x;
  }
  $x;
};
sub _coordinate_func_X {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return $x;
}
sub _coordinate_func_Y {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return $y;
}
sub _coordinate_func_Sum {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return $x + $y;
}
sub _coordinate_func_SumAbs {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return abs($x) + abs($y);
}
sub _coordinate_func_Product {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return $x * $y;
}
sub _coordinate_func_DiffXY {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return $x - $y;
}
sub _coordinate_func_DiffXYdiv2 {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return ($x - $y) / 2;
}
sub _coordinate_func_DiffYX {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return $y - $x;
}
sub _coordinate_func_AbsDiff {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return abs($x - $y);
}
sub _coordinate_func_Radius {
  my ($self, $n) = @_;
  return $self->{'planepath_object'}->n_to_radius($n);
}
sub _coordinate_func_RSquared {
  my ($self, $n) = @_;
  return $self->{'planepath_object'}->n_to_rsquared($n);
}

sub _coordinate_func_TRadius {
  my ($self, $n) = @_;
  return _path_n_to_tradius ($self->{'planepath_object'}, $n);
}
sub _coordinate_func_TRSquared {
  my ($self, $n) = @_;
  return _path_n_to_trsquared ($self->{'planepath_object'}, $n);
}
sub _path_n_to_tradius {
  my ($path, $n) = @_;
  # TRadius = sqrt(x^2+3*y^2)
  my $trsquared = _path_n_to_trsquared($path,$n);
  return (defined $trsquared ? sqrt($trsquared) : undef);
}
sub _path_n_to_trsquared {
  my ($path, $n) = @_;
  # TRSquared = x^2+3*y^2
  my ($x, $y) = $path->n_to_xy($n)
    or return undef;
  return $x*$x + $y*$y*3;
}

sub _coordinate_func_Depth {
  my ($self, $n) = @_;
  return $self->{'planepath_object'}->tree_n_to_depth($n);
}
sub _coordinate_func_NumChildren {
  my ($self, $n) = @_;
  return $self->{'planepath_object'}->tree_n_num_children($n);
}
sub _coordinate_func_IsLeaf {
  my ($self, $n) = @_;
  ### _coordinate_func_IsLeaf(): $n
  my $num_children = $self->{'planepath_object'}->tree_n_num_children($n);
  # undef, 0 or 1
  return (defined $num_children ? ($num_children == 0 ? 1 : 0) : undef);
}
sub _coordinate_func_IsNonLeaf {
  my ($self, $n) = @_;
  ### _coordinate_func_IsLeaf(): $n
  my $num_children = $self->{'planepath_object'}->tree_n_num_children($n);
  # undef, 0 or 1
  return (defined $num_children ? ($num_children == 0 ? 0 : 1) : undef);
}

use Math::PlanePath::GcdRationals;
use POSIX 'fmod';
sub _coordinate_func_GCD {
  my ($self, $n) = @_;

  # FIXME: Maybe re-run with bigrat if X or Y not integers.
  if ($self->{'planepath_object'}->isa('Math::PlanePath::KochSnowflakes')
      && $n <= 3) {
    return 1/3;
  }

  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;

  $x = abs($x);
  $y = abs($y);
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  if ($x == int($x) && $y == int($y)) {
    return Math::PlanePath::GcdRationals::_gcd($x,$y);
  }

  if ($x == 0) {
    return $y;
  }
  if ($y > $x) {
    $y = fmod($y,$x);
  }
  for (;;) {
    ### assert: $x >= 1
    if ($y == 0) {
      return $x;   # gcd(x,0)=x
    }
    if ($y < 0.00001) {
      return 0;
    }
    ($x,$y) = ($y, fmod($x,$y));
  }
}

sub _coordinate_func_RootN {
  my ($self, $n) = @_;
  return $self->{'planepath_object'}->tree_n_root($n);
}

# math-image --values=PlanePathCoord,coordinate_type=SubHeight,planepath=ThisPath --path=SierpinskiTriangle --scale=10
sub _coordinate_func_SubHeight {
  my ($self, $n) = @_;
  ### _coordinate_func_SubHeight(): $n
  my $height = $self->{'planepath_object'}->tree_n_to_subheight($n);
  return (defined $height ? $height : _INFINITY);
}

# rounding towards zero
sub _coordinate_func_IntXY {
  my ($self, $n) = @_;
  ### _coordinate_func_IntXY(): $n
  if (my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)) {
    return _xy_to_IntXY($x,$y);
  }
  return undef;
}
sub _xy_to_IntXY {
  my ($x, $y) = @_;
  ### xy: "x=$x  y=$y"
  if ($y < 0) {
    $y = -$y;
    $x = -$x;
  }
  if ($y == 0) {
    return _INFINITY;   # X/0 = infinity
  }
  if ($y == int($y)) {
    ### done in integers, no floating point ...
    my $r = $x % $y;
    ### $r
    if ($x < 0 && $r > 0) {
      $r -= $y;
    }
    ### assert: (($x>=0)&&($r>=0)) || (($x<=0)&&($r<=0))
    $x -= $r;
    ### assert: ($x % $y) == 0
    return int($x / $y);
  }
  return int($x/$y);
}
sub _coordinate_func_FracXY {
  my ($self, $n) = @_;
  ### _coordinate_func_FracXY(): $n

  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  ### xy: "x=$x  y=$y"
  if ($y < 0) {
    $y = -$y;
    $x = -$x;
  }
  if ($y == 0) {
    return 0;   # X/0 = infinity + frac=0
  }
  if ($y == int($y)) {
    ### done in integers ...
    my $r = $x % $y;
    if ($x < 0 && $r > 0) {
      $r -= $y;
    }
    # EXPERIMENTAL:
    # bigint/bigint as bigrat, otherwise promote to bigfloat
    if (ref $r && $r->isa('Math::BigInt')) {
      if (ref $y && $y->isa('Math::BigInt')) {
        require Math::BigRat;
        return Math::BigRat->new($r) / $y;
      }
      $r = $r->as_float;
    } else {
      if (ref $y && $y->isa('Math::BigInt')) { $y = $y->as_float; }
    }
    return $r/$y;
  } else {
    my $f = $x/$y;
    return $f - int($x/$y);
  }
}

# Math::BigInt in perl 5.6.0 has and/or/xor
sub _op_and { $_[0] & $_[1] }
sub _op_or  { $_[0] | $_[1] }
sub _op_xor { $_[0] ^ $_[1] }
sub _coordinate_func_BitAnd {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return _bitwise_by_parts($x,$y, \&_op_and);
}
sub _coordinate_func_BitOr {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return _bitwise_by_parts($x,$y, \&_op_or);
}
sub _coordinate_func_BitXor {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return _bitwise_by_parts($x,$y, \&_op_xor);
}
use constant 1.02 _UV_MAX_PLUS_1 => do {
  my $pow = 1.0;
  my $uv = ~0;
  while ($uv) {
    $uv >>= 1;
    $pow *= 2.0;
  }
  $pow
};
sub _bitwise_by_parts {
  my ($x, $y, $opfunc) = @_;
  ### _bitwise_by_parts(): $x, $y

  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  # Positive integers in UV range plain operator.
  # Any ref is Math::BigInt or whatever left to its operator overloads.
  if (ref $x || ref $y
      || ($x == int($x) && $y == int($y)
          && $x >= 0 && $y >= 0
          && $x < _UV_MAX_PLUS_1 && $x < _UV_MAX_PLUS_1)) {
    return &$opfunc($x,$y);
  }

  $x *= 65536.0;
  $x *= 65536.0;
  $x = int($x);
  $y *= 65536.0;
  $y *= 65536.0;
  $y = int($y);

  my @ret; # low to high
  while ($x >= 1 || $x < -1 || $y >= 1 || $y < -1) {
    ### $x
    ### $y

    my $xpart = $x % 65536.0;
    if ($xpart < 0) { $xpart += 65536.0; }
    $x = ($x - $xpart) / 65536.0;

    my $ypart = $y % 65536.0;
    if ($ypart < 0) { $ypart += 65536.0; }
    $y = ($y - $ypart) / 65536.0;

    ### xpart: $xpart . sprintf(' %04X',$xpart)
    ### ypart: $ypart . sprintf(' %04X',$ypart)
    push @ret, &$opfunc($xpart,$ypart);
  }
  my $ret = (&$opfunc($x<0,$y<0) ? -1 : 0);
  ### @ret
  ### $x
  ### $y
  ### $ret
  foreach my $rpart (reverse @ret) { # high to low
    $ret = 65536.0*$ret + $rpart;
  }
  ### ret joined: $ret
  $ret /= 65536.0;
  $ret /= 65536.0;
  ### ret final: $ret
  return $ret;
}
use constant 1.02 _IV_MIN => - (~0 >> 1) - 1;
sub _sign_extend {
  my ($n) = @_;
  return ($n - (- _IV_MIN)) + _IV_MIN;
}
use constant 1.02 _UV_NUMBITS => do {
  my $uv = ~0;
  my $count = 0;
  while ($uv) {
    $uv >>= 1;
    $count++;
    last if $count >= 1024;
  }
  $count
};
sub _frac_to_int {
  my ($x) = @_;
  $x -= int($x);
  return int(abs($x)*(2**_UV_NUMBITS()));
}
sub _int_to_frac {
  my ($x) = @_;
  return $x / (2**_UV_NUMBITS());
}

sub _coordinate_func_Min {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return min($x,$y);
}
sub _coordinate_func_Max {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return max($x,$y);
}

sub _coordinate_func_MinAbs {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return min(abs($x),abs($y));
}
sub _coordinate_func_MaxAbs {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return max(abs($x),abs($y));
}

sub _coordinate_func_NumSiblings {
  my ($self, $n) = @_;
  return path_tree_n_num_siblings($self->{'planepath_object'}, $n);
}
# ENHANCE-ME: if $n==NaN would like to return NaN, maybe
sub path_tree_n_num_siblings {
  my ($path, $n) = @_;
  $n = $path->tree_n_parent($n);
  return (defined $n
          ? $path->tree_n_num_children($n) - 1  # not including self
          : 0);  # any tree root considered to have no siblings
}

#------------------------------------------------------------------------------
# UNTESTED/EXPERIMENTAL

# n_start = i_start is X(n)
# n_start + 1       is Y(n) etc
#
# floor((n - nstart)/2) + nstart
# = floor((n - nstart)/2 + nstart)
# = floor((n + nstart)/2)
# xy = n - nstart mod 2
#    = n - nstart + 2*nstart mod 2
#    = n + nstart mod 2
#
# GP-Test  my(nstart=0,n=0); floor((n+nstart)/2)==0 && (n+nstart)%2==0
# GP-Test  my(nstart=0,n=1); floor((n+nstart)/2)==0 && (n+nstart)%2==1
#
# GP-Test  my(nstart=3,n=3); floor((n+nstart)/2)==3 && (n+nstart)%2==0
# GP-Test  my(nstart=3,n=4); floor((n+nstart)/2)==3 && (n+nstart)%2==1
# GP-Test  my(nstart=3,n=5); floor((n+nstart)/2)==4 && (n+nstart)%2==0
# GP-Test  my(nstart=3,n=6); floor((n+nstart)/2)==4 && (n+nstart)%2==1
#
sub _coordinate_func_ExperimentalPairsXY {
  my ($self, $n) = @_;
  my $path = $self->{'planepath_object'};
  $n += $path->n_start;
  my $xy = _divrem_mutate($n,2);
  my ($x, $y) = $path->n_to_xy($n) or return undef;
  return ($xy ? $y : $x);
}
sub _coordinate_func_ExperimentalPairsYX {
  my ($self, $n) = @_;
  my $path = $self->{'planepath_object'};
  $n += $path->n_start;
  my $xy = _divrem_mutate($n,2);
  my ($x, $y) = $path->n_to_xy($n) or return undef;
  return ($xy ? $x : $y);
}

sub _coordinate_func_ExperimentalAbsX {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return abs($x);
}
sub _coordinate_func_ExperimentalAbsY {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return abs($y);
}

# DiffXYsquared = X^2 - Y^2
sub _coordinate_func_ExperimentalDiffXYsquared {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return $x*$x - $y*$y;
}
# DiffYXsquared = Y^2 - X^2
sub _coordinate_func_ExperimentalDiffYXsquares {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return $y*$y - $x*$x;
}

sub _coordinate_func_ExperimentalLeafDistance {
  my ($self, $n) = @_;
  if (my $coderef = $self->{'planepath_object'}
      ->can('_EXPERIMENTAL__tree_n_to_leafdist')) {
    return $self->{'planepath_object'}->$coderef($n);
  }
  return path_tree_n_to_leafdist_by_search($self->{'planepath_object'},$n);
}
sub path_tree_n_to_leafdist_by_search {
  my ($path, $n) = @_;
  ### path_tree_n_to_leafdist(): $n

  if ($n < $path->n_start || ! $path->tree_any_leaf($path)) {
    return undef;
  }
  if (is_infinite($n)) {
    return $n;
  }
  my @pending = ($n);
  for (my $distance = 0; ; $distance++) {
    ### $distance
    ### @pending

    @pending = map {
      my @children = $path->tree_n_children($_)
        or return $distance;
      ### @children
      @children
    } @pending;
  }
}

sub _coordinate_func_ExperimentalNumOverlap {
  my ($self, $n) = @_;
  my ($x,$y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return _path_xy_num_overlaps($self->{'planepath_object'}, $x,$y);
}
# $path->xy_num_overlaps($x,$y)
# Return the number of ...
sub _path_xy_num_overlaps {
  my ($path, $x,$y) = @_;
  my @n_list = $path->xy_to_n_list($x,$y);
  return scalar(@n_list) - 1;
}

# math-image --values=PlanePathCoord,coordinate_type=ExperimentalNeighbours4,planepath=DragonCurve --path=DragonCurve --scale=10
my $neighbours3 = [ 2,0,  -1,1,  -1,-1 ];
sub _coordinate_func_ExperimentalNeighbours3 {
  my ($self, $n) = @_;
  return _path_n_neighbours_count ($self->{'planepath_object'}, $n, $neighbours3);
}
my $neighbours4 = [ 1,0, 0,1, -1,0, 0,-1 ];
sub _coordinate_func_ExperimentalNeighbours4 {
  my ($self, $n) = @_;
  return _path_n_neighbours_count ($self->{'planepath_object'}, $n, $neighbours4);
}
my $neighbours4d = [ 1,1, -1,1, -1,-1, 1,-1 ];
sub _coordinate_func_ExperimentalNeighbours4d {
  my ($self, $n) = @_;
  return _path_n_neighbours_count ($self->{'planepath_object'}, $n, $neighbours4d);
}
my $neighbours8 = [ 1,0, 0,1, -1,0, 0,-1,
                    1,1, -1,1, 1,-1, -1,-1 ];
sub _coordinate_func_ExperimentalNeighbours8 {
  my ($self, $n) = @_;
  return _path_n_neighbours_count ($self->{'planepath_object'}, $n, $neighbours8);
}
# ExperimentalNeighbours6v   triangular vertical
  my $neighbours6 = [ 2,0,   1,1,  -1,1,
                      -2,0, -1,-1, 1,-1 ];
sub _coordinate_func_ExperimentalNeighbours6 {
  my ($self, $n) = @_;
  return _path_n_neighbours_count ($self->{'planepath_object'}, $n, $neighbours6);
}
sub _path_n_neighbours_count {
  my ($path, $n, $neighbours_aref) = @_;
  # my $aref = $surround[$num_points]
  #   || croak "_path_n_neighbours_count() unrecognised number of points ",$num_points;
  my ($x, $y) = $path->n_to_xy($n) or return undef;
  my $count = 0;
  for (my $i = 0; $i < @$neighbours_aref; $i+=2) {
    $count += $path->xy_is_visited($x + $neighbours_aref->[$i],
                                   $y + $neighbours_aref->[$i+1]);
  }
  return $count;
}

sub _coordinate_func_ExperimentalGcdDivisions {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  $x = abs(int($x));
  $y = abs(int($y));
  if ($x == 0) {
    return $y;
  }
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  if ($x < $y) { ($x,$y) = ($y,$x); }
  my $count = 0;
  for (;;) {
    if ($y <= 1) {
      return $count;
    }
    ($x,$y) = ($y, $x % $y);
    $count++;
  }
}

# 1 for first visit, 2, 3, ... for subsequent
sub _coordinate_func_ExperimentalVisitNum {
  my ($self, $n) = @_;
  my $path = $self->{'planepath_object'};
  if (my ($x,$y) = $path->n_to_xy($n)) {
    my @n_list = grep {$_<=$n} $path->n_to_n_list($n);
    return scalar(@n_list);
  }
  return undef;
}

# number of visits ever made to location of $n, including $n itself so >=1
sub _coordinate_func_ExperimentalVisitCount {
  my ($self, $n) = @_;
  return path_n_num_visits($self->{'planepath_object'}, $n);
}
# $path->n_to_visit_count($n)
# Return the number of visits to the curve at point C<$n>, including C<$n>
# itself.  If there is no C<$n> in the path then return C<undef>.
sub path_n_num_visits {
  my ($path, $n) = @_;
  my ($x,$y) = $path->n_to_xy($n) or return undef;
  my @n_list = $path->xy_to_n_list($x,$y);
  return scalar(@n_list);
}

# number of revisits ever made to location of $n, so 0 if never
sub _coordinate_func_ExperimentalRevisit {
  my ($self, $n) = @_;
  return path_n_to_revisit($self->{'planepath_object'}, $n);
}
# $path->path_n_to_revisit($n)
# Return the number of other N which visit point C<$n>.
# If point C<$n> is visited only by that C<$n> then the return is 0.
sub path_n_to_revisit {
  my ($path, $n) = @_;
  if (my ($x, $y) = $path->n_to_xy($n)) {
    my $ret = 0;
    foreach my $n_list ($path->n_to_n_list($n)) {
      if ($n == $n_list) { return $ret; }
      $ret++;
    }
  }
  return undef;
}

# A215200 Triangle read by rows, Kronecker symbol (n-k|k) for n>=1, 1<=k<=n.

# cf A005825 ExperimentalNumerators in a worst case of a Jacobi symbol algorithm.
#    A005826 Worst case of a Jacobi symbol algorithm.
#    A005827 Worst case of a Jacobi symbol algorithm.
# A157415 Triangle t(n,m) = Jacobi(prime(n) / prime(m)) + Jacobi( prime(n)/ prime(n-m+2)), 2<=m<=n.

sub _coordinate_func_ExperimentalKroneckerSymbol {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return _kronecker_symbol($x,$y);
}
sub _kronecker_symbol {
  my ($x, $y) = @_;
  ### _kronecker_symbol(): "x=$x y=$y"
  $x = int($x);
  $y = int($y);
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  if ($x == 0) {
    # (0/b)=1 if b=+/-1, (0/b)=0 otherwise
    return ($y == 1 || $y == -1 ? 1 : 0);
  }

  if ($y == 0) {
    # (a/0)=1 if a=+/-1, (a/0)=0 otherwise
    return ($x == 1 || $x == -1 ? 1 : 0);
  }

  my $ret = 0;

  # (a/-1)=1 if a>=0, (a/-1)=-1 if a<0
  if ($y < 0) {
    $y = abs($y);
    if ($x < 0) {
      ### (a/-1) = -1 when a<0 ...
      $ret = 2;
    }
  }

  if ($y % 2 == 0) {
    if ($x % 2 == 0) {
      return 0;  # (even/even)=0
    }
    # (a/2) = (2/a)
    while ($y && $y % 4 == 0) { # (a/2)*(a/2)=1
      ### initial y multiple of 4 ...
      $y /= 4;
    }
    # (b/2)=(2/b) for b odd
    # (2/b) = (-1)^((b^2-1)/8) which is 1 if b==1,7mod8 or -1 if b==3,5mod8
    if ($y % 2 == 0) {
      ### initial y even, xor: (($x+1)/2) & 2
      ### assert: $x % 2 != 0
      $ret ^= ($x+1)/2;
      $y /= 2;
    }
  }

  for (;;) {
    ### at: "x=$x  y=$y"
    ### assert: $y%2 != 0

    if ($y <= 1) {
      ### y=1 stop (a/1)=1 ...
      last;
    }
    ### assert: $y > 1

    $x %= $y;
    ### remainder to: "x=$x"
    if ($x <= 1) {
      ### stop, (1/b) = 1 ...
      last;
    }

    # (2/b) with b odd is (-1)^((b^2-1)/8)
    # is (2/b)=1 if b==1,7mod8 or (2/b)=-1 if b==3,5mod8
    while ($x && $x % 4 == 0) {
      ### x multiple of 4 ...
      $x /= 4;
    }
    if ($x % 2 == 0) {
      # (2/b) = (-1)^((b^2-1)/8) which is 1 if b==1,7mod8 or -1 if b==3,5mod8
      ### x even, xor: (($y+1)/2) & 2
      $ret ^= ($y+1)/2;
      $x /= 2;
    }

    ### reciprocity, xor: ($x % 4) & ($y % 4) & 2
    $ret ^= ($x % 4) & ($y % 4);
    ($x,$y) = ($y,$x);
  }

  if ($x == 0) {
    ### (0/b)=0 ...
    return 0;
  }

  ### final ret: ($ret & 2)
  return ($ret & 2 ? -1 : 1);
}

sub _coordinate_func_ExperimentalMaxAbsTri {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return max(abs($x+$y),abs($x-$y),abs(2*$y));
}
sub _coordinate_func_ExperimentalMinAbsTri {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  return min(abs($x+$y),abs($x-$y),abs(2*$y));
}

sub _coordinate_func_ExperimentalRowOffset {
  my ($self, $n) = @_;
  return path_n_to_row_offset ($self->{'planepath_object'}, $n);
}
sub path_n_to_row_offset {
  my ($path, $n) = @_;
  my $depth = $path->tree_n_to_depth($n);
  if (! defined $depth) { return undef; }

  my ($n_row, $n_end) = $path->tree_depth_to_n_range($depth);
  if ($n_end - $n_row + 1 == $path->tree_depth_to_width($depth)) {
    return $n - $n_row;
  }
  my $ret = 0;
  foreach my $i ($n_row .. $n - 1) {
    if ($path->tree_n_to_depth($i) == $depth) {
      $ret++;
    }
  }
  return $ret;
}

use Math::PlanePath::GcdRationals;
sub _coordinate_func_ExperimentalMulDist {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  $x = int(abs($x));
  $y = int(abs($y));
  if (my $g = Math::PlanePath::GcdRationals::_gcd($x,$y)) {
    $x /= $g;
    $y /= $g;
  }
  unless ($x < (2.0**32) && $y < (2.0**32)) {
    return undef;
  }
  require Math::Factor::XS;
  return Math::Factor::XS::count_prime_factors($x) + Math::Factor::XS::count_prime_factors($y);
}

# Count of differing bit positions.
# Infinite if twos-comp negative.
# 1111 -1   1
# 1101 -2  10
# 1110 -3  11
#
use Math::PlanePath::Base::Digits
  'bit_split_lowtohigh';
sub _coordinate_func_ExperimentalHammingDist {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  # twos complement
  if ($x<0) {
    if ($y >= 0) { return _INFINITY; }
    $x = -$x;
    $y = -$y;
  } else {
    if ($y < 0) { return _INFINITY; }
  }

  # abs values
  # $x = abs(int($x));
  # $y = abs(int($y));

  my @xbits = bit_split_lowtohigh($x);
  my @ybits = bit_split_lowtohigh($y);
  my $ret = 0;
  while (@xbits || @ybits) {
    $ret += (shift @xbits ? 1 : 0) ^ (shift @ybits ? 1 : 0);
  }
  return $ret;
}

sub _coordinate_func_ExperimentalParity {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  $x += $y;
  $y = _floor($x);
  $y -= ($y % 2);
  return $x - $y;
}
sub _floor {
  my ($x) = @_;
  my $int = int($x);
  return ($x < $int ? $int-1 : $int);
}

sub _coordinate_func_ExperimentalNumerator {
  my ($self, $n) = @_;
  ### _coordinate_func_ExperimentalNumerator(): $n
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  ### $x
  ### $y
  if ($y < 0) { $x = -$x; }
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }
  my $g = Math::PlanePath::GcdRationals::_gcd(abs($x),abs($y));
  return ($g == 0
          ? 0 :
          $x/$g);
}
sub _coordinate_func_ExperimentalDenominator {
  my ($self, $n) = @_;
  my ($x, $y) = $self->{'planepath_object'}->n_to_xy($n)
    or return undef;
  if ($y < 0) {
    $x = -$x;
    $y = -$y;
  }
  if ($y == 0) {
    # +-any/0 reckoned as 1/0
    return $y;
  }
  if (is_infinite($x)) {
    return $x;   # +-inf/nonzero = +-inf
  }

  if ($x == 0                # 0/nonzero reckoned as 0/1
      || is_infinite($y)) {  # +-finite/+inf reckoned as 0/1
    return 1;
  }

  my $g = Math::PlanePath::GcdRationals::_gcd(abs($x),$y);
  if ($g == 0) {
    # X/0 reckoned as 1/0
    return 0;
  }
  return abs($y)/$g;
}


#------------------------------------------------------------------------------

sub characteristic_integer {
  my ($self) = @_;
  ### PlanePathCoord characteristic_integer() ...

  my $planepath_object = $self->{'planepath_object'};
  if (my $func = $planepath_object->can("_NumSeq_Coord_$self->{'coordinate_type'}_integer")) {
    return $planepath_object->$func();
  }
  if (defined (my $values_min = $self->values_min)
      && defined (my $values_max = $self->values_max)) {
    if ($values_min == int($values_min)
        && $values_max == int($values_max)
        && $values_min == $values_max) {
      return 1;
    }
  }
  return undef;
}

sub characteristic_smaller {
  my ($self) = @_;
  ### characteristic_smaller() ...
  my $planepath_object = $self->{'planepath_object'};
  my $func;
  return
    (($func = ($planepath_object->can("_NumSeq_Coord_$self->{'coordinate_type'}_smaller")))
     ? $planepath_object->$func()
     : 1); # default is smaller
}

{
  my %coordinate_to_d_minimum_method
    = (X       => 'dx_minimum',
       Y       => 'dy_minimum',
       Sum     => 'dsumxy_minimum',
       DiffXY  => 'ddiffxy_minimum',
       DiffYX  => \&path_ddiffyx_minimum,
      );
  sub path_ddiffyx_minimum {
    my ($path) = @_;
    my $ddiffxy_maximum = $path->ddiffxy_maximum();
    return (defined $ddiffxy_maximum ? - $ddiffxy_maximum : undef);
  }

  my %coordinate_type_monotonic_use
    = (RSquared  => 'Radius',
       TRSquared => 'TRadius',
      );

  sub characteristic_increasing {
    my ($self) = @_;
    ### PlanePathCoord characteristic_increasing() ...
    my $planepath_object = $self->{'planepath_object'};
    my $coordinate_type = $self->{'coordinate_type'};

    # eg. if dx_minimum() > 0 then X is increasing
    if (my $method = $coordinate_to_d_minimum_method{$coordinate_type}) {
      my $d_minimum = $planepath_object->$method();
      ### delta method: $method
      ### $d_minimum
      return (defined $d_minimum && $d_minimum > 0);
    }

    $coordinate_type = ($coordinate_type_monotonic_use{$coordinate_type}
                        || $coordinate_type);
    if (my $coderef = $planepath_object->can("_NumSeq_Coord_${coordinate_type}_increasing")) {
      ### dispatch to: $coderef
      return $planepath_object->$coderef();
    }
    ### unknown ...
    return undef;
  }

  sub characteristic_non_decreasing {
    my ($self) = @_;
    ### PlanePathCoord characteristic_non_decreasing() ...
    my $planepath_object = $self->{'planepath_object'};
    my $coordinate_type = $self->{'coordinate_type'};

    # eg. if dx_minimum() >= 0 then X is non-decreasing
    if (my $method = $coordinate_to_d_minimum_method{$coordinate_type}) {
      my $d_minimum = $planepath_object->$method();
      ### delta method: $method
      ### $d_minimum
      return (defined $d_minimum && $d_minimum >= 0);
    }

    if (defined (my $values_min = $self->values_min)) {
      if (defined (my $values_max = $self->values_max)) {
        if ($values_min == $values_max) {
          ### constant seq is non-decreasing ...
          return 1;
        }
      }
    }
    $coordinate_type = ($coordinate_type_monotonic_use{$coordinate_type}
                        || $coordinate_type);
    if (my $coderef = $planepath_object->can("_NumSeq_Coord_${coordinate_type}_non_decreasing")) {
      ### dispatch to: $coderef
      return $planepath_object->$coderef();
    }
    ### if increasing then non_decreasing too ...
    return $self->characteristic_increasing;
  }
}

{
  my %values_min = (X           => 'x_minimum',
                    Y           => 'y_minimum',
                    Sum         => 'sumxy_minimum',
                    SumAbs      => 'sumabsxy_minimum',
                    DiffXY      => 'diffxy_minimum',
                    AbsDiff     => 'absdiffxy_minimum',
                    RSquared    => 'rsquared_minimum',
                    GCD         => 'gcdxy_minimum',
                    NumChildren => 'tree_num_children_minimum',
                   );

  sub values_min {
    my ($self) = @_;
    ### PlanePathCoord values_min() ...
    my $planepath_object = $self->{'planepath_object'};
    if (my $method = ($values_min{$self->{'coordinate_type'}}
                      || $planepath_object->can("_NumSeq_Coord_$self->{'coordinate_type'}_min"))) {
      ### $method
      return $planepath_object->$method();
    }
    return undef;
  }
}
{
  my %values_max = (X           => 'x_maximum',
                    Y           => 'y_maximum',
                    Sum         => 'sumxy_maximum',
                    SumAbs      => 'sumabsxy_maximum',
                    DiffXY      => 'diffxy_maximum',
                    AbsDiff     => 'absdiffxy_maximum',
                    GCD         => 'gcdxy_maximum',
                    NumChildren => 'tree_num_children_maximum',
                   );
  sub values_max {
    my ($self) = @_;
    my $planepath_object = $self->{'planepath_object'};
    if (my $method = ($values_max{$self->{'coordinate_type'}}
                      || $planepath_object->can("_NumSeq_Coord_$self->{'coordinate_type'}_max"))) {
      return $planepath_object->$method();
    }
    return undef;
  }
}

{ package Math::PlanePath;
  use constant _NumSeq_override_parameter_info_list => ();
  use constant _NumSeq_extra_parameter_info_list => ();
  use constant _NumSeq_Coord_oeis_anum => {};

  #-------------
  sub _NumSeq_Coord_neighbours_min {
    my ($self, $neighbours_aref) = @_;
    my %hash;
    for (my $i = 0; $i < $#$neighbours_aref; $i+=2) {
      $hash{"$neighbours_aref->[$i],$neighbours_aref->[$i+1]"} = 1;
    }
    my @dxdy_list = $self->_UNDOCUMENTED__dxdy_list;
    for (my $i = 0; $i < $#dxdy_list; $i += 2) {
      if ($hash{"$dxdy_list[$i],dxdy_list[$i+1]"}) {
        return 1;
      }
    }
    return 0;
  }
  use constant _NumSeq_Coord_filling_type => 'plane';
  {
    my %_NumSeq_Coord_ExperimentalNeighbours3_min
      = (plane      => 3,
         triangular => 3,
         quadrant   => 1,
         half       => 2,
        );
    sub _NumSeq_Coord_ExperimentalNeighbours3_min {
      my ($self) = @_;
      if (my $filling_type = $self->_NumSeq_Coord_filling_type) {
        return $_NumSeq_Coord_ExperimentalNeighbours3_min{$filling_type};
      }
      _NumSeq_Coord_neighbours_min($self,$neighbours3);
    }
  }
  {
    my %_NumSeq_Coord_ExperimentalNeighbours4_min
      = (plane      => 4,
         triangular => 0,
         quadrant   => 2,
         half       => 3,
        );
    sub _NumSeq_Coord_ExperimentalNeighbours4_min {
      my ($self) = @_;
      if (my $filling_type = $self->_NumSeq_Coord_filling_type) {
        return $_NumSeq_Coord_ExperimentalNeighbours4_min{$filling_type};
      }
      _NumSeq_Coord_neighbours_min($self,$neighbours3);
    }
  }
  {
    my %_NumSeq_Coord_ExperimentalNeighbours4d_min
      = (plane      => 4,
         triangular => 4,
         quadrant   => 1,
         half       => 2,
        );
    sub _NumSeq_Coord_ExperimentalNeighbours4d_min {
      my ($self) = @_;
      if (my $filling_type = $self->_NumSeq_Coord_filling_type) {
        return $_NumSeq_Coord_ExperimentalNeighbours4d_min{$filling_type};
      }
      _NumSeq_Coord_neighbours_min($self,$neighbours3);
    }
  }
  {
    my %_NumSeq_Coord_ExperimentalNeighbours6_min
      = (plane      => 6,
         triangular => 6,
         quadrant   => 1,
         half       => 4,
        );
    sub _NumSeq_Coord_ExperimentalNeighbours6_min {
      my ($self) = @_;
      if (my $filling_type = $self->_NumSeq_Coord_filling_type) {
        return $_NumSeq_Coord_ExperimentalNeighbours6_min{$filling_type};
      }
      _NumSeq_Coord_neighbours_min($self,$neighbours3);
    }
  }
  {
    my %_NumSeq_Coord_ExperimentalNeighbours8_min
      = (plane      => 8,
         triangular => 4,
         quadrant   => 3,
         half       => 5,
        );
    sub _NumSeq_Coord_ExperimentalNeighbours8_min {
      my ($self) = @_;
      if (my $filling_type = $self->_NumSeq_Coord_filling_type) {
        return $_NumSeq_Coord_ExperimentalNeighbours8_min{$filling_type};
      }
      _NumSeq_Coord_neighbours_min($self,$neighbours3);
    }
  }

  use constant _NumSeq_Coord_ExperimentalNeighbours3_max => 3;
  use constant _NumSeq_Coord_ExperimentalNeighbours4d_max => 4;
  use constant _NumSeq_Coord_ExperimentalNeighbours6_max => 6;
  use constant _NumSeq_Coord_ExperimentalNeighbours8_max => 8;

  sub _NumSeq_Coord_ExperimentalNeighbours4_max {
    my ($self) = @_;
    if (my $filling_type = $self->_NumSeq_Coord_filling_type) {
      if ($filling_type eq 'triangular') { return 0; }
    }
    return 4;
  }

  use constant _NumSeq_Coord_ExperimentalNeighbours3_integer => 1; # counts
  use constant _NumSeq_Coord_ExperimentalNeighbours4_integer => 1;
  use constant _NumSeq_Coord_ExperimentalNeighbours4d_integer => 1;
  use constant _NumSeq_Coord_ExperimentalNeighbours6_integer => 1;
  use constant _NumSeq_Coord_ExperimentalNeighbours8_integer => 1;


  #------
  # X
  use constant _NumSeq_Coord_X_integer => 1;  # usually
  use constant _NumSeq_Coord_X_increasing => undef;
  use constant _NumSeq_Coord_X_non_decreasing => undef;

  #------
  # Y
  use constant _NumSeq_Coord_Y_integer => 1;  # usually
  use constant _NumSeq_Coord_Y_increasing => undef;
  use constant _NumSeq_Coord_Y_non_decreasing => undef;


  #------
  # Sum

  sub _NumSeq_Coord_Sum_integer {
    my ($self) = @_;
    ### _NumSeq_Coord_Sum_integer() ...
    return ($self->_NumSeq_Coord_X_integer
            && $self->_NumSeq_Coord_Y_integer);
  }
  *_NumSeq_Coord_SumAbs_integer    = \&_NumSeq_Coord_Sum_integer;
  *_NumSeq_Coord_Product_integer   = \&_NumSeq_Coord_Sum_integer;
  *_NumSeq_Coord_DiffXY_integer    = \&_NumSeq_Coord_Sum_integer;
  *_NumSeq_Coord_AbsDiff_integer   = \&_NumSeq_Coord_Sum_integer;
  *_NumSeq_Coord_RSquared_integer  = \&_NumSeq_Coord_Sum_integer;
  *_NumSeq_Coord_TRSquared_integer = \&_NumSeq_Coord_Sum_integer;
  *_NumSeq_Coord_ExperimentalDiffXYsquared_integer  = \&_NumSeq_Coord_Sum_integer;
  *_NumSeq_Coord_ExperimentalDiffYXsquares_integer  = \&_NumSeq_Coord_Sum_integer;

  sub _NumSeq_Coord_Product_min {
    my ($self) = @_;
    my ($x_minimum, $y_minimum);
    if (defined ($x_minimum = $self->x_minimum)
        && defined ($y_minimum = $self->y_minimum)
        && $x_minimum >= 0
        && $y_minimum >= 0) {
      return $x_minimum * $y_minimum;
    }
    return undef;
  }
  sub _NumSeq_Coord_Product_max {
    my ($self) = @_;
    my ($x_max, $y_minimum);
    ### X_max: $self->x_maximum
    ### Y_min: $self->y_minimum
    if (defined ($x_max = $self->x_maximum)
        && defined ($y_minimum = $self->y_minimum)
        && $x_max <= 0
        && $y_minimum >= 0) {
      # X all negative, Y all positive
      return $y_minimum * $x_max;
    }
    return undef;
  }

  #----------
  # DiffYX opposite of DiffXY
  sub _NumSeq_Coord_DiffYX_min {
    my ($self) = @_;
    if (defined (my $m = $self->diffxy_maximum)) {
      return - $m;
    } else {
      return undef;
    }
  }
  sub _NumSeq_Coord_DiffYX_max {
    my ($self) = @_;
    if (defined (my $m = $self->diffxy_minimum)) {
      return - $m;
    } else {
      return undef;
    }
  }
  sub _NumSeq_Coord_DiffYX_integer {
    my ($self) = @_;
    return $self->_NumSeq_Coord_DiffXY_integer;
  }

  #----------
  # Radius

  sub _NumSeq_Coord_Radius_min {
    my ($path) = @_;
    return sqrt($path->rsquared_minimum);
  }
  sub _NumSeq_Coord_Radius_max {
    my ($path) = @_;
    my $rsquared_maximum = $path->rsquared_maximum;
    return (defined $rsquared_maximum ? sqrt($rsquared_maximum) : undef);
  }

  #----------
  # TRadius

  sub _NumSeq_Coord_TRadius_min {
    my ($path) = @_;
    return sqrt($path->_NumSeq_Coord_TRSquared_min);
  }
  sub _NumSeq_Coord_TRSquared_min {
    my ($self) = @_;

    # The X and Y each closest to the origin.  This assumes that point is
    # actually visited, but is likely to be close.
    my $x_minimum = $self->x_minimum;
    my $x_maximum = $self->x_maximum;
    my $y_minimum = $self->y_minimum;
    my $y_maximum = $self->y_maximum;
    my $x = ((  defined $x_minimum && $x_minimum) > 0 ? $x_minimum
             : (defined $x_maximum && $x_maximum) < 0 ? $x_maximum
             : 0);
    my $y = ((  defined $y_minimum && $y_minimum) > 0 ? $y_minimum
             : (defined $y_maximum && $y_maximum) < 0 ? $y_maximum
             : 0);
    return ($x*$x + 3*$y*$y);
  }

  sub _NumSeq_Coord_IntXY_min {
    my ($self) = @_;
    if (defined(my $x = $self->x_minimum)
        && defined(my $y = $self->y_minimum)) {
      if ($y >= 0) {
        if ($y == 0) {
          $y = 1;
        }
        if ($x >= 0 && $y <= $x) {
          $y = 2*$x;
          if (defined (my $y_maximum = $self->y_maximum)) {
            $y = List::Util::min($y, $y_maximum);
          }
        }
        ### using: "x=$x  y=$y"
        # presume that point x_minimum(),y_minimum() occurs
        return Math::NumSeq::PlanePathCoord::_xy_to_IntXY($x,$y);
      }
    }
    return undef;
  }
  use constant _NumSeq_Coord_IntXY_max => undef;
  use constant _NumSeq_Coord_IntXY_integer => 1;

  use constant _NumSeq_Coord_FracXY_max => 1;
  use constant _NumSeq_FracXY_max_is_supremum => 1;
  sub _NumSeq_Coord_FracXY_min {
    my ($self) = @_;
    if (! $self->x_negative && ! $self->y_negative) {
      return 0;
    } else {
      return -1;
    }
  }
  *_NumSeq_FracXY_min_is_infimum = \&_NumSeq_Coord_FracXY_min; # if non-zero
  use constant _NumSeq_Coord_FracXY_integer => 0;

  use constant _NumSeq_Coord_ExperimentalParity_min => 0;
  sub _NumSeq_Coord_ExperimentalParity_integer { $_[0]->_NumSeq_Coord_Sum_integer }
  sub _NumSeq_Coord_ExperimentalParity_max {
    my ($self) = @_;
    return ($self->_NumSeq_Coord_ExperimentalParity_integer
            ? 1
            : 2);
  }
  sub _NumSeq_ExperimentalParity_max_is_supremum {
    my ($self) = @_;
    return ($self->_NumSeq_Coord_ExperimentalParity_integer ? 0 : 1);
  }

  sub _NumSeq_Coord_ExperimentalNumerator_min {
    my ($self) = @_;
    if (defined (my $gcd_maximum = $self->gcdxy_maximum)) {
      if ($gcd_maximum == 1) {
        return $self->x_minimum;  # X,Y no common factor, so ExperimentalNumerator==X
      }
    }
    if (! $self->y_negative
        && defined (my $x_minimum = $self->x_minimum)) {
      ### $x_minimum
      if ($x_minimum >= 1) {
        return 1;  # somewhere X/Y dividing out to 1/Z
      }
      if ($x_minimum >= 0) {
        return 0;  # 0/Y
      }
    }
    return undef;
  }
  use constant _NumSeq_Coord_ExperimentalNumerator_integer => 1;

  sub _NumSeq_Coord_ExperimentalDenominator_min {
    my ($self) = @_;
    if (defined (my $y_minimum = $self->y_minimum)) {
      if ($y_minimum > 0) {
        return 1;  # X/0=1/0 doesn't occur, so den>=1
      }
      if ($y_minimum == 0) {
        return 0;  # X/0=1/0
      }
    }
    return 0;
  }
  use constant _NumSeq_Coord_ExperimentalDenominator_integer => 1;

  # fractional part treated bitwise
  *_NumSeq_Coord_BitAnd_integer    = \&_NumSeq_Coord_Sum_integer;
  *_NumSeq_Coord_BitOr_integer     = \&_NumSeq_Coord_Sum_integer;
  *_NumSeq_Coord_BitXor_integer    = \&_NumSeq_Coord_Sum_integer;

  #-------------
  # GCD

  use constant _NumSeq_Coord_GCD_integer => 1;

  use constant _NumSeq_Coord_ExperimentalGcdDivisions_min => 0;
  use constant _NumSeq_Coord_ExperimentalGcdDivisions_max => undef;
  use constant _NumSeq_Coord_ExperimentalGcdDivisions_integer => 1;

  #-------------

  use constant _NumSeq_Coord_ExperimentalKroneckerSymbol_min => -1;
  use constant _NumSeq_Coord_ExperimentalKroneckerSymbol_max => 1;
  use constant _NumSeq_Coord_ExperimentalKroneckerSymbol_integer => 1;

  sub _NumSeq_Coord_BitAnd_min {
    my ($self) = @_;
    # if one of X,Y always >=0 then BitAnd >= 0
    my $max_min = $self->_NumSeq_Coord_Max_min;
    if (defined $max_min && $max_min >= 0) {
      return 0;
    }
    return undef;
  }
  sub _NumSeq_Coord_BitOr_min {
    my ($self) = @_;
    my $x_minimum = $self->x_minimum;
    my $y_minimum = $self->y_minimum;
    if (defined $x_minimum && defined $y_minimum) {
      return ($x_minimum > 0
              ? ($y_minimum > 0
                 ? List::Util::min($x_minimum, $y_minimum)     # +X,+Y
                 : $x_minimum)                                 # +X,-Y
              : ($y_minimum > 0
                 ? $y_minimum                                  # -X,+Y
                 : List::Util::min($x_minimum, $y_minimum)));  # -X,-Y

    } else {
      return undef;
    }
  }
  sub _NumSeq_Coord_BitXor_min {
    my ($self) = @_;
    my $x_minimum = $self->x_minimum;
    my $y_minimum = $self->y_minimum;
    if ($self->x_negative || $self->y_negative) {
      return undef;
    } else {
      return 0;  # no negatives
    }
  }

  #-------------
  # Min

  # Return the minimum value taken by min(X,Y) at integer N.
  # This is simply the smaller of x_minimum() or y_minimum().
  # If either X or Y is unbounded below then min(X,Y) is unbounded below too
  # and minxy_minimum() returns undef.
  #
  sub _NumSeq_Coord_Min_min {
    my ($self) = @_;
    # min(X,Y) has a minimum iff both X and Y have a minimum.
    if (defined (my $x_minimum = $self->x_minimum)
        && defined (my $y_minimum = $self->y_minimum)) {
      return Math::NumSeq::PlanePathCoord::min($x_minimum, $y_minimum);
    }
    return undef;
  }
  sub _NumSeq_Coord_Min_max {
    my ($self) = @_;
    # If there's a maximum X or Y then that will be the maximum for Min.
    # If there's both maximum X and Y then the bigger of the two.
    my $x_maximum = $self->x_maximum;
    my $y_maximum = $self->y_maximum;
    if (defined $x_maximum || defined $y_maximum) {
      return Math::NumSeq::PlanePathCoord::max
        (defined $x_maximum ? $x_maximum : (),
         defined $y_maximum ? $y_maximum : ());
    }
    return undef;
  }

  #-------------
  # Max

  sub _NumSeq_Coord_Max_min {
    my ($self) = @_;
    my $x_minimum = $self->x_minimum;
    my $y_minimum = $self->y_minimum;
    # or empty max is undef if neither minimum
    return Math::NumSeq::PlanePathCoord::max
      (defined $x_minimum ? $x_minimum : (),
       defined $y_minimum ? $y_minimum : ());
  }
  # Return the maximum value taken by max(X,Y) at integer N.
  # This is simply the smaller of x_maximum() or y_maximum().
  # If either X or Y is unbounded above then max(X,Y) is unbounded above too
  # and maxxy_maximum() returns undef.
  #
  sub _NumSeq_Coord_Max_max {
    my ($self) = @_;
    if (defined (my $x_maximum = $self->x_maximum)
        && defined (my $y_maximum = $self->y_maximum)) {
      return Math::NumSeq::PlanePathCoord::max($x_maximum, $y_maximum);
    }
    return undef;
  }
  *_NumSeq_Coord_Min_integer    = \&_NumSeq_Coord_Sum_integer;
  *_NumSeq_Coord_Max_integer    = \&_NumSeq_Coord_Sum_integer;

  sub _NumSeq_Coord_Max_is_always_X {
    my ($path) = @_;
    # if X-Y>=0 then X>=Y and max(X,Y)=X
    my $diffxy_minimum = $path->diffxy_minimum;
    return (defined $diffxy_minimum && $diffxy_minimum >= 0);
  }
  sub _NumSeq_Coord_Max_is_always_Y {
    my ($path) = @_;
    # if X-Y<=0 then X<=Y and max(X,Y)=Y
    my $diffxy_maximum = $path->diffxy_maximum;
    return (defined $diffxy_maximum && $diffxy_maximum <= 0);
  }
  sub _NumSeq_Coord_Max_increasing {
    my ($path) = @_;
    if ($path->_NumSeq_Coord_Max_is_always_X) {
      return $path->_NumSeq_Coord_X_increasing;
    }
    if ($path->_NumSeq_Coord_Max_is_always_Y) {
      return $path->_NumSeq_Coord_Y_increasing;
    }
    return undef;
  }
  sub _NumSeq_Coord_Max_non_decreasing {
    my ($path) = @_;
    if ($path->_NumSeq_Coord_Max_is_always_X) {
      return $path->_NumSeq_Coord_X_non_decreasing;
    }
    if ($path->_NumSeq_Coord_Max_is_always_Y) {
      return $path->_NumSeq_Coord_Y_non_decreasing;
    }
    return undef;
  }

  #------------
  # ExperimentalHammingDist

  use constant _NumSeq_Coord_ExperimentalHammingDist_min => 0;
  use constant _NumSeq_Coord_ExperimentalHammingDist_integer => 1;
  # sub _NumSeq_Coord_ExperimentalHammingDist_min {
  #   my ($self) = @_;
  #   return ($self->x_negative || $self->y_negative ? undef : 0);
  # }

  #-------------
  # MinAbs

  sub _NumSeq_Coord_MinAbs_min {
    my ($self) = @_;
    return Math::NumSeq::PlanePathCoord::min
      ($self->_NumSeq_Coord_ExperimentalAbsX_min,
       $self->_NumSeq_Coord_ExperimentalAbsY_min);
  }
  sub _NumSeq_Coord_MinAbs_max {
    my ($self) = @_;
    my $absx_maximum = $self->_NumSeq_Coord_ExperimentalAbsX_max;
    my $absy_maximum = $self->_NumSeq_Coord_ExperimentalAbsY_max;
    # smaller of the two maxima, or undef if neither bounded
    return Math::NumSeq::PlanePathCoord::min
      ((defined $absx_maximum ? $absx_maximum : ()),
       (defined $absy_maximum ? $absy_maximum : ()));
  }
  *_NumSeq_Coord_MinAbs_integer = \&_NumSeq_Coord_Sum_integer;

  sub _NumSeq_Coord_MaxAbs_non_decreasing {
    my ($path) = @_;
    if (! $path->x_negative && ! $path->y_negative) {
      # X>0 and Y>0 so MaxAbs==Max
      return $path->_NumSeq_Coord_Max_non_decreasing;
    }
    return undef;
  }
  sub _NumSeq_Coord_MaxAbs_increasing {
    my ($path) = @_;
    if (! $path->x_negative && ! $path->y_negative) {
      # X>0 and Y>0 so MaxAbs==Max
      return $path->_NumSeq_Coord_Max_increasing;
    }
    return undef;
  }

  #-------------
  # MaxAbs

  sub _NumSeq_Coord_MaxAbs_min {
    my ($self) = @_;
    return Math::NumSeq::PlanePathCoord::max
      ($self->_NumSeq_Coord_ExperimentalAbsX_min,
       $self->_NumSeq_Coord_ExperimentalAbsY_min);
  }
  sub _NumSeq_Coord_MaxAbs_max {
    my ($self) = @_;
    if (defined (my $x_minimum = $self->x_minimum)
        && defined (my $y_minimum = $self->y_minimum)
        && defined (my $x_maximum = $self->x_maximum)
        && defined (my $y_maximum = $self->y_maximum)) {
      return Math::NumSeq::PlanePathCoord::max
        (-$x_minimum, -$y_minimum, $x_maximum, $y_maximum);
    }
    return undef;
  }
  *_NumSeq_Coord_MaxAbs_integer = \&_NumSeq_Coord_Sum_integer;

  #-------------
  # ExperimentalAbsX

  sub _NumSeq_Coord_ExperimentalAbsX_min {
    my ($self) = @_;
    # if positive min or negative max then 0 is not crossed and have an ExperimentalAbsX
    # min which is bigger than 0
    { my $x_minimum = $self->x_minimum;
      if (defined $x_minimum && $x_minimum > 0) { return $x_minimum; }
    }
    { my $x_maximum = $self->x_maximum;
      if (defined $x_maximum && $x_maximum < 0) { return - $x_maximum; }
    }
    return 0;
  }
  sub _NumSeq_Coord_ExperimentalAbsX_max {
    my ($self) = @_;
    # if bounded above and below then have an ExperimentalAbsX
    if (defined (my $x_minimum = $self->x_minimum)) {
      if (defined (my $x_maximum = $self->x_maximum)) {
        return Math::NumSeq::PlanePathCoord::max
          (abs($x_minimum), abs($x_maximum));
      }
    }
    return undef;
  }

  #-------------
  # ExperimentalAbsY

  sub _NumSeq_Coord_ExperimentalAbsY_min {
    my ($self) = @_;
    # if positive min or negative max then 0 is not crossed and have an ExperimentalAbsY
    # min which is bigger than 0
    { my $y_minimum = $self->y_minimum;
      if (defined $y_minimum && $y_minimum > 0) { return $y_minimum; }
    }
    { my $y_maximum = $self->y_maximum;
      if (defined $y_maximum && $y_maximum < 0) { return - $y_maximum; }
    }
    return 0;
  }
  sub _NumSeq_Coord_ExperimentalAbsY_max {
    my ($self) = @_;
    # if bounded above and below then have an ExperimentalAbsY
    if (defined (my $y_minimum = $self->y_minimum)) {
      if (defined (my $y_maximum = $self->y_maximum)) {
        return Math::NumSeq::PlanePathCoord::max
          (abs($y_minimum), abs($y_maximum));
      }
    }
    return undef;
  }

  #-------------

  sub _NumSeq_Coord_pred_X {
    my ($path, $value) = @_;
    return (($path->figure ne 'square' || $value == int($value))
            && ($path->x_negative || $value >= 0));
  }
  sub _NumSeq_Coord_pred_Y {
    my ($path, $value) = @_;
    return (($path->figure ne 'square' || $value == int($value))
            && ($path->y_negative || $value >= 0));
  }
  sub _NumSeq_Coord_pred_Sum {
    my ($path, $value) = @_;
    return (($path->figure ne 'square' || $value == int($value))
            && ($path->x_negative || $path->y_negative || $value >= 0));
  }
  sub _NumSeq_Coord_pred_SumAbs {
    my ($path, $value) = @_;
    return (($path->figure ne 'square' || $value == int($value))
            && $value >= 0);
  }

  #--------------------------
  sub _NumSeq_Coord_pred_Radius {
    my ($path, $value) = @_;
    return $path->_NumSeq_Coord_pred_RSquared($value*$value);
  }
  sub _NumSeq_Coord_pred_RSquared {
    my ($path, $value) = @_;
    # FIXME: this should be whether x^2+y^2 ever occurs, which is no prime
    # factor 4k+3 or some such
    return (($path->figure ne 'square' || $value == int($value))
            && $value >= 0);
  }

  #--------------------------
  sub _NumSeq_Coord_pred_TRadius {
    my ($path, $value) = @_;
    return $path->_NumSeq_Coord_pred_RSquared($value*$value);
  }
  sub _NumSeq_Coord_pred_TRSquared {
    my ($path, $value) = @_;
    # FIXME: this should be whether x^2+3*y^2 occurs ...
    return (($path->figure ne 'square' || $value == int($value))
            && $value >= 0);
  }

  #--------------------------
  use constant _NumSeq_Coord_Depth_min => 0;
  sub _NumSeq_Coord_Depth_max {
    my ($path, $value) = @_;
    return ($path->tree_n_num_children($path->n_start)
            ? undef  # is a tree, default infinite max depth
            : 0);    # not a tree, depth always 0
  }
  use constant _NumSeq_Coord_Depth_integer => 1;
  use constant _NumSeq_Coord_Depth_non_decreasing => 1; # usually

  #--------------------------
  use constant _NumSeq_Coord_NumChildren_integer => 1;

  # compare with "==" to be numeric style, just in case some overloaded
  # class stringizes to "1.0" or some such nonsense
  sub _NumSeq_Coord_pred_NumChildren {
    my ($self, $value) = @_;
    foreach my $num ($self->tree_num_children_list) {
      if ($value == $num) { return 1; }
    }
    return 0;
  }

  #--------------------------
  use constant _NumSeq_Coord_NumSiblings_min => 0; # root node no siblings
  sub _NumSeq_Coord_NumSiblings_max {
    my ($path) = @_;
    return List::Util::max(0,
                           # not including self
                           $path->tree_num_children_maximum - 1);
  }
  use constant _NumSeq_Coord_NumSiblings_integer => 1;
  # if NumChildren=const except for NumChildren=0 then have NumSiblings=const-1
  # so NumSiblings=0 at the root and thereafter non-decreasing
  sub _NumSeq_Coord_NumSiblings_non_decreasing {
    my ($path) = @_;
    my @num_children = $path->tree_num_children_list;
    if ($num_children[0] == 0) { shift @num_children; }
    return (scalar(@num_children) <= 1);
  }

  #--------------------------
  use constant _NumSeq_Coord_ExperimentalLeafDistance_integer => 1;
  use constant _NumSeq_Coord_ExperimentalLeafDistance_min => 0;
  use constant _NumSeq_Coord_ExperimentalLeafDistance_max => 0;

  #--------------------------
  sub _NumSeq_Coord_SubHeight_min {
    my ($path) = @_;
    if ($path->tree_any_leaf) {
      return 0;  # height 0 at a leaf
    } else {
      return undef;  # actually +infinity
    }
  }
  sub _NumSeq_Coord_SubHeight_max {
    my ($path) = @_;
    return ($path->tree_n_num_children($path->n_start)
            ? undef  # is a tree, default infinite max height
            : 0);    # not a tree, height always 0
  }
  use constant _NumSeq_Coord_SubHeight_integer => 1;

  #--------------------------
  sub _NumSeq_Coord_RootN_min {
    my ($path) = @_;
    return $path->n_start;
  }
  sub _NumSeq_Coord_RootN_max {
    my ($path) = @_;
    return $path->n_start
      + List::Util::max(0, $path->tree_num_roots()-1);
  }
  use constant _NumSeq_Coord_RootN_integer => 1;

  #--------------------------
  sub _NumSeq_Coord_IsLeaf_min {
    my ($path) = @_;
    # if num_children>0 occurs then that's a non-leaf node so IsLeaf=0 occurs
    return ($path->tree_num_children_maximum() > 0 ? 0 : 1);
  }
  sub _NumSeq_Coord_IsLeaf_max {
    my ($path) = @_;
    return ($path->tree_any_leaf() ? 1 : 0);
  }
  # IsNonLeaf is opposite of IsLeaf
  sub _NumSeq_Coord_IsNonLeaf_min {
    my ($path) = @_;
    return $path->_NumSeq_Coord_IsLeaf_max ? 0 : 1;
  }
  sub _NumSeq_Coord_IsNonLeaf_max {
    my ($path) = @_;
    return $path->_NumSeq_Coord_IsLeaf_min ? 0 : 1;
  }
  use constant _NumSeq_Coord_IsLeaf_integer => 1;
  use constant _NumSeq_Coord_IsNonLeaf_integer => 1;

  #--------------------------
  use constant _NumSeq_Coord_ExperimentalRowOffset_min => 0;

  #--------------------------
  use constant _NumSeq_Coord_n_list_max => 1;

  use constant _NumSeq_Coord_ExperimentalVisitCount_min => 1;
  sub _NumSeq_Coord_ExperimentalVisitCount_max {
    my ($path) = @_;
    return $path->_NumSeq_Coord_n_list_max;
  }
  use constant _NumSeq_Coord_ExperimentalVisitNum_min => 1;
  *_NumSeq_Coord_ExperimentalVisitNum_max
    = \&_NumSeq_Coord_ExperimentalVisitCount_max;

  use constant _NumSeq_Coord_ExperimentalRevisit_min => 0;
  sub _NumSeq_Coord_ExperimentalRevisit_max {
    my ($path) = @_;
    return $path->_NumSeq_Coord_n_list_max - 1;
  }
}

{ package Math::PlanePath::SquareSpiral;
  use constant _NumSeq_Coord_filling_type => 'plane';
  sub _NumSeq_Coord_MaxAbs_non_decreasing {
    my ($self) = @_;
    return ($self->{'wider'} == 0);
  }
  use constant _NumSeq_Coord_oeis_anum =>
    { 'wider=0,n_start=1' =>
      { X       => 'A174344',
        SumAbs  => 'A214526', # "Manhattan" distance from n to 1
        # OEIS-Catalogue: A174344 planepath=SquareSpiral coordinate_type=X
        # OEIS-Catalogue: A214526 planepath=SquareSpiral coordinate_type=SumAbs
      },
      'wider=0,n_start=0' =>
      { Sum     => 'A180714', # X+Y of square spiral
        AbsDiff => 'A053615', # n..0..n, distance to pronic
        # OEIS-Catalogue: A180714 planepath=SquareSpiral,n_start=0 coordinate_type=Sum
        # OEIS-Other:     A053615 planepath=SquareSpiral,n_start=0 coordinate_type=AbsDiff
      },
    };
}
{ package Math::PlanePath::GreekKeySpiral;
  use constant _NumSeq_Coord_filling_type => 'plane';
  sub _NumSeq_Coord_MaxAbs_non_decreasing {
    my ($self) = @_;
    return ($self->{'turns'} == 0);  # when same as SquareSpiral
  }
}
{ package Math::PlanePath::PyramidSpiral;
  use constant _NumSeq_Coord_filling_type => 'plane';
  use constant _NumSeq_Coord_oeis_anum =>
    { 'n_start=0' =>
      { ExperimentalAbsX => 'A053615', # runs n..0..n, OFFSET=0
        # OEIS-Catalogue: A053615 planepath=PyramidSpiral,n_start=0 coordinate_type=ExperimentalAbsX
      },
    };
}
{ package Math::PlanePath::TriangleSpiral;
  use constant _NumSeq_Coord_filling_type => 'triangular';
  use constant _NumSeq_Coord_ExperimentalParity_max => 0;  # even always
}
{ package Math::PlanePath::TriangleSpiralSkewed;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::DiamondSpiral;
  use constant _NumSeq_Coord_filling_type => 'plane';
  use constant _NumSeq_Coord_SumAbs_non_decreasing => 1; # diagonals pos,neg
  use constant _NumSeq_Coord_oeis_anum =>
    { 'n_start=0' =>
      { X => 'A010751', # up 1, down 2, up 3, down 4, etc
        ExperimentalAbsY => 'A053616',
        # OEIS-Catalogue: A010751 planepath=DiamondSpiral,n_start=0
        # OEIS-Other:     A053616 planepath=DiamondSpiral,n_start=0 coordinate_type=ExperimentalAbsY
      },
    };
}
{ package Math::PlanePath::AztecDiamondRings;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::PentSpiralSkewed;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::HexSpiral;
  use constant _NumSeq_Coord_filling_type => 'triangular';
  # origin 0,0 if wider even, otherwise only X=1,Y=0 if wider odd
  sub _NumSeq_Coord_TRSquared_min { $_[0]->rsquared_minimum }

  # always odd/even according to wider odd/even
  sub _NumSeq_Coord_ExperimentalParity_min {
    my ($self) = @_;
    return $self->{'wider'} & 1;
  }
  *_NumSeq_Coord_ExperimentalParity_max = \&_NumSeq_Coord_ExperimentalParity_min;

  # X!=Y when wider odd
  *_NumSeq_Coord_ExperimentalHammingDist_min = \&_NumSeq_Coord_ExperimentalParity_min;
  *_NumSeq_Coord_MaxAbs_min = \&_NumSeq_Coord_ExperimentalParity_min;
}
{ package Math::PlanePath::HexSpiralSkewed;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::HexArms;
  use constant _NumSeq_Coord_filling_type => 'triangular';
  use constant _NumSeq_Coord_ExperimentalParity_max => 0;  # even always
}
{ package Math::PlanePath::HeptSpiralSkewed;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::AnvilSpiral;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::OctagramSpiral;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::KnightSpiral;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::CretanLabyrinth;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::SquareArms;
  use constant _NumSeq_Coord_filling_type => 'plane';
  use constant _NumSeq_Coord_MaxAbs_non_decreasing => 1; # successive squares
}
{ package Math::PlanePath::DiamondArms;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::SacksSpiral;
  use constant _NumSeq_Coord_X_integer => 0;
  use constant _NumSeq_Coord_Y_integer => 0;
  use constant _NumSeq_Coord_Radius_increasing => 1; # Radius==sqrt($i)
  use constant _NumSeq_Coord_RSquared_smaller => 0;  # RSquared==$i
  use constant _NumSeq_Coord_RSquared_integer => 1;

  use constant _NumSeq_Coord_oeis_anum =>
    { '' =>
      { RSquared => 'A001477',  # integers 0,1,2,3,etc
        # OEIS-Other: A001477 planepath=SacksSpiral coordinate_type=RSquared
      },
    };
}
{ package Math::PlanePath::VogelFloret;
  use constant _NumSeq_Coord_X_integer => 0;
  use constant _NumSeq_Coord_Y_integer => 0;
  use constant _NumSeq_AbsDiff_min_is_infimum => 1;
  use constant _NumSeq_MinAbs_min_is_infimum => 1;
  use constant _NumSeq_MaxAbs_min_is_infimum => 1;

  sub _NumSeq_Coord_Radius_min {
    my ($self) = @_;
    # starting N=1 at R=radius_factor*sqrt(1), theta=something
    return $self->{'radius_factor'};
  }
  sub _NumSeq_Coord_TRSquared_min {
    my ($self) = @_;
    # starting N=1 at R=radius_factor*sqrt(1), theta=something
    my ($x,$y) = $self->n_to_xy($self->n_start);
    return $x*$x + 3*$y*$y;
  }
  sub _NumSeq_Coord_Radius_func {
    my ($seq, $i) = @_;
    ### VogelFloret Radius: $i, $seq->{'planepath_object'}
    # R=radius_factor*sqrt($n)
    # avoid sin/cos in the main n_to_xy()

    my $path = $seq->{'planepath_object'};
    my $rf = $path->{'radius_factor'};

    # promote BigInt $i -> BigFloat so that sqrt() doesn't round, and in
    # case radius_factor is not an integer
    if (ref $i && $i->isa('Math::BigInt') && $rf != int($rf)) {
      require Math::BigFloat;
      $i = Math::BigFloat->new($i);
    }

    return sqrt($i) * $rf;
  }
  use constant _NumSeq_Coord_Radius_increasing => 1; # Radius==sqrt($i)
  use constant _NumSeq_Coord_RSquared_smaller => 0;  # RSquared==$i
}
{ package Math::PlanePath::TheodorusSpiral;
  use constant _NumSeq_Coord_X_integer => 0;
  use constant _NumSeq_Coord_Y_integer => 0;
  use constant _NumSeq_Coord_Radius_increasing => 1; # Radius==sqrt($i)
  use constant _NumSeq_Coord_RSquared_smaller => 0;  # RSquared==$i
  use constant _NumSeq_Coord_RSquared_integer => 1;

  use constant _NumSeq_Coord_oeis_anum =>
    { '' =>
      { RSquared => 'A001477',  # integers 0,1,2,3,etc
        # OEIS-Other: A001477 planepath=TheodorusSpiral coordinate_type=RSquared
      },
    };
}
{ package Math::PlanePath::ArchimedeanChords;
  use constant _NumSeq_Coord_X_integer => 0;
  use constant _NumSeq_Coord_Y_integer => 0;
  use constant _NumSeq_Coord_Radius_increasing => 1; # spiralling outwards
}
{ package Math::PlanePath::MultipleRings;

  #---------
  # X
  sub _NumSeq_Coord_X_increasing {
    my ($self) = @_;
    # step==0 trivial on X axis
    return ($self->{'step'} == 0 ? 1 : 0);
  }
  sub _NumSeq_Coord_X_integer {
    my ($self) = @_;
    return ($self->{'step'} == 0);  # step==0 trivial on X axis
  }

  #---------
  # Y
  *_NumSeq_Coord_Y_integer              = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_Y_non_decreasing       = \&_NumSeq_Coord_X_increasing;

  *_NumSeq_Coord_Sum_increasing         = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_DiffXY_increasing      = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_DiffXYdiv2_increasing  = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_TRSquared_integer      = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_Product_non_decreasing = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_Product_integer        = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_BitAnd_non_decreasing  = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_BitOr_increasing       = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_BitXor_increasing      = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_Min_non_decreasing     = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_Max_increasing         = \&_NumSeq_Coord_X_increasing;

  #---------
  # SumAbs
  sub _NumSeq_Coord_SumAbs_non_decreasing {
    my ($self) = @_;
    # step==0 trivial on X axis
    # polygon step=4 same x+y in ring, others vary
    return ($self->{'step'} == 0
            || ($self->{'ring_shape'} eq 'polygon' && $self->{'step'} == 4)
            ? 1
            : 0);
  }
  *_NumSeq_Coord_SumAbs_increasing      = \&_NumSeq_Coord_X_increasing;

  #---------
  # Product
  sub _NumSeq_Coord_Product_max {
    my ($self) = @_;
    # step==0 trivial on X axis
    # polygon step=4 same x+y in ring, others vary
    return ($self->{'step'} == 0 ? 0   # step=0 always Y=0 so X*Y=0
            : undef);
  }
  *_NumSeq_Coord_BitAnd_max = \&_NumSeq_Coord_Product_max;

  #---------
  *_NumSeq_Coord_AbsDiff_increasing     = \&_NumSeq_Coord_X_increasing;
  sub _NumSeq_AbsDiff_min_is_infimum {
    my ($self) = @_;
    # step multiple of 4 always falls on X=Y, otherwise approaches 0 only
    return ($self->{'ring_shape'} eq 'polygon'
            && $self->{'step'} % 4);
  }

  #---------
  # RSquared
  sub _NumSeq_Coord_RSquared_smaller {
    my ($self) = @_;
    # step==0 on X axis RSquared is i^2, bigger than i.
    # step=1 is 0,1,1,4,4,4,9,9,9,9,16,16,16,16,16 etc k+1 repeats of k^2,
    # bigger than i from i=5 onwards
    return ($self->{'step'} <= 1 ? 0 : 1);
  }
  *_NumSeq_Coord_RSquared_integer = \&_NumSeq_Coord_Radius_integer;
  *_NumSeq_Coord_RSquared_non_decreasing = \&_NumSeq_Coord_Radius_non_decreasing;

  #---------
  # Radius
  sub _NumSeq_Coord_Radius_integer {
    my ($self) = @_;
    # step==0 on X axis R=N
    # step==1 start X=0,Y=0, spaced 1 apart on X axis, same radius for others
    # step==6 start X=1,Y=0, spaced 1 apart
    return ($self->{'step'} <= 1 || $self->{'step'} == 6);
  }
  sub _NumSeq_Coord_Radius_non_decreasing {
    my ($self) = @_;
    # circle is non-decreasing, polygon varies
    return ! ($self->{'ring_shape'} eq 'polygon' && $self->{'step'} >= 3);
  }
  *_NumSeq_Coord_Radius_increasing      = \&_NumSeq_Coord_X_increasing;

  #---------
  # TRadius
  sub _NumSeq_Coord_TRadius_min {
    my ($self) = @_;
    return $self->_NumSeq_Coord_Radius_min;
  }
  sub _NumSeq_Coord_TRSquared_min {
    my ($self) = @_;
    return $self->rsquared_minimum;
  }
  sub _NumSeq_Coord_TRadius_non_decreasing {
    my ($self) = @_;
    # step==0 trivial on X axis
    return ($self->{'step'} == 0 ? 1 : 0);
  }
  *_NumSeq_Coord_TRadius_increasing     = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_TRadius_integer        = \&_NumSeq_Coord_X_increasing;

  #---------
  # GCD
  *_NumSeq_Coord_GCD_integer            = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_GCD_increasing         = \&_NumSeq_Coord_X_increasing;

  #---------
  # IntXY
  # step=0 X/0 so IntXY=X
  *_NumSeq_Coord_IntXY_increasing   = \&_NumSeq_Coord_X_increasing;

  #---------
  # FracXY
  sub _NumSeq_Coord_FracXY_max {
    my ($self) = @_;
    return ($self->{'step'} == 0 ? 0 : 1);
  }
  sub _NumSeq_FracXY_max_is_supremum {
    my ($self) = @_;
    return ($self->{'step'} == 0 ? 0 : 1);
  }
  *_NumSeq_Coord_FracXY_non_decreasing  = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_FracXY_integer         = \&_NumSeq_Coord_X_increasing;

  sub _NumSeq_ExperimentalParity_min_is_infimum {
    my ($self) = @_;
    return $self->{'ring_shape'} eq 'polygon';
  }

  use constant _NumSeq_Coord_oeis_anum =>
    {
     # MultipleRings step=0 is trivial X=N,Y=0
     'step=0,ring_shape=circle' =>
     { Y        => 'A000004',  # all-zeros
       Product  => 'A000004',  # all-zeros
       # OEIS-Other: A000004 planepath=MultipleRings,step=0 coordinate_type=Y
       # OEIS-Other: A000004 planepath=MultipleRings,step=0 coordinate_type=Product

       # OFFSET
       # X        => 'A001477',  # integers 0 upwards
       # Sum      => 'A001477',  # integers 0 upwards
       # AbsDiff  => 'A001477',  # integers 0 upwards
       # Radius   => 'A001477',  # integers 0 upwards
       # DiffXY   => 'A001477',  # integers 0 upwards
       # DiffYX   => 'A001489',  # negative integers 0 downwards
       # RSquared => 'A000290',  # squares 0 upwards
       # # OEIS-Other: A001477 planepath=MultipleRings,step=0 coordinate_type=X
       # # OEIS-Other: A001477 planepath=MultipleRings,step=0 coordinate_type=Sum
       # # OEIS-Other: A001477 planepath=MultipleRings,step=0 coordinate_type=AbsDiff
       # # OEIS-Other: A001477 planepath=MultipleRings,step=0 coordinate_type=Radius
       # # OEIS-Other: A001477 planepath=MultipleRings,step=0 coordinate_type=DiffXY
       # # OEIS-Other: A001489 planepath=MultipleRings,step=0 coordinate_type=DiffYX
       # # OEIS-Other: A000290 planepath=MultipleRings,step=0 coordinate_type=RSquared
     },
    };
}
# { package Math::PlanePath::PixelRings;
# }
{ package Math::PlanePath::FilledRings;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::Hypot;
  use constant _NumSeq_Coord_filling_type => 'plane';
  sub _NumSeq_Coord_TRSquared_min { $_[0]->rsquared_minimum }

  # in order of radius so monotonic, but always have 4x duplicates or more
  use constant _NumSeq_Coord_Radius_non_decreasing => 1;

  sub _NumSeq_Coord_ExperimentalHammingDist_min {
    my ($self) = @_;
    return ($self->{'points'} eq 'odd' ? 1 : 0);
  }
  *_NumSeq_Coord_ExperimentalParity_min = \&_NumSeq_Coord_ExperimentalHammingDist_min;
  *_NumSeq_Coord_MaxAbs_min = \&_NumSeq_Coord_ExperimentalHammingDist_min;

  sub _NumSeq_Coord_ExperimentalParity_max {
    my ($self) = @_;
    return ($self->{'points'} eq 'even' ? 0 : 1);
  }
}
{ package Math::PlanePath::HypotOctant;
  use constant _NumSeq_Coord_IntXY_min => 1;  # triangular X>=Y so X/Y >= 1

  sub _NumSeq_Coord_TRSquared_min { $_[0]->rsquared_minimum }
  sub _NumSeq_Coord_BitXor_min {
    my ($self) = @_;
    # "odd" always has X!=Ymod2 so differ in low bit
    return ($self->{'points'} eq 'odd' ? 1 : 0);
  }

  # in order of radius so monotonic, but can have duplicates
  use constant _NumSeq_Coord_Radius_non_decreasing => 1;

  sub _NumSeq_Coord_ExperimentalHammingDist_min {
    my ($self) = @_;
    return ($self->{'points'} eq 'odd' ? 1 : 0);
  }

  sub _NumSeq_Coord_ExperimentalParity_min {
    my ($self) = @_;
    return ($self->{'points'} eq 'odd' ? 1 : 0);
  }
  sub _NumSeq_Coord_ExperimentalParity_max {
    my ($self) = @_;
    return ($self->{'points'} eq 'even' ? 0 : 1);
  }
}
{ package Math::PlanePath::TriangularHypot;
  use constant _NumSeq_Coord_filling_type => 'triangular';
  sub _NumSeq_Coord_TRSquared_min {
    my ($self) = @_;
    return ($self->{'points'} eq 'odd'
            ? 1     # odd at X=1,Y=0
            : $self->{'points'} eq 'hex_centred'
            ? 4     # hex_centred at X=2,Y=0 or X=1,Y=1
            : 0);   # even,all at X=0,Y=0
  }

  # in order of triangular radius so monotonic, but can have duplicates so
  # non-decreasing
  use constant _NumSeq_Coord_TRadius_non_decreasing => 1;

  sub _NumSeq_Coord_ExperimentalHammingDist_min {
    my ($self) = @_;
    return ($self->{'points'} eq 'odd' ? 1 : 0);      # X!=Y when odd
  }
  *_NumSeq_Coord_ExperimentalParity_min = \&_NumSeq_Coord_ExperimentalHammingDist_min;
  sub _NumSeq_Coord_MaxAbs_min {
    my ($self) = @_;
    return ($self->{'points'} eq 'odd' || $self->{'points'} eq 'hex_centred'
            ? 1 : 0);
  }

  sub _NumSeq_Coord_ExperimentalParity_max {
    my ($self) = @_;
    return ($self->{'points'} eq 'odd' || $self->{'points'} eq 'all' ? 1 : 0);
  }
}
{ package Math::PlanePath::PythagoreanTree;
  use constant _NumSeq_Coord_SubHeight_min => undef;
  use constant _NumSeq_Coord_ExperimentalLeafDistance_max => undef;

  {
    my %_NumSeq_Coord_IntXY_min = (AB => 0, # A>=1,B>=1 so int(A/B)>=0
                                   AC => 0, # A<C so int(A/C)==0 always
                                   BC => 0, # B<C so int(A/C)==0 always
                                   PQ => 1, # octant X>=Y+1 so X/Y>1
                                   SM => 0, # A>=1,B>=1 so int(A/B)>=0
                                   SC => 0,
                                   MC => 0,
                                  );
    sub _NumSeq_Coord_IntXY_min {
      my ($self) = @_;
      return $_NumSeq_Coord_IntXY_min{$self->{'coordinates'}};
    }
  }
  {
    my %_NumSeq_Coord_IntXY_max = (AC => 0, # A<C so int(A/C)==0 always
                                   BC => 0, # B<C so int(A/C)==0 always
                                   SM => 0, # X<Y so int(X/Y)<1
                                   SC => 0, # X<Y so int(X/Y)<1
                                   MC => 0, # X<Y so int(X/Y)<1
                                  );
    sub _NumSeq_Coord_IntXY_max {
      my ($self) = @_;
      return $_NumSeq_Coord_IntXY_max{$self->{'coordinates'}};
    }
  }

  # P=2,Q=1 frac=0
  # otherwise A,B,C have no common factor and >1 so frac!=0
  sub _NumSeq_FracXY_min_is_infimum {
    my ($self) = @_;
    return $self->{'coordinates'} ne 'PQ';
  }

  {
    my %_NumSeq_Coord_ExperimentalDenominator_min = (AB => 4, # at A=3,B=4 no common factor
                                         AC => 5, # at A=3,B=5
                                         BC => 5, # at B=4,B=5
                                         PQ => 1, # at P=2,Q=1
                                        );
    sub _NumSeq_Coord_ExperimentalDenominator_min {
      my ($self) = @_;
      return $_NumSeq_Coord_ExperimentalDenominator_min{$self->{'coordinates'}};
    }
  }

  {
    my %_NumSeq_Coord_BitAnd_min = (AB => 0,  # at X=3,Y=4
                                    AC => 1,  # at X=3,Y=5
                                    BC => 0,  # at X=8,Y=17
                                    PQ => 0,  # at X=2,Y=1
                                    SM => 0,  # at X=3,Y=4
                                    SC => 0,  # at X=3,Y=5
                                    MC => 0,  # at X=4,Y=5
                                   );
    sub _NumSeq_Coord_BitAnd_min {
      my ($self) = @_;
      return $_NumSeq_Coord_BitAnd_min{$self->{'coordinates'}};
    }
  }
  {
    my %_NumSeq_Coord_BitOr_min = (AB => 7,  # at A=3,B=4
                                   AC => 7,  # at A=3,C=5
                                   BC => 5,  # at B=4,C=5
                                   PQ => 3,  # at P=2,Q=1
                                   SM => 7,  # at X=3,Y=4
                                   SC => 7,  # at X=3,Y=5
                                   MC => 5,  # at X=4,Y=5
                                  );
    sub _NumSeq_Coord_BitOr_min {
      my ($self) = @_;
      return $_NumSeq_Coord_BitOr_min{$self->{'coordinates'}};
    }
  }
  {
    my %_NumSeq_Coord_BitXor_min = (AB => 1, # at X=21,Y=20
                                    AC => 6, # at X=3,Y=5
                                    BC => 1, # at X=4,Y=5
                                    PQ => 1, # at X=3,Y=2
                                    SM => 1, # at X=3,Y=4
                                    SC => 6,  # at X=3,Y=5
                                    MC => 1,  # at X=4,Y=5
                                );
    sub _NumSeq_Coord_BitXor_min {
      my ($self) = @_;
      return $_NumSeq_Coord_BitXor_min{$self->{'coordinates'}};
    }
  }

  sub _NumSeq_Coord_Radius_integer {
    my ($self) = @_;
    return ($self->{'coordinates'} eq 'AB'     # hypot
           || $self->{'coordinates'} eq 'SM'); # hypot
  }

  use constant _NumSeq_Coord_ExperimentalHammingDist_min => 1; # X!=Y

  {
    my %_NumSeq_Coord_ExperimentalParity_min = (PQ => 1, # one odd one even, so odd always
                                    AB => 1, # odd,even so odd always
                                    BA => 1,
                                    BC => 1, # even,odd so odd always
                                   );
    sub _NumSeq_Coord_ExperimentalParity_min {
      my ($self) = @_;
      return $_NumSeq_Coord_ExperimentalParity_min{$self->{'coordinates'}} || 0;
    }
  }
  sub _NumSeq_Coord_ExperimentalParity_max {
    my ($self) = @_;
    return ($self->{'coordinates'} eq 'AC'
            ? 0   # odd,odd so even always
            : 1);
  }

  # Not quite right.
  # sub _NumSeq_Coord_pred_Radius {
  #   my ($path, $value) = @_;
  #   return ($value >= 0
  #           && ($path->{'coordinate_type'} ne 'AB'
  #               || $value == int($value)));
  # }
}
{ package Math::PlanePath::RationalsTree;
  use constant _NumSeq_Coord_BitAnd_min => 0;  # X=1,Y=2
  use constant _NumSeq_Coord_BitXor_min => 0;  # X=1,Y=1
  use constant _NumSeq_Coord_SubHeight_min => undef;
  use constant _NumSeq_Coord_ExperimentalLeafDistance_max => undef;

  use constant _NumSeq_Coord_oeis_anum =>
    { 'tree_type=SB' =>
      { IntXY => 'A153036',
        Depth => 'A000523', # floor(log2(n)) starting OFFSET=1
        # OEIS-Catalogue: A153036 planepath=RationalsTree coordinate_type=IntXY
        # OEIS-Catalogue: A000523 planepath=RationalsTree coordinate_type=Depth

        # Not quite, OFFSET n=0 cf N=1 here
        # Y => 'A047679', # SB denominator
        # # OEIS-Catalogue: A047679 planepath=RationalsTree coordinate_type=Y
        #
        # X => 'A007305',   # SB numerators but starting extra 0,1
        # Sum => 'A007306', # Farey/SB denominators, but starting extra 1,1
        # Product => 'A119272', # num*den, but starting extra 1,1
        # cf A054424 permutation
      },
      'tree_type=CW' =>
      {
       # A070871 Stern adjacent S(n)*S(n+1), or Conway's alimentary function,
       # cf A070872 where S(n)*S(n+1) = n
       #    A070873 where S(n)*S(n+1) > n
       #    A070874 where S(n)*S(n+1) < n
       Product => 'A070871',
       Depth   => 'A000523', # floor(log2(n)) starting OFFSET=1
       # OEIS-Catalogue: A070871 planepath=RationalsTree,tree_type=CW coordinate_type=Product
       # OEIS-Other:     A000523 planepath=RationalsTree,tree_type=CW coordinate_type=Depth

       # Not quite, A007814 has extra initial 0, OFFSET=0 "0,1,0,2,0"
       # whereas path CW IntXY starts N=1 "1,0,2,0,1"
       # IntXY   => 'A007814', # countlow1bits(N)
       # # OEIS-Other:     A007814 planepath=RationalsTree,tree_type=CW coordinate_type=IntXY

       # Not quite, CW X and Y is Stern diatomic A002487, but RationalsTree
       # starts N=0 X=1,1,2 or Y=1,2 rather than from 0

       # Not quite, CW DiffYX is A070990 stern diatomic first diffs, but
       # path starts N=1 diff="0,1,-1,2,-1,1,-2", whereas A070990 starts n=0
       # "1,-1,2,-1,1,-2" one less term and would be n_start=-1
      },
      'tree_type=AYT' =>
      { X      => 'A020650', # AYT numerator
        Y      => 'A020651', # AYT denominator
        Sum    => 'A086592', # Kepler's tree denominators
        SumAbs => 'A086592', # Kepler's tree denominators
        Depth  => 'A000523', # floor(log2(n)) starting OFFSET=1
        IntXY  => 'A135523',
        # OEIS-Catalogue: A020650 planepath=RationalsTree,tree_type=AYT coordinate_type=X
        # OEIS-Catalogue: A020651 planepath=RationalsTree,tree_type=AYT coordinate_type=Y
        # OEIS-Other:     A086592 planepath=RationalsTree,tree_type=AYT coordinate_type=Sum
        # OEIS-Other:     A000523 planepath=RationalsTree,tree_type=AYT coordinate_type=Depth
        # OEIS-Catalogue: A135523 planepath=RationalsTree,tree_type=AYT coordinate_type=IntXY

        # Not quite, DiffYX almost A070990 Stern diatomic first differences,
        # but we have an extra 0 at the start, and we start i=1 rather than
        # n=0 too
      },
      'tree_type=HCS' =>
      {
       Depth  => 'A000523', # floor(log2(n)) starting OFFSET=1
       # OEIS-Other: A000523 planepath=RationalsTree,tree_type=HCS coordinate_type=Depth

       # # Not quite, OFFSET=0 value=1/1 corresponding to N=0 X=0/Y=1 here
       # Sum    => 'A071585', # rats>=1 is HCS num+den
       # Y      => 'A071766', # rats>=1 HCS denominator
       # # OEIS-Catalogue: A071585 planepath=RationalsTree,tree_type=HCS coordinate_type=X
       # # OEIS-Catalogue: A071766 planepath=RationalsTree,tree_type=HCS coordinate_type=Y
      },
      'tree_type=Bird' =>
      { X   => 'A162909', # Bird tree numerators
        Y   => 'A162910', # Bird tree denominators
        Depth  => 'A000523', # floor(log2(n)) starting OFFSET=1
        # OEIS-Catalogue: A162909 planepath=RationalsTree,tree_type=Bird coordinate_type=X
        # OEIS-Catalogue: A162910 planepath=RationalsTree,tree_type=Bird coordinate_type=Y
        # OEIS-Other: A000523 planepath=RationalsTree,tree_type=Bird coordinate_type=Depth
      },
      'tree_type=Drib' =>
      { X      => 'A162911', # Drib tree numerators
        Y      => 'A162912', # Drib tree denominators
        Depth  => 'A000523', # floor(log2(n)) starting OFFSET=1
        # OEIS-Catalogue: A162911 planepath=RationalsTree,tree_type=Drib coordinate_type=X
        # OEIS-Catalogue: A162912 planepath=RationalsTree,tree_type=Drib coordinate_type=Y
        # OEIS-Other:     A000523 planepath=RationalsTree,tree_type=Drib coordinate_type=Depth
      },
      'tree_type=L' =>
      {
       X => 'A174981', # numerator
       # OEIS-Catalogue: A174981 planepath=RationalsTree,tree_type=L coordinate_type=X

       # # Not quite, A002487 extra initial, so n=2 is denominator at N=0
       # Y    => 'A002487', # denominator, stern diatomic
       # # OEIS-Catalogue: A071585 planepath=RationalsTree,tree_type=HCS coordinate_type=Y

       # Not quite, A000523 is OFFSET=1 path starts N=0
       # Depth  => 'A000523', # floor(log2(n)) starting OFFSET=1
      },
    };
}
{ package Math::PlanePath::FractionsTree;
  use constant _NumSeq_Coord_IntXY_max => 0;  # X/Y<1 always
  use constant _NumSeq_Coord_IntXY_non_decreasing => 1;
  use constant _NumSeq_FracXY_min_is_infimum => 1; # no common factor
  use constant _NumSeq_Coord_BitXor_min => 1;  # X=2,Y=3
  use constant _NumSeq_Coord_SubHeight_min => undef;
  use constant _NumSeq_Coord_ExperimentalLeafDistance_max => undef;
  use constant _NumSeq_Coord_ExperimentalHammingDist_min => 1; # X!=Y

  use constant _NumSeq_Coord_oeis_anum =>
    { 'tree_type=Kepler' =>
      { X       => 'A020651', # numerators, same as AYT denominators
        Y       => 'A086592', # Kepler half-tree denominators
        DiffYX  => 'A020650', # AYT numerators
        AbsDiff => 'A020650', # AYT numerators
        Depth   => 'A000523', # floor(log2(n)) starting OFFSET=1
        # OEIS-Other:     A020651 planepath=FractionsTree coordinate_type=X
        # OEIS-Catalogue: A086592 planepath=FractionsTree coordinate_type=Y
        # OEIS-Other:     A020650 planepath=FractionsTree coordinate_type=DiffYX
        # OEIS-Other:     A020650 planepath=FractionsTree coordinate_type=AbsDiff
        # OEIS-Other:     A000523 planepath=FractionsTree coordinate_type=Depth

        # Not quite, Sum is from 1/2 value=3 skipping the initial value=2 in
        # A086593 which would be 1/1.  Also is every second denominator, but
        # again no initial value=2.
        # Sum => 'A086593',
        # Y_odd => 'A086593',   # at N=1,3,5,etc
      },
    };
}
{ package Math::PlanePath::CfracDigits;
  use constant _NumSeq_Coord_IntXY_max => 0;   # upper octant 0 < X/Y < 1
  use constant _NumSeq_Coord_IntXY_non_decreasing => 1;
  use constant _NumSeq_FracXY_min_is_infimum => 1; # X,Y no common factor

  # X=Y doesn't occur so X,Y always differ by at least 1 bit.  The smallest
  # two differing by 1 bit are X=1,Y=2.
  use constant _NumSeq_Coord_BitOr_min => 3; # X=1,Y=2

  use constant _NumSeq_Coord_BitXor_min => 1; # X=2,Y=3
  use constant _NumSeq_Coord_ExperimentalHammingDist_min => 1; # X!=Y

  # use constant _NumSeq_Coord_oeis_anum =>
  #   { 'radix=2' =>
  # {
  # },
  # };
}
{ package Math::PlanePath::ChanTree;

  sub _NumSeq_Coord_Max_min {
    my ($self) = @_;
    # except in k=2 Calkin-Wilf, point X=1,Y=1 doesn't occur, only X=1,Y=2
    # or X=2,Y=1
    return ($self->{'k'} == 2 ? 1 : 2);
  }
  *_NumSeq_Coord_MaxAbs_min = \&_NumSeq_Coord_Max_min;

  use constant _NumSeq_Coord_SubHeight_min => undef;
  use constant _NumSeq_Coord_ExperimentalLeafDistance_max => undef;

  sub _NumSeq_Coord_Product_min {
    my ($self) = @_;
    return ($self->{'reduced'} || $self->{'k'} == 2
            ? 1    # X=1,Y=1 reduced or k=2 X=1,Y=1
            : 2);  # X=1,Y=2
  }
  sub _NumSeq_Coord_TRSquared_min {
    my ($self) = @_;
    return ($self->{'k'} == 2
            || ($self->{'reduced'} && ($self->{'k'} & 1) == 0)
            ? 4    # X=1,Y=1 reduced k even, or k=2 top 1/1
            : 7);  # X=2,Y=1
  }

  use constant _NumSeq_Coord_BitAnd_min => 0; # X=1,Y=2
  sub _NumSeq_Coord_BitOr_min {
    my ($self) = @_;
    return ($self->{'k'} == 2 || $self->{'reduced'} ? 1  # X=1,Y=1
            : $self->{'k'} & 1 ? 3  # k odd  X=1,Y=2
            : 2);                   # k even X=2,Y=2
  }
  sub _NumSeq_Coord_BitXor_min {
    my ($self) = @_;
    return ($self->{'k'} == 2 || $self->{'reduced'} ? 0  # X=1,Y=1
            : $self->{'k'} & 1 ? 1  # k odd  X=2,Y=3
            : 0);                   # k even X=2,Y=2
  }

  sub _NumSeq_Coord_ExperimentalParity_min {
    my ($self) = @_;
    return ($self->{'k'} % 2
            ? 1  # k odd has one odd, one even, so odd
            : 0);
  }
  # X!=Y when k odd
  *_NumSeq_Coord_ExperimentalHammingDist_min = \&_NumSeq_Coord_ExperimentalParity_min;

  use constant _NumSeq_Coord_oeis_anum =>
    {
     do { # k=2 same as CW
       my $cw = { Product => 'A070871',
                  Depth   => 'A000523', # floor(log2(n)) starting OFFSET=1
                  # OEIS-Other: A070871 planepath=ChanTree,k=2,n_start=1 coordinate_type=Product
                  # OEIS-Other: A000523 planepath=ChanTree,k=2,n_start=1 coordinate_type=Depth
                };
       (
        'k=2,n_start=1' => $cw,

        # 'k=2,reduced=0,points=even,n_start=1' => $cw,
        # 'k=2,reduced=1,points=even,n_start=1' => $cw,
        # 'k=2,reduced=0,points=all,n_start=1' => $cw,
        # 'k=2,reduced=1,points=all,n_start=1' => $cw,
       ),
     },
     # 'k=3,reduced=0,points=even,n_start=0' =>
     'k=3,n_start=0' =>
     { X => 'A191379',
       # OEIS-Catalogue: A191379 planepath=ChanTree
     },
    };
}

{ package Math::PlanePath::PeanoCurve;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
  use constant _NumSeq_Coord_oeis_anum =>
    {
     # Same in GrayCode and WunderlichSerpentine
     'radix=3' =>
     { X        => 'A163528',
       Y        => 'A163529',
       Sum      => 'A163530',
       SumAbs   => 'A163530',
       RSquared => 'A163531',
       # OEIS-Catalogue: A163528 planepath=PeanoCurve coordinate_type=X
       # OEIS-Catalogue: A163529 planepath=PeanoCurve coordinate_type=Y
       # OEIS-Catalogue: A163530 planepath=PeanoCurve coordinate_type=Sum
       # OEIS-Other:     A163530 planepath=PeanoCurve coordinate_type=SumAbs
       # OEIS-Catalogue: A163531 planepath=PeanoCurve coordinate_type=RSquared
     },
    };
}
{ package Math::PlanePath::WunderlichSerpentine;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
  use constant _NumSeq_Coord_oeis_anum =>
    {
     do {
       my $peano = { X        => 'A163528',
                     Y        => 'A163529',
                     Sum      => 'A163530',
                     SumAbs   => 'A163530',
                     RSquared => 'A163531',
                   };
       # OEIS-Other: A163528 planepath=WunderlichSerpentine,serpentine_type=Peano,radix=3 coordinate_type=X
       # OEIS-Other: A163529 planepath=WunderlichSerpentine,serpentine_type=Peano,radix=3 coordinate_type=Y
       # OEIS-Other: A163530 planepath=WunderlichSerpentine,serpentine_type=Peano,radix=3 coordinate_type=Sum
       # OEIS-Other: A163530 planepath=WunderlichSerpentine,serpentine_type=Peano,radix=3 coordinate_type=SumAbs
       # OEIS-Other: A163531 planepath=WunderlichSerpentine,serpentine_type=Peano,radix=3 coordinate_type=RSquared

       # ENHANCE-ME: with serpentine_type by bits too
       ('serpentine_type=Peano,radix=3' => $peano,
       )
     },
    };
}
{ package Math::PlanePath::HilbertCurve;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
  use constant _NumSeq_Coord_oeis_anum =>
    { '' =>
      { X           => 'A059253',
        Y           => 'A059252',
        Sum         => 'A059261',
        SumAbs      => 'A059261',
        DiffXY      => 'A059285',
        RSquared    => 'A163547',
        BitXor      => 'A059905',  # alternate bits first (ZOrderCurve X)
        ExperimentalHammingDist => 'A139351',  # count 1-bits at even bit positions
        # OEIS-Catalogue: A059253 planepath=HilbertCurve coordinate_type=X
        # OEIS-Catalogue: A059252 planepath=HilbertCurve coordinate_type=Y
        # OEIS-Catalogue: A059261 planepath=HilbertCurve coordinate_type=Sum
        # OEIS-Other:     A059261 planepath=HilbertCurve coordinate_type=SumAbs
        # OEIS-Catalogue: A059285 planepath=HilbertCurve coordinate_type=DiffXY
        # OEIS-Catalogue: A163547 planepath=HilbertCurve coordinate_type=RSquared
        # OEIS-Other:     A059905 planepath=HilbertCurve coordinate_type=BitXor
        # OEIS-Other:     A139351 planepath=HilbertCurve coordinate_type=ExperimentalHammingDist
      },
    };
}
{ package Math::PlanePath::HilbertSides;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
  use constant _NumSeq_Coord_oeis_anum =>
    { '' =>
      {
       #          1              -1
       #        /              /
       #          0          3    0   X-Y = 0,1,0,-1
       #        /            | /
       #  3---2   -1         2    1
       #      | /            | /
       #  0---1          0---1
       DiffXY   => 'A059285',
       # OEIS-Other: A059285 planepath=HilbertSides coordinate_type=DiffXY
      },
    };
}
{ package Math::PlanePath::HilbertSpiral;
  use constant _NumSeq_Coord_filling_type => 'plane';
  use constant _NumSeq_Coord_oeis_anum =>
    { '' =>
      {
       # HilbertSpiral going negative is mirror on X=-Y line, which is
       # (-Y,-X), so DiffXY = -Y-(-X) = X-Y same diff as plain HilbertCurve.
       DiffXY   => 'A059285',
       # OEIS-Other: A059285 planepath=HilbertSpiral coordinate_type=DiffXY
      },
    };
}
{ package Math::PlanePath::ZOrderCurve;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
  use constant _NumSeq_Coord_oeis_anum =>
    { 'radix=2' =>
      { X => 'A059905',  # alternate bits first
        Y => 'A059906',  # alternate bits second
        # OEIS-Catalogue: A059905 planepath=ZOrderCurve coordinate_type=X
        # OEIS-Catalogue: A059906 planepath=ZOrderCurve coordinate_type=Y
      },
      'radix=3' =>
      { X => 'A163325',  # alternate ternary digits first
        Y => 'A163326',  # alternate ternary digits second
        # OEIS-Catalogue: A163325 planepath=ZOrderCurve,radix=3 coordinate_type=X
        # OEIS-Catalogue: A163326 planepath=ZOrderCurve,radix=3 coordinate_type=Y
      },
      'radix=10,i_start=1' =>
      {
       # i_start=1 per A080463 offset=1, it skips initial zero
       Sum    => 'A080463',
       SumAbs => 'A080463',
       # OEIS-Catalogue: A080463 planepath=ZOrderCurve,radix=10 coordinate_type=Sum i_start=1
       # OEIS-Other:     A080463 planepath=ZOrderCurve,radix=10 coordinate_type=SumAbs i_start=1
      },
      'radix=10,i_start=10' =>
      {
       # i_start=10 per A080464 OFFSET=10, it skips all but one initial zeros
       Product => 'A080464',
       # OEIS-Catalogue: A080464 planepath=ZOrderCurve,radix=10 coordinate_type=Product i_start=10

       AbsDiff => 'A080465',
       # OEIS-Catalogue: A080465 planepath=ZOrderCurve,radix=10 coordinate_type=AbsDiff i_start=10
      },
    };
}
{ package Math::PlanePath::GrayCode;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
  use constant _NumSeq_Coord_oeis_anum =>
    {
     do {
       my $peano = { X        => 'A163528',
                     Y        => 'A163529',
                     Sum      => 'A163530',
                     SumAbs   => 'A163530',
                     RSquared => 'A163531',
                   };
       my $z = { BitXor        => 'A059905',
               };
       ('apply_type=TsF,gray_type=reflected,radix=3' => $peano,
        'apply_type=FsT,gray_type=reflected,radix=3' => $peano,
         # OEIS-Other: A163528 planepath=GrayCode,apply_type=TsF,radix=3 coordinate_type=X
         # OEIS-Other: A163529 planepath=GrayCode,apply_type=TsF,radix=3 coordinate_type=Y
         # OEIS-Other: A163530 planepath=GrayCode,apply_type=TsF,radix=3 coordinate_type=Sum
         # OEIS-Other: A163530 planepath=GrayCode,apply_type=TsF,radix=3 coordinate_type=SumAbs
         # OEIS-Other: A163531 planepath=GrayCode,apply_type=TsF,radix=3 coordinate_type=RSquared

         # OEIS-Other: A163528 planepath=GrayCode,apply_type=FsT,radix=3 coordinate_type=X
         # OEIS-Other: A163529 planepath=GrayCode,apply_type=FsT,radix=3 coordinate_type=Y
         # OEIS-Other: A163530 planepath=GrayCode,apply_type=FsT,radix=3 coordinate_type=Sum
         # OEIS-Other: A163530 planepath=GrayCode,apply_type=FsT,radix=3 coordinate_type=SumAbs
         # OEIS-Other: A163531 planepath=GrayCode,apply_type=FsT,radix=3 coordinate_type=RSquared

        'apply_type=TsF,gray_type=reflected,radix=2' => $z,
        'apply_type=TsF,gray_type=modular,radix=2' => $z,
        'apply_type=Fs,gray_type=reflected,radix=2' => $z,
        'apply_type=Fs,gray_type=modular,radix=2' => $z,
         # OEIS-Other: A059905 planepath=GrayCode,apply_type=TsF coordinate_type=BitXor
         # OEIS-Other: A059905 planepath=GrayCode,apply_type=TsF,gray_type=modular coordinate_type=BitXor
         # OEIS-Other: A059905 planepath=GrayCode,apply_type=Fs coordinate_type=BitXor
         # OEIS-Other: A059905 planepath=GrayCode,apply_type=Fs,gray_type=modular coordinate_type=BitXor
       ),
     },
    };
}
{ package Math::PlanePath::ImaginaryBase;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::ImaginaryHalf;
  use constant _NumSeq_Coord_filling_type => 'half';
}
{ package Math::PlanePath::CubicBase;
  use constant _NumSeq_Coord_filling_type => 'triangular';
  use constant _NumSeq_Coord_ExperimentalParity_max => 0;  # even always
}
{ package Math::PlanePath::Flowsnake;
  use constant _NumSeq_Coord_ExperimentalParity_max => 0;  # even always
}
{ package Math::PlanePath::FlowsnakeCentres;
  use constant _NumSeq_Coord_ExperimentalParity_max => 0;  # even always
}
{ package Math::PlanePath::GosperIslands;
  use constant _NumSeq_Coord_TRSquared_min => 4; # minimum X=1,Y=1
  use constant _NumSeq_Coord_ExperimentalParity_max => 0;  # even always
}
{ package Math::PlanePath::GosperReplicate;
  use constant _NumSeq_Coord_filling_type => 'triangular';
  use constant _NumSeq_Coord_ExperimentalParity_max => 0;  # even always
}
{ package Math::PlanePath::GosperSide;
  use constant _NumSeq_Coord_ExperimentalParity_max => 0;  # even always
}
{ package Math::PlanePath::KochCurve;
  use constant _NumSeq_Coord_IntXY_min => 3;  # at X=3,Y=1 among the Y>0 points
  use constant _NumSeq_Coord_ExperimentalParity_max => 0;  # even always
}
{ package Math::PlanePath::KochPeaks;
  use constant _NumSeq_Coord_MaxAbs_min => 1;  # odd always
  use constant _NumSeq_Coord_TRSquared_min => 1; # minimum X=1,Y=0
  use constant _NumSeq_Coord_ExperimentalParity_min => 1;  # odd always
  use constant _NumSeq_Coord_ExperimentalHammingDist_min => 1; # X!=Y
}
{ package Math::PlanePath::KochSnowflakes;
  use constant _NumSeq_Coord_Y_integer => 0;
  use constant _NumSeq_Coord_BitAnd_integer => 1; # only Y non-integer
  use constant _NumSeq_Coord_TRSquared_min => 3*4/9; # minimum X=0,Y=2/3
  use constant _NumSeq_Coord_MaxAbs_min => 2/3; # at N=3
  use constant _NumSeq_Coord_TRadius_min => sqrt(_NumSeq_Coord_TRSquared_min);
  use constant _NumSeq_Coord_GCD_integer => 0;
}
{ package Math::PlanePath::KochSquareflakes;
  use constant _NumSeq_Coord_X_integer => 0;
  use constant _NumSeq_Coord_Y_integer => 0;
  use constant _NumSeq_Coord_MaxAbs_min => 1/2; # at N=1
  use constant _NumSeq_Coord_Sum_integer => 1;
  use constant _NumSeq_Coord_SumAbs_integer => 1;
  use constant _NumSeq_Coord_DiffXY_integer => 1;
  use constant _NumSeq_Coord_DiffYX_integer => 1;
  use constant _NumSeq_Coord_AbsDiff_integer => 1;
  use constant _NumSeq_Coord_BitXor_integer => 1; # 0.5 xor 0.5 cancels out
  use constant _NumSeq_Coord_TRSquared_min => 1; # X=1/2, Y=1/2
  use constant _NumSeq_Coord_TRSquared_integer => 1;
  use constant _NumSeq_Coord_GCD_integer => 0;  # GCD(1/2,1/2)=1/2
}
{ package Math::PlanePath::QuadricCurve;
  use constant _NumSeq_Coord_IntXY_min => undef; # negatives
}
{ package Math::PlanePath::QuadricIslands;
  use constant _NumSeq_Coord_X_integer => 0;
  use constant _NumSeq_Coord_Y_integer => 0;
  use constant _NumSeq_Coord_Sum_integer => 1;    # 0.5 + 0.5 = integer
  use constant _NumSeq_Coord_SumAbs_integer => 1;
  use constant _NumSeq_Coord_DiffXY_integer => 1;
  use constant _NumSeq_Coord_DiffYX_integer => 1;
  use constant _NumSeq_Coord_AbsDiff_integer => 1;
  use constant _NumSeq_Coord_GCD_integer => 0;  # GCD(1/2,1/2)=1/2

  # BitXor X=1/2=0.1 Y=-1/2=-0.1=...1111.0  BitXor=0
  use constant _NumSeq_Coord_BitXor_integer => 1;

  # TRSquared on X=1/2,Y=1/2 is TR^2 = (1/2)^2+3*(1/2)^2 = 1
  use constant _NumSeq_Coord_TRSquared_integer => 1;
  use constant _NumSeq_Coord_TRSquared_min => 1; # X=1/2,Y=1/2
}
{ package Math::PlanePath::SierpinskiTriangle;
  sub _NumSeq_Coord_Y_non_decreasing {
    my ($self) = @_;
    return ($self->{'align'} ne 'diagonal'); # rows upwards, except diagonal
  }
  # Max==Y for align!=diagonal
  *_NumSeq_Coord_Max_non_decreasing = \&_NumSeq_Coord_Y_non_decreasing;
  *_NumSeq_Coord_MaxAbs_non_decreasing = \&_NumSeq_Coord_Y_non_decreasing;

  sub _NumSeq_Coord_Sum_non_decreasing {
    my ($self) = @_;
    return ($self->{'align'} eq 'diagonal'); # anti-diagonals
  }
  *_NumSeq_Coord_SumAbs_non_decreasing = \&_NumSeq_Coord_Sum_non_decreasing;

  use constant _NumSeq_Coord_IntXY_min => -1; # wedge

  # align=diagonal has X,Y no 1-bits in common, so BitAnd==0
  sub _NumSeq_Coord_BitAnd_max {
    my ($self) = @_;
    return ($self->{'align'} eq 'diagonal' ? 0
           : undef);
  }
  sub _NumSeq_Coord_BitAnd_non_decreasing {
    my ($self) = @_;
    return ($self->{'align'} eq 'diagonal');
  }

  # align=right,diagonal has X,Y BitOr 1-bits accumulating ...
  sub _NumSeq_Coord_BitOr_non_decreasing {
    my ($self) = @_;
    return ($self->{'align'} eq 'right'
            || $self->{'align'} eq 'diagonal');
  }

  # align=diagonal has X,Y no bits in common so is same as BitOr 1-bits
  # accumulating ...
  sub _NumSeq_Coord_BitXor_non_decreasing {
    my ($self) = @_;
    return ($self->{'align'} eq 'diagonal');
  }

  sub _NumSeq_Coord_ExperimentalParity_max {
    my ($self) = @_;
    return ($self->{'align'} eq 'triangular'
            ? 0   # triangular always even points
            : 1);
  }

  use constant _NumSeq_Coord_ExperimentalLeafDistance_max => 4;
}
{ package Math::PlanePath::SierpinskiArrowhead;
  use constant _NumSeq_Coord_IntXY_min => -1; # wedge
  *_NumSeq_Coord_ExperimentalParity_max
    = \&Math::PlanePath::SierpinskiTriangle::_NumSeq_Coord_ExperimentalParity_max;
}
{ package Math::PlanePath::SierpinskiArrowheadCentres;
  use constant _NumSeq_Coord_IntXY_min => -1; # wedge
  *_NumSeq_Coord_BitAnd_max
    = \&Math::PlanePath::SierpinskiTriangle::_NumSeq_Coord_BitAnd_max;
  *_NumSeq_Coord_BitAnd_non_decreasing
    = \&Math::PlanePath::SierpinskiTriangle::_NumSeq_Coord_BitAnd_non_decreasing;
  *_NumSeq_Coord_ExperimentalParity_max
    = \&Math::PlanePath::SierpinskiTriangle::_NumSeq_Coord_ExperimentalParity_max;
}
{ package Math::PlanePath::SierpinskiCurve;
  {
    my @Max_min = (undef,
                   1,  # 1 arm, octant X>Y and X>=1
                   1,  # 2 arms, quadrant X>=1 or Y>=1
                   1,  # 3 arms
                   0,  # 4 arms
                   # more than 3 arm, Max goes negative unbounded
                  );
    sub _NumSeq_Coord_Max_min {
      my ($self) = @_;
      return $Max_min[$self->arms_count];
    }
  }
  {
    my @IntXY_min = (undef,
                     1,  # octant X>Y so X/Y>1
                     0,  # quadrant X>=0 so X/Y>=0
                     -1, # 3-oct X>=-Y so X/Y>=-1
                    );   # arms>=4 has X unbounded negative
    sub _NumSeq_Coord_IntXY_min {
      my ($self) = @_;
      return $IntXY_min[$self->arms_count];
    }
  }

  use constant _NumSeq_Coord_TRSquared_min => 1; # minimum X=1,Y=0
  sub _NumSeq_Coord_BitOr_min {
    my ($self) = @_;
    return ($self->arms_count <= 2
            ? 1       # X=0,Y=0 not visited BitOr(X,Y)>=1
            : undef); # going X negative
  }
  sub _NumSeq_Coord_BitXor_min {
    my ($self) = @_;
    return ($self->arms_count <= 2
            ? 1       # X!=Y so BitXor(X,Y)>=1
            : undef); # going X negative
  }
}
{ package Math::PlanePath::SierpinskiCurveStair;
  use constant _NumSeq_Coord_Max_min => 1;
  *_NumSeq_Coord_IntXY_min = \&Math::PlanePath::SierpinskiCurve::_NumSeq_Coord_IntXY_min;
  *_NumSeq_Coord_BitOr_min = \&Math::PlanePath::SierpinskiCurve::_NumSeq_Coord_BitOr_min;
  *_NumSeq_Coord_BitXor_min = \&Math::PlanePath::SierpinskiCurve::_NumSeq_Coord_BitXor_min;
  use constant _NumSeq_Coord_TRSquared_min => 1; # minimum X=1,Y=0
}
{ package Math::PlanePath::HIndexing;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
#   # except 0/0=inf
#   # use constant _NumSeq_Coord_IntXY_max => 1; # upper octant X<=Y so X/Y<=1
}
{ package Math::PlanePath::DragonCurve;
  use constant _NumSeq_Coord_n_list_max => 2;

  # 4-arm plane filling if full grid
  sub _NumSeq_Coord_ExperimentalNeighbours4_min {
    my ($self) = @_;
    return $self->arms_count == 4 ? 4 : 2;
  }
  # use constant _NumSeq_Coord_ExperimentalNeighbours6_min => 0; # ???
  sub _NumSeq_Coord_ExperimentalNeighbours8_min {
    my ($self) = @_;
    return $self->arms_count == 4 ? 8 : 3;
  }
}
{ package Math::PlanePath::DragonRounded;
  use constant _NumSeq_Coord_TRSquared_min => 1; # minimum X=1,Y=0
  use constant _NumSeq_Coord_ExperimentalHammingDist_min => 1; # X!=Y
  use constant _NumSeq_Coord_MaxAbs_min => 1; # X!=Y
}
# { package Math::PlanePath::DragonMidpoint;
# }
{ package Math::PlanePath::AlternatePaper;
  use constant _NumSeq_Coord_n_list_max => 2;
  {
    my @_NumSeq_Coord_IntXY_min = (undef,
                                   1,  # 1 arm, octant X+Y>=0
                                   0,  # 2 arms, X>=0
                                   0,  # 3 arms, X>-Y so X/Y>-1
                                  );   # more than 3 arm, X neg axis so undef
    sub _NumSeq_Coord_IntXY_min {
      my ($self) = @_;
      return $_NumSeq_Coord_IntXY_min[$self->arms_count];
    }
  }

  # 8-arm plane filling if full grid
  {
    #                                                 arms  1 2 3 4 5 6 7 8
    my @_NumSeq_Coord_ExperimentalNeighbours3_min = (undef, 1,1,2,2,3,3,3,3);
    sub _NumSeq_Coord_ExperimentalNeighbours3_min {
      my ($self) = @_;
      return $_NumSeq_Coord_ExperimentalNeighbours3_min[$self->arms_count];
    }
  }
  {
    #                                                 arms  1 2 3 4 5 6 7 8
    my @_NumSeq_Coord_ExperimentalNeighbours4_min = (undef, 1,2,2,3,3,3,3,4);
    sub _NumSeq_Coord_ExperimentalNeighbours4_min {
      my ($self) = @_;
      return $_NumSeq_Coord_ExperimentalNeighbours4_min[$self->arms_count];
    }
  }
  # use constant _NumSeq_Coord_ExperimentalNeighbours6_min => 0; # ???
  {
    #                                                 arms  1 2 3 4 5 6 7 8
    my @_NumSeq_Coord_ExperimentalNeighbours8_min = (undef, 2,3,4,5,6,7,7,8);
    sub _NumSeq_Coord_ExperimentalNeighbours8_min {
      my ($self) = @_;
      return $_NumSeq_Coord_ExperimentalNeighbours8_min[$self->arms_count];
    }
  }

  use constant _NumSeq_Coord_oeis_anum =>
    { 'i_start=1' =>
      { DiffXY  => 'A020990', # GRS*(-1)^n cumulative
        AbsDiff => 'A020990',

        # Not quite, OFFSET=0 value=1 which corresponds to N=1 Sum=1, so
        # A020986 doesn't have N=0 Sum=0.
        # Sum     => 'A020986', # GRS cumulative
        # # OEIS-Catalogue: A020986 planepath=AlternatePaper coordinate_type=Sum i_start=1

        # X_undoubled => 'A020986', # GRS cumulative
        # Y_undoubled => 'A020990', # GRS*(-1)^n cumulative
      },
    };
}
{ package Math::PlanePath::AlternatePaperMidpoint;
  {
    my @_NumSeq_Coord_IntXY_min = (undef,
                                   1,  # 1 arm, octant X+Y>=0
                                   0,  # 2 arms, X>=0
                                   0,  # 3 arms, X>-Y so X/Y>-1
                                  );   # more than 3 arm, X neg axis so undef
    sub _NumSeq_Coord_IntXY_min {
      my ($self) = @_;
      return $_NumSeq_Coord_IntXY_min[$self->arms_count];
    }
  }
}
{ package Math::PlanePath::TerdragonCurve;
  use constant _NumSeq_Coord_ExperimentalParity_max => 0;  # even always
  use constant _NumSeq_Coord_n_list_max => 3;
}
{ package Math::PlanePath::TerdragonRounded;
  use constant _NumSeq_Coord_TRSquared_min => 4; # either X=2,Y=0 or X=1,Y=1
  use constant _NumSeq_Coord_ExperimentalParity_max => 0;  # even always
}
{ package Math::PlanePath::TerdragonMidpoint;
  use constant _NumSeq_Coord_TRSquared_min => 4; # either X=2,Y=0 or X=1,Y=1
  use constant _NumSeq_Coord_ExperimentalParity_max => 0;  # even always
}
{ package Math::PlanePath::AlternateTerdragon;
  use constant _NumSeq_Coord_ExperimentalParity_max => 0;  # even always
  use constant _NumSeq_Coord_n_list_max => 3;
}
{ package Math::PlanePath::R5DragonCurve;
  use constant _NumSeq_Coord_n_list_max => 2;
}
# { package Math::PlanePath::R5DragonMidpoint;
# }
{ package Math::PlanePath::CCurve;
  use constant _NumSeq_Coord_n_list_max => 4;
}
# { package Math::PlanePath::ComplexPlus;
  # Sum X+Y < 0 at N=16
  # use constant _NumSeq_Coord_oeis_anum =>
  #  { 'realpart=1,arms=1' =>
  #    {
  #     # not quite, OFFSET=1 but start N=0 here
  #     # Y        => 'A290884',
  #     # RSquared => 'A290886',
  #     # OEIS-Catalogue: A290884 planepath=ComplexPlus coordinate_type=Y
  #     # OEIS-Catalogue: A290886 planepath=ComplexPlus coordinate_type=RSquared
  #     # also -X, also OFFSET=1
  #     # NegX => 'A290885',
  #    },
  #  };
# }
{ package Math::PlanePath::ComplexMinus;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::ComplexRevolving;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::Rows;
  use constant _NumSeq_extra_parameter_info_list =>
    { name => 'width',
      type => 'integer',
    };

  *_NumSeq_Coord_X_non_decreasing       = \&_NumSeq_Coord_Y_increasing;

  sub _NumSeq_Coord_Y_increasing {
    my ($self) = @_;
    return ($self->{'width'} == 1
            ? 1    # X=N,Y=0 only
            : 0);
  }

  sub _NumSeq_Coord_Min_max { $_[0]->x_maximum }
  *_NumSeq_Coord_Max_increasing=\&_NumSeq_Coord_Y_increasing; # height=1 Max=Y
  sub _NumSeq_Coord_Max_non_decreasing {
    my ($self) = @_;
    return ($self->{'width'} <= 2);
  }

  sub _NumSeq_Coord_Sum_non_decreasing {
    my ($self) = @_;
    return ($self->{'width'} <= 2
            ? 1    # width=1 is X=0,Y=N only, or width=2 is X=0,1,Y=N/2
            : 0);
  }
  *_NumSeq_Coord_Sum_increasing         = \&_NumSeq_Coord_Y_increasing;

  *_NumSeq_Coord_SumAbs_non_decreasing = \&_NumSeq_Coord_Sum_non_decreasing;
  *_NumSeq_Coord_SumAbs_increasing     = \&_NumSeq_Coord_Y_increasing;

  *_NumSeq_Coord_DiffYX_increasing      = \&_NumSeq_Coord_Y_increasing;

  *_NumSeq_Coord_Product_non_decreasing = \&_NumSeq_Coord_Y_increasing;

  *_NumSeq_Coord_AbsDiff_increasing     = \&_NumSeq_Coord_Y_increasing;

  sub _NumSeq_Coord_BitAnd_max {
    my ($self) = @_;
    return $self->{'width'}-1;  # at X=Y=width-1
  }
  *_NumSeq_Coord_BitAnd_non_decreasing  = \&_NumSeq_Coord_Y_increasing;

  *_NumSeq_Coord_BitOr_increasing       = \&_NumSeq_Coord_Y_increasing;
  *_NumSeq_Coord_BitXor_increasing      = \&_NumSeq_Coord_Y_increasing;

  *_NumSeq_Coord_Radius_non_decreasing = \&_NumSeq_Coord_Sum_non_decreasing;
  *_NumSeq_Coord_Radius_increasing      = \&_NumSeq_Coord_Y_increasing;
  *_NumSeq_Coord_Radius_integer         = \&_NumSeq_Coord_Y_increasing;

  *_NumSeq_Coord_GCD_increasing         = \&_NumSeq_Coord_Y_increasing;

  # width <= 2 one or two columns is increasing
  *_NumSeq_Coord_TRadius_increasing = \&_NumSeq_Coord_Sum_non_decreasing;

  use constant _NumSeq_Coord_Y_non_decreasing => 1; # rows upwards

  use constant _NumSeq_Coord_oeis_anum =>
    { 'n_start=1,width=1' =>
      { Product  => 'A000004', # all zeros
        # OEIS-Other: A000004 planepath=Rows,width=1 coordinate_type=Product

        # OFFSET
        # Y        => 'A001477', # integers 0 upwards
        # Sum      => 'A001477', # integers 0 upwards
        # # OEIS-Other: A001477 planepath=Rows,width=1 coordinate_type=Y
        # DiffXY   => 'A001489', # negative integers 0 downwards
        # DiffYX   => 'A001477', # integers 0 upwards
        # AbsDiff  => 'A001477', # integers 0 upwards
        # Radius   => 'A001477', # integers 0 upwards
        # RSquared => 'A000290', # squares 0 upwards
        # # OEIS-Other: A001477 planepath=Rows,width=1 coordinate_type=Sum
        # # OEIS-Other: A001489 planepath=Rows,width=1 coordinate_type=DiffXY
        # # OEIS-Other: A001477 planepath=Rows,width=1 coordinate_type=DiffYX
        # # OEIS-Other: A001477 planepath=Rows,width=1 coordinate_type=AbsDiff
        # # OEIS-Other: A001477 planepath=Rows,width=1 coordinate_type=Radius
        # # OEIS-Other: A000290 planepath=Rows,width=1 coordinate_type=RSquared
      },

      'n_start=0,width=2' =>
      { X       => 'A000035', # 0,1 repeating OFFSET=0
        Y       => 'A004526', # 0,0,1,1,2,2,etc cf Math::NumSeq::Runs
        # OEIS-Other: A000035 planepath=Rows,width=2,n_start=0 coordinate_type=X
        # OEIS-Other: A004526 planepath=Rows,width=2,n_start=0 coordinate_type=Y

        #   # Not quite, A142150 OFFSET=0 starting 0,0,1,0,2 interleave integers
        #   # and 0 but Product here extra 0 start 0,0,0,1,0,2,0
        #   # Product => 'A142150'
        #
        #   # Not quite, GCD=>'A057979' but A057979 extra initial 1
      },
    };
}
{ package Math::PlanePath::Columns;
  use constant _NumSeq_extra_parameter_info_list =>
    { name => 'height',
      type => 'integer',
    };

  sub _NumSeq_Coord_X_increasing {
    my ($self) = @_;
    return ($self->{'height'} == 1
            ? 1    # X=N,Y=0 only
            : 0);
  }
  use constant _NumSeq_Coord_X_non_decreasing => 1; # columns across

  *_NumSeq_Coord_Y_non_decreasing       = \&_NumSeq_Coord_X_increasing;

  sub _NumSeq_Coord_Min_max { $_[0]->y_maximum }
  *_NumSeq_Coord_Max_increasing=\&_NumSeq_Coord_X_increasing; # height=1 Max=X
  sub _NumSeq_Coord_Max_non_decreasing {
    my ($self) = @_;
    return ($self->{'height'} <= 2);
  }

  *_NumSeq_Coord_Sum_increasing         = \&_NumSeq_Coord_X_increasing;
  sub _NumSeq_Coord_Sum_non_decreasing {
    my ($self) = @_;
    return ($self->{'height'} <= 2
            ? 1    # height=1 is X=N,Y=0 only, or height=2 is X=N/2,Y=0,1
            : 0);
  }

  *_NumSeq_Coord_SumAbs_increasing      = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_SumAbs_non_decreasing = \&_NumSeq_Coord_Sum_non_decreasing;

  *_NumSeq_Coord_DiffXY_increasing      = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_AbsDiff_increasing     = \&_NumSeq_Coord_X_increasing;

  *_NumSeq_Coord_Radius_increasing      = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_Radius_integer         = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_TRadius_increasing     = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_TRadius_integer        = \&_NumSeq_Coord_X_increasing;

  sub _NumSeq_Coord_BitAnd_max {
    my ($self) = @_;
    return $self->{'height'}-1;  # at X=Y=height-1
  }
  *_NumSeq_Coord_BitAnd_non_decreasing  = \&_NumSeq_Coord_X_increasing;

  *_NumSeq_Coord_BitOr_increasing       = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_BitXor_increasing      = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_Product_non_decreasing = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_GCD_increasing         = \&_NumSeq_Coord_X_increasing;

  *_NumSeq_Coord_Radius_non_decreasing = \&_NumSeq_Coord_Sum_non_decreasing;

  use constant _NumSeq_Coord_oeis_anum =>
    { 'n_start=1,height=1' =>
      { Product  => 'A000004', # all zeros
        # OEIS-Other: A000004 planepath=Columns,height=1 coordinate_type=Product

        # OFFSET
        # X        => 'A001477', # integers 0 upwards
        # Sum      => 'A001477', # integers 0 upwards
        # DiffXY   => 'A001477', # integers 0 upwards
        # DiffYX   => 'A001489', # negative integers 0 downwards
        # AbsDiff  => 'A001477', # integers 0 upwards
        # Radius   => 'A001477', # integers 0 upwards
        # RSquared => 'A000290', # squares 0 upwards
        # # OEIS-Other: A001477 planepath=Columns,height=1 coordinate_type=X
        # # OEIS-Other: A001477 planepath=Columns,height=1 coordinate_type=Sum
        # # OEIS-Other: A001489 planepath=Columns,height=1 coordinate_type=DiffYX
        # # OEIS-Other: A001477 planepath=Columns,height=1 coordinate_type=DiffXY
        # # OEIS-Other: A001477 planepath=Columns,height=1 coordinate_type=AbsDiff
        # # OEIS-Other: A001477 planepath=Columns,height=1 coordinate_type=Radius
        # # OEIS-Other: A000290 planepath=Columns,height=1 coordinate_type=RSquared
      },

      'n_start=0,height=2' =>
      { X       => 'A004526', # 0,0,1,1,2,2,etc, as per Math::NumSeq::Runs 2rep
        Y       => 'A000035', # 0,1 repeating OFFSET=0
        # OEIS-Other: A004526 planepath=Columns,height=2,n_start=0 coordinate_type=X
        # OEIS-Other: A000035 planepath=Columns,height=2,n_start=0 coordinate_type=Y
      },
    };
}
{ package Math::PlanePath::Diagonals;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
  use constant _NumSeq_Coord_Sum_non_decreasing => 1; # X+Y diagonals

  sub _NumSeq_Coord_SumAbs_non_decreasing {
    my ($self) = @_;
    return ($self->{'x_start'} >= 0 && $self->{'y_start'} >= 0);
  }

  # these irrespective where x_start,y_start make x_minimum(),y_minimum()
  use constant _NumSeq_Coord_BitAnd_min => 0;  # when all diff bits
  use constant _NumSeq_Coord_BitXor_min => 0;  # when X=Y

  use constant _NumSeq_Coord_oeis_anum =>
    {
     'direction=down,n_start=1,x_start=0,y_start=0' =>
     { ExperimentalPairsXY => 'A057554',  # starting OFFSET=1 so the default n_start=1 here
       # OEIS-Catalogue: A057554 planepath=Diagonals coordinate_type=ExperimentalPairsXY
     },
     'direction=up,n_start=1,x_start=0,y_start=0' =>
     { ExperimentalPairsYX => 'A057554',  # starting OFFSET=1 so the default n_start=1 here
       # OEIS-Other:     A057554 planepath=Diagonals,direction=up coordinate_type=ExperimentalPairsYX
     },

     'direction=down,n_start=1,x_start=1,y_start=0' =>
     { ExperimentalNumerator   => 'A164306',  # T(n,k) = k/GCD(n,k) n,k>=1 offset=1
       ExperimentalDenominator => 'A167192',  # T(n,k) = (n-k)/GCD(n,k) n,k>=1 offset=1
       # OEIS-Catalogue: A164306 planepath=Diagonals,x_start=1,y_start=0 coordinate_type=ExperimentalNumerator
       # OEIS-Catalogue: A167192 planepath=Diagonals,x_start=1,y_start=0 coordinate_type=ExperimentalDenominator
     },

     'direction=down,n_start=1,x_start=1,y_start=1' =>
     { Product => 'A003991', # X*Y starting (1,1) n=1
       GCD     => 'A003989', # GCD by diagonals starting (1,1) n=1
       Min     => 'A003983', # X,Y>=1
       MinAbs  => 'A003983', #   MinAbs=Min
       Max     => 'A051125', # X,Y>=1
       MaxAbs  => 'A051125', #   MaxAbs=Max
       IntXY   => 'A004199', # X>=0,Y>=0, X/Y round towards zero
       ExperimentalPairsXY => 'A057555',  # starting OFFSET=1 so n_start=1 here
       # OEIS-Catalogue: A003991 planepath=Diagonals,x_start=1,y_start=1 coordinate_type=Product
       # OEIS-Catalogue: A003989 planepath=Diagonals,x_start=1,y_start=1 coordinate_type=GCD
       # OEIS-Catalogue: A003983 planepath=Diagonals,x_start=1,y_start=1 coordinate_type=Min
       # OEIS-Other:     A003983 planepath=Diagonals,x_start=1,y_start=1 coordinate_type=MinAbs
       # OEIS-Catalogue: A051125 planepath=Diagonals,x_start=1,y_start=1 coordinate_type=Max
       # OEIS-Other:     A051125 planepath=Diagonals,x_start=1,y_start=1 coordinate_type=MaxAbs
       # OEIS-Catalogue: A004199 planepath=Diagonals,x_start=1,y_start=1 coordinate_type=IntXY
       # OEIS-Catalogue: A057555 planepath=Diagonals,x_start=1,y_start=1 coordinate_type=ExperimentalPairsXY

       # cf A003990 LCM starting (1,1) n=1
       #    A003992 X^Y power starting (1,1) n=1
     },

     'direction=up,n_start=1,x_start=1,y_start=1' =>
     { Product => 'A003991', # X*Y starting (1,1) n=1
       GCD     => 'A003989', # GCD by diagonals starting (1,1) n=1
       IntXY   => 'A003988', # Int(X/Y) starting (1,1) n=1
       ExperimentalPairsYX => 'A057555',  # starting OFFSET=1 so n_start=1 here
       # OEIS-Other:     A003991 planepath=Diagonals,direction=up,x_start=1,y_start=1 coordinate_type=Product
       # OEIS-Other:     A003989 planepath=Diagonals,direction=up,x_start=1,y_start=1 coordinate_type=GCD
       # OEIS-Catalogue: A003988 planepath=Diagonals,direction=up,x_start=1,y_start=1 coordinate_type=IntXY
       # OEIS-Other:     A057555 planepath=Diagonals,direction=up,x_start=1,y_start=1 coordinate_type=ExperimentalPairsYX

       # num,den of reduction of A004736/A002260 which is run1toK/runKto1.
       ExperimentalNumerator   => 'A112543', # 1,2,1,3,1,1,4,3,2,1,5,2,1,1,1,6,
       ExperimentalDenominator => 'A112544', # 1,1,2,1,1,3,1,2,3,4,1,1,1,2,5,1,
       # OEIS-Catalogue: A112543 planepath=Diagonals,direction=up,x_start=1,y_start=1 coordinate_type=ExperimentalNumerator
       # OEIS-Catalogue: A112544 planepath=Diagonals,direction=up,x_start=1,y_start=1 coordinate_type=ExperimentalDenominator
     },

     #------------------
     # n_start=0 instead

     'direction=down,n_start=0,x_start=0,y_start=0' =>
     { X           => 'A002262',  # runs 0toN   0, 0,1, 0,1,2, etc
       Y           => 'A025581',  # runs Nto0   0, 1,0, 2,1,0, 3,2,1,0 descend
       Sum         => 'A003056',  # 0, 1,1, 2,2,2, 3,3,3,3
       SumAbs      => 'A003056',  #   same
       Product     => 'A004247',  # 0, 0,0,0, 1, 0,0, 2,2, 0,0, 3,4,5, 0,0
       DiffYX      => 'A114327',  # Y-X by anti-diagonals
       AbsDiff     => 'A049581',  # abs(Y-X) by anti-diagonals
       RSquared    => 'A048147',  # x^2+y^2 by diagonals
       BitAnd      => 'A004198',  # X bitand Y
       BitOr       => 'A003986',  # X bitor Y, cf A006583 diagonal totals
       BitXor      => 'A003987',  # cf A006582 X xor Y diagonal totals
       GCD         => 'A109004',  # GCD(x,y) by diagonals, (0,0) at n=0
       Min         => 'A004197',  # X,Y>=0, runs 0toNto0,0toNNto0
       MinAbs      => 'A004197',  #  MinAbs=Min
       Max         => 'A003984',
       MaxAbs      => 'A003984',  #  MaxAbs=Max
       ExperimentalHammingDist => 'A101080',
       # OEIS-Other: A002262 planepath=Diagonals,n_start=0 coordinate_type=X
       # OEIS-Other: A025581 planepath=Diagonals,n_start=0 coordinate_type=Y
       # OEIS-Other: A003056 planepath=Diagonals,n_start=0 coordinate_type=Sum
       # OEIS-Other: A003056 planepath=Diagonals,n_start=0 coordinate_type=SumAbs
       # OEIS-Catalogue: A004247 planepath=Diagonals,n_start=0 coordinate_type=Product
       # OEIS-Catalogue: A114327 planepath=Diagonals,n_start=0 coordinate_type=DiffYX
       # OEIS-Catalogue: A049581 planepath=Diagonals,n_start=0 coordinate_type=AbsDiff
       # OEIS-Catalogue: A048147 planepath=Diagonals,n_start=0 coordinate_type=RSquared
       # OEIS-Catalogue: A004198 planepath=Diagonals,n_start=0 coordinate_type=BitAnd
       # OEIS-Catalogue: A003986 planepath=Diagonals,n_start=0 coordinate_type=BitOr
       # OEIS-Catalogue: A003987 planepath=Diagonals,n_start=0 coordinate_type=BitXor
       # OEIS-Catalogue: A109004 planepath=Diagonals,n_start=0 coordinate_type=GCD
       # OEIS-Catalogue: A004197 planepath=Diagonals,n_start=0 coordinate_type=Min
       # OEIS-Other:     A004197 planepath=Diagonals,n_start=0 coordinate_type=MinAbs
       # OEIS-Catalogue: A003984 planepath=Diagonals,n_start=0 coordinate_type=Max
       # OEIS-Other:     A003984 planepath=Diagonals,n_start=0 coordinate_type=MaxAbs
       # OEIS-Catalogue: A101080 planepath=Diagonals,n_start=0 coordinate_type=ExperimentalHammingDist
     },
     'direction=up,n_start=0,x_start=0,y_start=0' =>
     { X        => 'A025581',  # \ opposite of direction="down"
       Y        => 'A002262',  # /
       Sum      => 'A003056',  # \
       SumAbs   => 'A003056',  # | same as direction="down'
       Product  => 'A004247',  # |
       AbsDiff  => 'A049581',  # |
       RSquared => 'A048147',  # /
       DiffXY   => 'A114327',  # transposed from direction="down"
       BitAnd   => 'A004198',  # X bitand Y
       BitOr    => 'A003986',  # X bitor Y, cf A006583 diagonal totals
       BitXor   => 'A003987',  # cf A006582 X xor Y diagonal totals
       GCD      => 'A109004',  # GCD(x,y) by diagonals, (0,0) at n=0
       ExperimentalHammingDist => 'A101080',
       # OEIS-Other: A025581 planepath=Diagonals,direction=up,n_start=0 coordinate_type=X
       # OEIS-Other: A002262 planepath=Diagonals,direction=up,n_start=0 coordinate_type=Y
       # OEIS-Other: A003056 planepath=Diagonals,direction=up,n_start=0 coordinate_type=Sum
       # OEIS-Other: A003056 planepath=Diagonals,direction=up,n_start=0 coordinate_type=SumAbs
       # OEIS-Other: A004247 planepath=Diagonals,direction=up,n_start=0 coordinate_type=Product
       # OEIS-Other: A114327 planepath=Diagonals,direction=up,n_start=0 coordinate_type=DiffXY
       # OEIS-Other: A049581 planepath=Diagonals,direction=up,n_start=0 coordinate_type=AbsDiff
       # OEIS-Other: A048147 planepath=Diagonals,direction=up,n_start=0 coordinate_type=RSquared
       # OEIS-Other: A004198 planepath=Diagonals,direction=up,n_start=0 coordinate_type=BitAnd
       # OEIS-Other: A003986 planepath=Diagonals,direction=up,n_start=0 coordinate_type=BitOr
       # OEIS-Other: A003987 planepath=Diagonals,direction=up,n_start=0 coordinate_type=BitXor
       # OEIS-Other: A109004 planepath=Diagonals,direction=up,n_start=0 coordinate_type=GCD
       # OEIS-Other: A101080 planepath=Diagonals,direction=up,n_start=0 coordinate_type=ExperimentalHammingDist
     },

    };
}
{ package Math::PlanePath::DiagonalsAlternating;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
  use constant _NumSeq_Coord_Sum_non_decreasing => 1; # X+Y diagonals
  use constant _NumSeq_Coord_SumAbs_non_decreasing => 1; # X+Y diagonals

  use constant _NumSeq_Coord_oeis_anum =>
    { 'n_start=0' =>
      { Sum         => 'A003056',  # 0, 1,1, 2,2,2, 3,3,3,3
        SumAbs      => 'A003056',  #   same
        Product     => 'A004247',  # 0, 0,0,0, 1, 0,0, 2,2, 0,0, 3,4,5, 0,0
        AbsDiff     => 'A049581',  # abs(Y-X) by anti-diagonals
        RSquared    => 'A048147',  # x^2+y^2 by diagonals
        BitAnd      => 'A004198',  # X bitand Y
        BitOr       => 'A003986',  # X bitor Y, cf A006583 diagonal totals
        BitXor      => 'A003987',  # cf A006582 X xor Y diagonal totals
        Min         => 'A004197',  # runs 0toNto0,0toNNto0
        MinAbs      => 'A004197',  # MinAbs=Min
        Max         => 'A003984',
        MaxAbs      => 'A003984',  # MaxAbs=Max
        ExperimentalHammingDist => 'A101080',
        # OEIS-Other: A003056 planepath=DiagonalsAlternating,n_start=0 coordinate_type=Sum
        # OEIS-Other: A003056 planepath=DiagonalsAlternating,n_start=0 coordinate_type=SumAbs
        # OEIS-Other: A004247 planepath=DiagonalsAlternating,n_start=0 coordinate_type=Product
        # OEIS-Other: A049581 planepath=DiagonalsAlternating,n_start=0 coordinate_type=AbsDiff
        # OEIS-Other: A048147 planepath=DiagonalsAlternating,n_start=0 coordinate_type=RSquared
        # OEIS-Other: A004198 planepath=DiagonalsAlternating,n_start=0 coordinate_type=BitAnd
        # OEIS-Other: A003986 planepath=DiagonalsAlternating,n_start=0 coordinate_type=BitOr
        # OEIS-Other: A003987 planepath=DiagonalsAlternating,n_start=0 coordinate_type=BitXor
        # OEIS-Other: A004197 planepath=DiagonalsAlternating,n_start=0 coordinate_type=Min
        # OEIS-Other: A004197 planepath=DiagonalsAlternating,n_start=0 coordinate_type=MinAbs
        # OEIS-Other: A003984 planepath=DiagonalsAlternating,n_start=0 coordinate_type=Max
        # OEIS-Other: A003984 planepath=DiagonalsAlternating,n_start=0 coordinate_type=MaxAbs
        # OEIS-Other: A101080 planepath=DiagonalsAlternating,n_start=0 coordinate_type=ExperimentalHammingDist
      },
    };
}
{ package Math::PlanePath::DiagonalsOctant;
  use constant _NumSeq_Coord_Sum_non_decreasing => 1; # X+Y diagonals
  use constant _NumSeq_Coord_SumAbs_non_decreasing => 1; # X+Y diagonals

  use constant _NumSeq_Coord_oeis_anum =>
    { 'direction=down,n_start=0' =>
      { X       => 'A055087',  # 0, 0,1, 0,1, 0,1,2, 0,1,2, etc
        Min     => 'A055087',  # X<=Y so Min=X
        MinAbs  => 'A055087',  #   MinAbs=Min
        Sum     => 'A055086',  # reps floor(n/2)+1
        SumAbs  => 'A055086',  #   same
        DiffYX  => 'A082375',  # step=2 k to 0
        # OEIS-Catalogue: A055087 planepath=DiagonalsOctant,n_start=0 coordinate_type=X
        # OEIS-Other:     A055087 planepath=DiagonalsOctant,n_start=0 coordinate_type=Min
        # OEIS-Other:     A055087 planepath=DiagonalsOctant,n_start=0 coordinate_type=MinAbs
        # OEIS-Catalogue: A055086 planepath=DiagonalsOctant,n_start=0 coordinate_type=Sum
        # OEIS-Other:     A055086 planepath=DiagonalsOctant,n_start=0 coordinate_type=SumAbs
        # OEIS-Catalogue: A082375 planepath=DiagonalsOctant,n_start=0 coordinate_type=DiffYX
      },
      'direction=up,n_start=0' =>
      { Sum     => 'A055086',  # reps floor(n/2)+1
        SumAbs  => 'A055086',  #   same
        # OEIS-Other: A055086 planepath=DiagonalsOctant,direction=up,n_start=0 coordinate_type=Sum
        # OEIS-Other: A055086 planepath=DiagonalsOctant,direction=up,n_start=0 coordinate_type=SumAbs
      },
    };
}
{ package Math::PlanePath::MPeaks;
  use constant _NumSeq_Coord_filling_type => 'half';
}
{ package Math::PlanePath::Staircase;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
}
# { package Math::PlanePath::StaircaseAlternating;
# }
{ package Math::PlanePath::Corner;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
  sub _NumSeq_Coord_Max_non_decreasing {
    my ($self) = @_;
    # non-decreasing when wider=0 or 1
    return ($self->{'wider'} <= 1);
  }
  use constant _NumSeq_Coord_oeis_anum =>
    { 'wider=0,n_start=1' =>
      { Sum     => 'A213088', # Manhattan X+Y
        SumAbs  => 'A213088',
        # OEIS-Catalogue: A213088 planepath=Corner coordinate_type=Sum
        # OEIS-Other:     A213088 planepath=Corner coordinate_type=SumAbs
      },
      'wider=0,n_start=0' =>
      { DiffXY  => 'A196199', # runs -n to n
        AbsDiff => 'A053615', # runs n..0..n
        Max     => 'A000196', # n repeated 2n+1 times, floor(sqrt(N))
        MaxAbs  => 'A000196', #  MaxAbs=Max
        # OEIS-Other: A196199 planepath=Corner,n_start=0 coordinate_type=DiffXY
        # OEIS-Other: A053615 planepath=Corner,n_start=0 coordinate_type=AbsDiff
        # OEIS-Other: A000196 planepath=Corner,n_start=0 coordinate_type=Max
        # OEIS-Other: A000196 planepath=Corner,n_start=0 coordinate_type=MaxAbs

        # Not quite, A053188 has extra initial 0
        # AbsDiff => 'A053188', # distance to nearest square
      },
    };
}
{ package Math::PlanePath::PyramidRows;

  *_NumSeq_Coord_Min_non_decreasing = \&_NumSeq_Coord_Y_increasing;

  # Max==Y and Y is non-decreasing when
  #   step=0 align=any
  #   step=1 align=any
  #   step=2 align=left or centre
  #   step>2 align=left
  sub _NumSeq_Coord_Max_non_decreasing {
    my ($self) = @_;
    return ($self->{'step'} <= 1
            || ($self->{'step'} == 2 && $self->{'align'} eq 'centre')
            || $self->{'align'} eq 'left');
  }

  sub _NumSeq_Coord_MaxAbs_non_decreasing {
    my ($self) = @_;
    return ($self->{'step'} <= 1
            || ($self->{'step'} == 2 && $self->{'align'} eq 'centre'));
  }

  *_NumSeq_Coord_Sum_increasing = \&_NumSeq_Coord_Y_increasing;
  *_NumSeq_Coord_SumAbs_increasing = \&_NumSeq_Coord_Y_increasing;

  sub _NumSeq_Coord_IntXY_min {
    my ($self) = @_;
    return ($self->{'align'} eq 'left'     ? - $self->{'step'}
            : $self->{'align'} eq 'centre' ? - int($self->{'step'}/2)
            : 0);  # right
  }

  sub _NumSeq_Coord_FracXY_max {
    my ($self) = @_;
    return ($self->{'step'} == 0 ? 0 : 1);  # step=0 X=0 frac=0 always
  }
  *_NumSeq_FracXY_max_is_supremum = \&_NumSeq_Coord_FracXY_max;
  sub _NumSeq_Coord_FracXY_integer {
    my ($self) = @_;
    return ($self->{'step'} == 0 ? 1 : 0);  # step=0 X=0 frac=0 always
  }

  sub _NumSeq_Coord_Radius_integer {
    my ($self) = @_;
    return ($self->{'step'} == 0);
  }

  sub _NumSeq_Coord_Y_increasing {
    my ($self) = @_;
    return ($self->{'step'} == 0
            ? 1       # column X=0,Y=N
            : 0);
  }
  *_NumSeq_Coord_DiffYX_increasing = \&_NumSeq_Coord_Y_increasing;
  *_NumSeq_Coord_AbsDiff_increasing = \&_NumSeq_Coord_Y_increasing;
  *_NumSeq_Coord_Max_increasing = \&_NumSeq_Coord_Y_increasing;
  *_NumSeq_Coord_Radius_increasing = \&_NumSeq_Coord_Y_increasing;
  *_NumSeq_Coord_TRadius_increasing = \&_NumSeq_Coord_Y_increasing;
  *_NumSeq_Coord_BitOr_increasing = \&_NumSeq_Coord_Y_increasing;
  *_NumSeq_Coord_BitXor_increasing = \&_NumSeq_Coord_Y_increasing;
  *_NumSeq_Coord_GCD_increasing = \&_NumSeq_Coord_Y_increasing;

  use constant _NumSeq_Coord_Y_non_decreasing => 1; # rows upwards
  *_NumSeq_Coord_X_non_decreasing = \&_NumSeq_Coord_Y_increasing; # X=0 always
  *_NumSeq_Coord_Product_non_decreasing = \&_NumSeq_Coord_Y_increasing; # N*0=0

  # step=0 constant ExperimentalNumerator=0
  sub _NumSeq_Coord_ExperimentalNumerator_max {
    my ($self) = @_;
    return ($self->{'step'} == 0 ? 0 : undef);
  }

  # step=0 has Y=0 so BitAnd=0 always
  *_NumSeq_Coord_BitAnd_max = \&_NumSeq_Coord_ExperimentalNumerator_max;
  *_NumSeq_Coord_BitAnd_non_decreasing = \&_NumSeq_Coord_Y_increasing;

  # cf A050873 GCD(X+1,Y+1) by rows n>=1 k=1..n, x_start=1,y_start=1
  #    A051173 LCM(X+1,Y+1) by rows n>=1 k=1..n, x_start=1,y_start=1
  #
  # Maybe with x_start,y_start to go by rows starting from 1.
  # ExperimentalDenominator   => 'A164306',  # T(n,k) = k/GCD(n,k) n,k>=1 offset=1
  # # OEIS-Catalogue: A164306 planepath=PyramidRows,step=1,x_start=1,y_start=1 coordinate_type=ExperimentalDenominator
  # ExperimentalDenominator => 'A167192',  # T(n,k) = (n-k)/GCD(n,k) n,k>=1 offset=1
  # # OEIS-Catalogue: A167192 planepath=PyramidRows,step=1,x_start=1,y_start=1,align=left coordinate_type=ExperimentalNumerator
  #
  use constant _NumSeq_Coord_oeis_anum =>
    {
     # PyramidRows step=0 is trivial X=0,Y=N
     do {
       my $href = { X        => 'A000004',  # all-zeros
                    Product  => 'A000004',  # all-zeros
                    # OEIS-Other: A000004 planepath=PyramidRows,step=0 coordinate_type=X
                    # OEIS-Other: A000004 planepath=PyramidRows,step=0 coordinate_type=Product
                  };
       ('step=0,align=centre' => $href,
        'step=0,align=right'  => $href,
        'step=0,align=left'   => $href,
       );
     },
     do {
       my $href = { X         => 'A000004',  # all zeros
                    Min       => 'A000004',  # Min=X
                    Y         => 'A001477',  # integers Y=0,1,2,etc
                    Max       => 'A001477',  # Max=Y
                    MaxAbs    => 'A001477',  # MaxAbs=Max
                    Sum       => 'A001477',  # Sum=Y
                    DiffYX    => 'A001477',  # DiffYX=Y
                    DiffXY    => 'A001489',  # negatives 0,-1,-2,etc
                    AbsDiff   => 'A001477',  # AbsDiff=Y
                    Product   => 'A000004',  # Product=0
                    Radius    => 'A001477',  # Radius=Y
                    GCD       => 'A001477',  # GCD=Y
                    RSquared  => 'A000290',  # n^2
                    TRSquared => 'A033428',  # 3*n^2
                    BitAnd    => 'A000004',  # BitAnd=0
                    BitOr     => 'A001477',  # BitOr=Y
                    BitXor    => 'A001477',  # BitXor=Y
                    # OEIS-Other: A000004 planepath=PyramidRows,step=0,n_start=0 coordinate_type=X
                    # OEIS-Other: A000004 planepath=PyramidRows,step=0,n_start=0 coordinate_type=Min
                    # OEIS-Other: A001477 planepath=PyramidRows,step=0,n_start=0 coordinate_type=Y
                    # OEIS-Other: A001477 planepath=PyramidRows,step=0,n_start=0 coordinate_type=Max
                    # OEIS-Other: A001477 planepath=PyramidRows,step=0,n_start=0 coordinate_type=MaxAbs
                    # OEIS-Other: A001477 planepath=PyramidRows,step=0,n_start=0 coordinate_type=Sum
                    # OEIS-Other: A001477 planepath=PyramidRows,step=0,n_start=0 coordinate_type=DiffYX
                    # OEIS-Other: A001489 planepath=PyramidRows,step=0,n_start=0 coordinate_type=DiffXY
                    # OEIS-Other: A001477 planepath=PyramidRows,step=0,n_start=0 coordinate_type=AbsDiff
                    # OEIS-Other: A000004 planepath=PyramidRows,step=0,n_start=0 coordinate_type=Product
                    # OEIS-Other: A001477 planepath=PyramidRows,step=0,n_start=0 coordinate_type=Radius
                    # OEIS-Other: A001489 planepath=PyramidRows,step=0,n_start=0 coordinate_type=DiffXY
                    # OEIS-Other: A000290 planepath=PyramidRows,step=0,n_start=0 coordinate_type=RSquared
                    # OEIS-Other: A033428 planepath=PyramidRows,step=0,n_start=0 coordinate_type=TRSquared
                    # OEIS-Other: A000004 planepath=PyramidRows,step=0,n_start=0 coordinate_type=BitAnd
                    # OEIS-Other: A001477 planepath=PyramidRows,step=0,n_start=0 coordinate_type=BitOr
                    # OEIS-Other: A001477 planepath=PyramidRows,step=0,n_start=0 coordinate_type=BitXor
                  };
       ('step=0,align=centre,n_start=0' => $href,
        'step=0,align=right,n_start=0'  => $href,
        'step=0,align=left,n_start=0'   => $href,
       );
     },

     # PyramidRows step=1
     # cf A050873 GCD triangle starting (1,1) n=1
     #    A051173 LCM triangle starting (1,1) n=1
     #    A003991 X*Y product starting (1,1) n=1
     #    A001316 count of occurrences of n as BitOr
     do {
       my $href =
         { X        => 'A002262',  # 0, 0,1, 0,1,2, etc (Diagonals)
           Min      => 'A002262',  # X<=Y always
           Y        => 'A003056',  # 0, 1,1, 2,2,2, 3,3,3,3 (Diagonals)
           Max      => 'A003056',  #  Max=Y as Y>=X always
           MaxAbs   => 'A003056',  #  MaxAbs=Max as Y>=0 always
           DiffYX   => 'A025581',  # descending N to 0 (Diagonals)
           AbsDiff  => 'A025581',  #   absdiff same
           Sum      => 'A051162',  # triangle X+Y for X=0 to Y inclusive
           SumAbs   => 'A051162',  #   sumabs same
           Product  => 'A079904',
           RSquared => 'A069011',  # triangle X^2+Y^2 for X=0 to Y inclusive
           GCD      => 'A109004',  # same as by diagonals
           BitAnd   => 'A080099',
           BitOr    => 'A080098',
           BitXor   => 'A051933',
         };
       ('step=1,align=centre,n_start=0' => $href,
        'step=1,align=right,n_start=0'  => $href,
       );
       # OEIS-Other: A002262 planepath=PyramidRows,step=1,n_start=0 coordinate_type=X
       # OEIS-Other: A002262 planepath=PyramidRows,step=1,n_start=0 coordinate_type=Min
       # OEIS-Other: A003056 planepath=PyramidRows,step=1,n_start=0 coordinate_type=Y
       # OEIS-Other: A003056 planepath=PyramidRows,step=1,n_start=0 coordinate_type=Max
       # OEIS-Other: A003056 planepath=PyramidRows,step=1,n_start=0 coordinate_type=MaxAbs
       # OEIS-Other: A025581 planepath=PyramidRows,step=1,n_start=0 coordinate_type=DiffYX
       # OEIS-Other: A025581 planepath=PyramidRows,step=1,n_start=0 coordinate_type=AbsDiff
       # OEIS-Other: A051162 planepath=PyramidRows,step=1,n_start=0 coordinate_type=Sum
       # OEIS-Other: A051162 planepath=PyramidRows,step=1,n_start=0 coordinate_type=SumAbs
       # OEIS-Catalogue: A079904 planepath=PyramidRows,step=1,n_start=0 coordinate_type=Product
       # OEIS-Catalogue: A069011 planepath=PyramidRows,step=1,n_start=0 coordinate_type=RSquared
       # OEIS-Other:     A109004 planepath=PyramidRows,step=1,n_start=0 coordinate_type=GCD
       # OEIS-Catalogue: A080099 planepath=PyramidRows,step=1,n_start=0 coordinate_type=BitAnd
       # OEIS-Catalogue: A080098 planepath=PyramidRows,step=1,n_start=0 coordinate_type=BitOr
       # OEIS-Catalogue: A051933 planepath=PyramidRows,step=1,n_start=0 coordinate_type=BitXor

       # OEIS-Other: A002262 planepath=PyramidRows,step=1,align=right,n_start=0 coordinate_type=X
       # OEIS-Other: A003056 planepath=PyramidRows,step=1,align=right,n_start=0 coordinate_type=Y
       # OEIS-Other: A025581 planepath=PyramidRows,step=1,align=right,n_start=0 coordinate_type=DiffYX
       # OEIS-Other: A025581 planepath=PyramidRows,step=1,align=right,n_start=0 coordinate_type=AbsDiff
       # OEIS-Other: A051162 planepath=PyramidRows,step=1,align=right,n_start=0 coordinate_type=Sum
       # OEIS-Other: A051162 planepath=PyramidRows,step=1,align=right,n_start=0 coordinate_type=SumAbs
       # OEIS-Other: A079904 planepath=PyramidRows,step=1,align=right,n_start=0 coordinate_type=Product
       # OEIS-Other: A069011 planepath=PyramidRows,step=1,align=right,n_start=0 coordinate_type=RSquared
       # OEIS-Other: A080099 planepath=PyramidRows,step=1,align=right,n_start=0 coordinate_type=BitAnd
       # OEIS-Other: A080098 planepath=PyramidRows,step=1,align=right,n_start=0 coordinate_type=BitOr
       # OEIS-Other: A051933 planepath=PyramidRows,step=1,align=right,n_start=0 coordinate_type=BitXor
     },

     # 'step=1,align=left,n_start=0' =>
     # { ExperimentalAbsX => 'A025581', # descending runs n to 0
     # },

     # PyramidRows step=2
     'step=2,align=centre,n_start=0' =>
     { X       => 'A196199',  # runs -n to n
       Min     => 'A196199',  # X since X<Y
       Y       => 'A000196',  # n appears 2n+1 times, starting 0
       Max     => 'A000196',  # Y since X<Y
       Sum     => 'A053186',  # runs 0 to 2n
       ExperimentalAbsX    => 'A053615',  # runs n to 0 to n
       # OEIS-Catalogue: A196199 planepath=PyramidRows,n_start=0 coordinate_type=X
       # OEIS-Other:     A196199 planepath=PyramidRows,n_start=0 coordinate_type=Min
       # OEIS-Catalogue: A000196 planepath=PyramidRows,n_start=0 coordinate_type=Y
       # OEIS-Other:     A000196 planepath=PyramidRows,n_start=0 coordinate_type=Max
       # OEIS-Other:     A053186 planepath=PyramidRows,n_start=0 coordinate_type=Sum
       # OEIS-Other:     A053615 planepath=PyramidRows,n_start=0 coordinate_type=ExperimentalAbsX

       # # Not quite, extra initial 0
       # DiffYX  => 'A068527',  # dist to next square
       # AbsDiff => 'A068527',  # same since Y-X>0
     },
     'step=2,align=right,n_start=0' =>
     { X       => 'A053186',  # runs 0 to 2n
       Y       => 'A000196',  # n appears 2n+1 times, starting 0
       DiffXY  => 'A196199',  # runs -n to n
       AbsDiff => 'A053615',  # n..0..n, distance to pronic
       # OEIS-Other: A053186 planepath=PyramidRows,align=right,n_start=0 coordinate_type=X
       # OEIS-Other: A000196 planepath=PyramidRows,align=right,n_start=0 coordinate_type=Y
       # OEIS-Other: A196199 planepath=PyramidRows,align=right,n_start=0 coordinate_type=DiffXY
       # OEIS-Other: A053615 planepath=PyramidRows,align=right,n_start=0 coordinate_type=AbsDiff
     },
     'step=2,align=left,n_start=0' =>
     { X    => '',  # runs -2n+1 to 0
       Y    => 'A000196',  # n appears 2n+1 times, starting 0
       Sum  => 'A196199',  # -n to n
       # OEIS-Other: A000196 planepath=PyramidRows,align=left,n_start=0 coordinate_type=Y
       # OEIS-Other: A196199 planepath=PyramidRows,align=left,n_start=0 coordinate_type=Sum

       # Not quite, A068527 doesn't have two initial 0s
       # ExperimentalAbsX => 'A068527',  # dist to next square
       # # OEIS-Other: A068527 planepath=PyramidRows,align=left,n_start=0 coordinate_type=ExperimentalAbsX
     },

     # PyramidRows step=3
     do {
       my $href =
         { Y   => 'A180447',  # n appears 3n+1 times, starting 0
         };
       ('step=3,align=centre,n_start=0' => $href,
        'step=3,align=right,n_start=0'  => $href,
       );
       # OEIS-Catalogue: A180447 planepath=PyramidRows,step=3,n_start=0 coordinate_type=Y
       # OEIS-Other:     A180447 planepath=PyramidRows,step=3,align=right,n_start=0 coordinate_type=Y
     },
     'step=3,align=left,n_start=0' =>
     { Y   => 'A180447',  # n appears 3n+1 times, starting 0
       Max => 'A180447',  # Y since X<Y
     },
     # OEIS-Other: A180447 planepath=PyramidRows,step=3,align=left,n_start=0 coordinate_type=Y
     # OEIS-Other: A180447 planepath=PyramidRows,step=3,align=left,n_start=0 coordinate_type=Max

     # PyramidRows step=4
     'step=4,align=right,n_start=0' =>
     { X   => 'A060511',  # amount exceeding hexagonal number
     },
     # OEIS-Catalogue: A060511 planepath=PyramidRows,step=4,align=right,n_start=0 coordinate_type=X
    };
}
{ package Math::PlanePath::PyramidSides;
  use constant _NumSeq_Coord_filling_type => 'half';
  use constant _NumSeq_Coord_SumAbs_non_decreasing => 1;

  use constant _NumSeq_Coord_oeis_anum =>
    { 'n_start=0' =>
      { X      => 'A196199',  # runs -n to n
        SumAbs => 'A000196',  # n appears 2n+1 times, starting 0
        # OEIS-Other: A196199 planepath=PyramidSides,n_start=0 coordinate_type=X
        # OEIS-Other: A000196 planepath=PyramidSides,n_start=0 coordinate_type=SumAbs

        ExperimentalAbsX   => 'A053615',  # runs n to 0 to n
        # OEIS-Other: A053615 planepath=PyramidSides,n_start=0 coordinate_type=ExperimentalAbsX
      },
    };
}
{ package Math::PlanePath::CellularRule;

  # single cell
  # 111 -> any
  # 110 -> any
  # 101 -> any
  # 100 -> 0 initial
  # 011 -> any
  # 010 -> 0 initial
  # 001 -> 0 initial
  # 000 -> 0
  # so (rule & 0x17) == 0
  #
  # right 2 cell line 0x54,74,D4,F4
  # 111 -> any
  # 110 -> 1
  # 101 -> any
  # 100 -> 1
  # 011 -> 0
  # 010 -> 1
  # 001 -> 0
  # 000 -> 0
  # so (rule & 0x5F) == 0x54
  #
  sub _NumSeq_Coord_X_increasing {
    my ($self) = @_;
    ### CellularRule _NumSeq_Coord_X_increasing() rule: $self->{'rule'}
    return (($self->{'rule'} & 0x17) == 0    # single cell only
            ? 1
            : 0);
  }
  sub _NumSeq_Coord_Sum_increasing {
    my ($self) = @_;
    return (($self->{'rule'} & 0x17) == 0        # single cell only
            || ($self->{'rule'} & 0x5F) == 0x54  # right line 2
            ? 1
            : 0);
  }
  *_NumSeq_Coord_Min_increasing = \&_NumSeq_Coord_Sum_increasing; # Min=X
  *_NumSeq_Coord_SumAbs_increasing = \&_NumSeq_Coord_Sum_increasing;
  *_NumSeq_Coord_Radius_increasing = \&_NumSeq_Coord_Sum_increasing;
  *_NumSeq_Coord_TRadius_increasing = \&_NumSeq_Coord_Radius_increasing;

  *_NumSeq_Coord_Y_increasing = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_Max_increasing = \&_NumSeq_Coord_X_increasing; # Max==Y
  *_NumSeq_Coord_Product_increasing = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_DiffXY_increasing = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_DiffYX_increasing = \&_NumSeq_Coord_X_increasing;
  *_NumSeq_Coord_AbsDiff_increasing = \&_NumSeq_Coord_X_increasing;
  use constant _NumSeq_Coord_MaxAbs_non_decreasing => 1; # -Y<=X<=Y so MaxAbs=Y

  sub _NumSeq_Coord_X_non_decreasing {
    my ($self) = @_;
    return (($self->{'rule'} & 0x17) == 0        # single cell only
            || ($self->{'rule'} & 0x5F) == 0x54  # right line 2
            ? 1
            : 0);
  }
  *_NumSeq_Coord_Min_non_decreasing = \&_NumSeq_Coord_X_non_decreasing; # Min=X
  sub _NumSeq_Coord_Product_non_decreasing {
    my ($self) = @_;
    return (($self->{'rule'} & 0x17) == 0        # single cell only
            || ($self->{'rule'} & 0x5F) == 0x54  # right line 2
            ? 1
            : 0);
  }

  use constant _NumSeq_Coord_Y_non_decreasing => 1; # rows upwards
  use constant _NumSeq_Coord_Max_non_decreasing => 1; # Max==Y

  sub _NumSeq_Coord_BitAnd_max {
    my ($self) = @_;
    return (($self->{'rule'} & 0x17) == 0        # single cell only
            || ($self->{'rule'} & 0x5F) == 0x54  # right line 2
            ? 0
            : undef);
  }

  sub _NumSeq_Coord_ExperimentalParity_max {
    my ($self) = @_;
    return (($self->{'rule'} & 0x17) == 0    # single cell only
            ? 0                              # X=0,Y=0 even

            : 1);
  }
}
{ package Math::PlanePath::CellularRule::OneTwo;
  sub _NumSeq_Coord_Sum_increasing {
    my ($self) = @_;
    return ($self->{'sign'} > 0);  # when to the right
  }
  *_NumSeq_Coord_SumAbs_increasing = \&_NumSeq_Coord_Sum_increasing;
  *_NumSeq_Coord_Radius_increasing = \&_NumSeq_Coord_Sum_increasing;
  *_NumSeq_Coord_TRadius_increasing = \&_NumSeq_Coord_Radius_increasing;

  sub _NumSeq_Coord_X_non_decreasing {
    my ($self) = @_;
    return ($self->{'sign'} > 0); # yes when to the right
  }
  *_NumSeq_Coord_Min_non_decreasing = \&_NumSeq_Coord_X_non_decreasing; # Min=X
  *_NumSeq_Coord_Product_non_decreasing = \&_NumSeq_Coord_X_non_decreasing;
  *_NumSeq_Coord_BitAnd_non_decreasing = \&_NumSeq_Coord_X_non_decreasing;
  *_NumSeq_Coord_BitOr_non_decreasing = \&_NumSeq_Coord_X_non_decreasing;

  use constant _NumSeq_Coord_Y_non_decreasing => 1;   # rows upwards
  use constant _NumSeq_Coord_Max_non_decreasing => 1; # Max=Y
  use constant _NumSeq_Coord_MaxAbs_non_decreasing => 1; # -Y<=X<=Y so MaxAbs=Y
  sub _NumSeq_Coord_MinAbs_non_decreasing {
    my ($self) = @_;
    return ($self->{'sign'} > 0); # yes when to the right
  }

  sub _NumSeq_Coord_IntXY_min {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? -1 : 0);
  }

  sub _NumSeq_Coord_BitOr_max {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? 1 : undef);
  }
  use constant _NumSeq_Coord_BitXor_max => 1;

  use constant _NumSeq_Coord_oeis_anum =>
    { 'align=left,n_start=0' =>
      { Y      => 'A004396', # one even two odd
        Max    => 'A004396', # Max=Y
        SumAbs => 'A131452', # a(3n)=4n, a(3n+1)=4n+2, a(3n+2)=4n+1.
        DiffYX => 'A131452', # X<0 so Y-X=abs(Y)+abs(X)
        # OEIS-Catalogue: A004396 planepath=CellularRule,rule=6,n_start=0 coordinate_type=Y
        # OEIS-Other:     A004396 planepath=CellularRule,rule=166,n_start=0 coordinate_type=Max
        # OEIS-Catalogue: A131452 planepath=CellularRule,rule=6,n_start=0 coordinate_type=SumAbs
        # OEIS-Other:     A131452 planepath=CellularRule,rule=166,n_start=0 coordinate_type=SumAbs

        # Maybe, but OFFSET in fractions?
        # Sum    => 'A022003', # 1/999 decimal 0,0,1,0,0,1
        # # OEIS-Other:     A022003 planepath=CellularRule,rule=166,n_start=0 coordinate_type=Sum
      },

      'align=right,n_start=0' =>
      { X      => 'A004523', # 0,0,1,2,2,3 two even, one odd
        Min    => 'A004523', # Min=X
        BitAnd => 'A004523', # BitAnd=X
        Y      => 'A004396', # one even two odd
        Max    => 'A004396', # Max=Y
        BitOr  => 'A004396', # BitOr=Y
        SumAbs => 'A004773', # 0,1,2 mod 4
        ExperimentalPairsXY => 'A002264',  # triples 0,0,0, 1,1,1, etc

        # OEIS-Catalogue: A004523 planepath=CellularRule,rule=20,n_start=0 coordinate_type=X
        # OEIS-Other:     A004523 planepath=CellularRule,rule=20,n_start=0 coordinate_type=Min
        # OEIS-Other:     A004523 planepath=CellularRule,rule=20,n_start=0 coordinate_type=BitAnd
        # OEIS-Other:     A004396 planepath=CellularRule,rule=20,n_start=0 coordinate_type=Y
        # OEIS-Other:     A004396 planepath=CellularRule,rule=180,n_start=0 coordinate_type=Max
        # OEIS-Other:     A004396 planepath=CellularRule,rule=180,n_start=0 coordinate_type=BitOr
        # OEIS-Catalogue: A004773 planepath=CellularRule,rule=20,n_start=0 coordinate_type=SumAbs
        # OEIS-Other:     A004773 planepath=CellularRule,rule=180,n_start=0 coordinate_type=SumAbs
        # OEIS-Other:     A002264 planepath=CellularRule,rule=20,n_start=0 coordinate_type=ExperimentalPairsXY
      },
    };
}
{ package Math::PlanePath::CellularRule::Two;
  sub _NumSeq_Coord_Sum_increasing {
    my ($self) = @_;
    return ($self->{'sign'} > 0);  # when to the right
  }
  *_NumSeq_Coord_SumAbs_increasing = \&_NumSeq_Coord_Sum_increasing;
  *_NumSeq_Coord_Radius_increasing = \&_NumSeq_Coord_Sum_increasing;
  *_NumSeq_Coord_TRadius_increasing = \&_NumSeq_Coord_Radius_increasing;

  sub _NumSeq_Coord_X_non_decreasing {
    my ($self) = @_;
    return ($self->{'sign'} > 0); # yes when to the right
  }
  *_NumSeq_Coord_Min_non_decreasing = \&_NumSeq_Coord_X_non_decreasing; # Min=X
  *_NumSeq_Coord_Product_non_decreasing = \&_NumSeq_Coord_X_non_decreasing;
  *_NumSeq_Coord_BitAnd_non_decreasing = \&_NumSeq_Coord_X_non_decreasing;
  *_NumSeq_Coord_BitOr_non_decreasing = \&_NumSeq_Coord_X_non_decreasing;

  use constant _NumSeq_Coord_Y_non_decreasing => 1;   # rows upwards
  use constant _NumSeq_Coord_Max_non_decreasing => 1; # Max=Y
  use constant _NumSeq_Coord_MaxAbs_non_decreasing => 1; # -Y<=X<=Y so MaxAbs=Y
  sub _NumSeq_Coord_MinAbs_non_decreasing {
    my ($self) = @_;
    return ($self->{'sign'} > 0); # yes when to the right
  }

  sub _NumSeq_Coord_IntXY_min {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? -1 : 0);
  }

  sub _NumSeq_Coord_BitOr_max {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? 1 : undef);
  }
  use constant _NumSeq_Coord_BitXor_max => 1;

  use constant _NumSeq_Coord_oeis_anum =>
    {
     'align=left,n_start=1' =>
     { Y => 'A076938',  # 0,1,1,2,2,3,3,...
       # OEIS-Other: A076938 planepath=CellularRule,rule=14 coordinate_type=Y
       # OEIS-Other: A076938 planepath=CellularRule,rule=174 coordinate_type=Y
     },
     'align=right,n_start=1' =>
     { Y => 'A076938',  # 0,1,1,2,2,3,3,...
       # OEIS-Other: A076938 planepath=CellularRule,rule=84 coordinate_type=Y
       # OEIS-Other: A076938 planepath=CellularRule,rule=116 coordinate_type=Y
     },
    };
}
{ package Math::PlanePath::CellularRule::Line;
  sub _NumSeq_Coord_Radius_integer {
    my ($path) = @_;
    # centre Radius=Y so integer, otherwise Radius=sqrt(2)*Y not integer
    return ($path->{'align'} eq 'centre');
  }

  use constant _NumSeq_Coord_Y_increasing => 1;       # line upwards
  use constant _NumSeq_Coord_Max_increasing => 1;     # Max=Y
  use constant _NumSeq_Coord_Radius_increasing => 1;  # line upwards
  use constant _NumSeq_Coord_TRadius_increasing => 1; # line upwards
  sub _NumSeq_Coord_TRadius_integer {
    my ($path) = @_;
    return ($path->{'sign'} != 0); # left or right sloping
  }

  sub _NumSeq_Coord_X_increasing {
    my ($path) = @_;
    return ($path->{'sign'} >= 1); # X=Y diagonal
  }
  sub _NumSeq_Coord_X_non_decreasing {
    my ($path) = @_;
    return ($path->{'sign'} >= 0); # X=0 vertical or X=Y diagonal
  }
  *_NumSeq_Coord_Min_non_decreasing = \&_NumSeq_Coord_X_non_decreasing; # Min=X
  *_NumSeq_Coord_Min_increasing = \&_NumSeq_Coord_X_increasing; # Min=X

  sub _NumSeq_Coord_Sum_increasing {
    my ($path) = @_;
    return ($path->{'sign'} == -1
            ? 0   # X=-Y so X+Y=0
            : 1); # X=0 so X+Y=Y, or X=Y so X+Y=2Y
  }
  use constant _NumSeq_Coord_Sum_non_decreasing => 1; # line upwards
  use constant _NumSeq_Coord_SumAbs_increasing => 1;  # line upwards

  sub _NumSeq_Coord_Product_increasing {
    my ($path) = @_;
    return ($path->{'sign'} > 0
            ? 1   # X=Y so X*Y=Y^2
            : 0); # X=0 so X*Y=0, or X=-Y so X*Y=-(Y^2)
  }
  sub _NumSeq_Coord_Product_non_decreasing {
    my ($path) = @_;
    return ($path->{'sign'} >= 0
            ? 1   # X=Y so X*Y=Y^2
            : 0); # X=0 so X*Y=0, or X=-Y so X*Y=-(Y^2)
  }

  # sign=1 X=Y so X-Y=0 always, non-decreasing
  # sign=0 X=0 so Y-X=Y, increasing
  # sign=-1 X=-Y so Y-X=2*Y, increasing
  sub _NumSeq_Coord_DiffXY_non_decreasing {
    my ($path) = @_;
    return ($path->{'sign'} == 1 ? 1  # X-Y=0 always
            : 0);
  }
  sub _NumSeq_Coord_DiffYX_increasing {
    my ($path) = @_;
    return ($path->{'sign'} == 1 ? 0 : 1);
  }
  *_NumSeq_Coord_AbsDiff_increasing = \&_NumSeq_Coord_DiffYX_increasing;
  use constant _NumSeq_Coord_DiffYX_non_decreasing  => 1; # Y-X >= 0 always
  use constant _NumSeq_Coord_AbsDiff_non_decreasing => 1; # Y-X >= 0 always
  use constant _NumSeq_Coord_GCD_increasing => 1; # GCD==Y

  use constant _NumSeq_Coord_MaxAbs_non_decreasing => 1; # -Y<=X<=Y so MaxAbs=Y
  sub _NumSeq_Coord_ExperimentalParity_max {
    my ($path) = @_;
    return ($path->{'align'} eq 'centre' ? 1 : 0);
  }

  sub _NumSeq_Coord_ExperimentalNumerator_min {
    my ($path) = @_;
    return ($path->{'align'} eq 'left'
            ? -1
            : 0);
  }
  sub _NumSeq_Coord_ExperimentalNumerator_max {
    my ($path) = @_;
    return ($path->{'align'} eq 'right'
            ? 1   # right X=Y so 1/1 except for 0/0
            : 0);
  }
  sub _NumSeq_Coord_ExperimentalNumerator_non_decreasing {
    my ($path) = @_;
    return ($path->{'align'} ne 'left');
  }

  # ExperimentalDenominator_min => 0; # 0/0 at n_start()
  use constant _NumSeq_Coord_ExperimentalDenominator_max => 1;
  use constant _NumSeq_Coord_ExperimentalDenominator_non_decreasing => 1;

  # left Y bitand -Y twos-complement gives mask of low 1-bits
  sub _NumSeq_Coord_BitAnd_non_decreasing {
    my ($path) = @_;
    return ($path->{'align'} ne 'left'); # centre BitAnd=0, right BitAnd=Y
  }
  sub _NumSeq_Coord_BitAnd_increasing {
    my ($path) = @_;
    return ($path->{'align'} eq 'right'); # right BitAnd=Y
  }

  # left Y bitor -Y twos-complement gives all-1s above low 0-bits
  sub _NumSeq_Coord_BitOr_increasing {
    my ($path) = @_;
    return ($path->{'align'} ne 'left'); # centre,right BitOr = Y
  }

  sub _NumSeq_Coord_BitXor_min {
    my ($path) = @_;
    return ($path->{'align'} eq 'left'
            ? undef
            : 0); # right X=Y so BitXor=0 always, centre X=0 so BitXor=Y
  }
  sub _NumSeq_Coord_BitXor_max {
    my ($path) = @_;
    return ($path->{'align'} eq 'centre'
            ? undef  # centre X=0 BitXor=Y
            : 0);    # right X=Y so BitXor=0 always, left negative
  }
  sub _NumSeq_Coord_BitXor_increasing {
    my ($path) = @_;
    return ($path->{'align'} eq 'centre'); # centre BitXor=Y
  }

  # and maximum 0/0=infinity
  sub _NumSeq_Coord_IntXY_min {
    my ($path) = @_;
    return ($path->{'align'} eq 'right'
            ? 1  # right X=Y so X/Y=1 always
            : $path->{'align'} eq 'left'
            ? -1 # left X=-Y so X/Y=-1 always
            : 0);
  }

  use constant _NumSeq_Coord_FracXY_min => 0; # X=0,+Y,-Y so frac=0
  use constant _NumSeq_Coord_FracXY_max => 0;
  use constant _NumSeq_Coord_FracXY_integer => 1;
  use constant _NumSeq_FracXY_min_is_infimum => 0;
  use constant _NumSeq_FracXY_max_is_supremum => 0;

  use constant _NumSeq_Coord_oeis_anum =>
    { 'align=left,n_start=0' =>
      { X         => 'A001489',  # integers negative X=0,-1,-2,etc
        Min       => 'A001489',  # Min=X
        Y         => 'A001477',  # integers Y=0,1,2,etc
        Max       => 'A001477',  # Max=Y
        Sum       => 'A000004',  # all zeros
        DiffYX    => 'A005843',  # even 0,2,4,etc
        RSquared  => 'A001105',  # 2*n^2
        TRSquared => 'A016742',  # 4*n^2
        # OEIS-Other: A001489 planepath=CellularRule,rule=2,n_start=0 coordinate_type=X
        # OEIS-Other: A001489 planepath=CellularRule,rule=2,n_start=0 coordinate_type=Min
        # OEIS-Other: A001477 planepath=CellularRule,rule=2,n_start=0 coordinate_type=Y
        # OEIS-Other: A001477 planepath=CellularRule,rule=2,n_start=0 coordinate_type=Max
        # OEIS-Other: A000004 planepath=CellularRule,rule=2,n_start=0 coordinate_type=Sum
        # OEIS-Other: A005843 planepath=CellularRule,rule=2,n_start=0 coordinate_type=DiffYX
        # OEIS-Other: A001105 planepath=CellularRule,rule=2,n_start=0 coordinate_type=RSquared
        # OEIS-Other: A016742 planepath=CellularRule,rule=2,n_start=0 coordinate_type=TRSquared
      },

      'align=right,n_start=0' =>
      { X         => 'A001477',  # integers Y=0,1,2,etc
        Min       => 'A001477',  # Min=X
        Y         => 'A001477',  # integers Y=0,1,2,etc
        Max       => 'A001477',  # Max=Y
        Sum       => 'A005843',  # even 0,2,4,etc
        DiffYX    => 'A000004',  # all zeros
        DiffXY    => 'A000004',  # all zeros
        RSquared  => 'A001105',  # 2*n^2
        TRSquared => 'A016742',  # 4*n^2
        ExperimentalPairsXY => 'A004526', # 0,0,1,1,2,2,etc cf Math::NumSeq::Runs
        # OEIS-Other: A001477 planepath=CellularRule,rule=16,n_start=0 coordinate_type=X
        # OEIS-Other: A001477 planepath=CellularRule,rule=16,n_start=0 coordinate_type=Min
        # OEIS-Other: A001477 planepath=CellularRule,rule=16,n_start=0 coordinate_type=Y
        # OEIS-Other: A001477 planepath=CellularRule,rule=16,n_start=0 coordinate_type=Max
        # OEIS-Other: A005843 planepath=CellularRule,rule=16,n_start=0 coordinate_type=Sum
        # OEIS-Other: A000004 planepath=CellularRule,rule=16,n_start=0 coordinate_type=DiffYX
        # OEIS-Other: A000004 planepath=CellularRule,rule=16,n_start=0 coordinate_type=DiffXY
        # OEIS-Other: A001105 planepath=CellularRule,rule=16,n_start=0 coordinate_type=RSquared
        # OEIS-Other: A016742 planepath=CellularRule,rule=16,n_start=0 coordinate_type=TRSquared
        # OEIS-Other: A004526 planepath=CellularRule,rule=16,n_start=0 coordinate_type=ExperimentalPairsXY
      },

      # same as PyramidRows step=0
      'align=centre,n_start=0' =>
      Math::PlanePath::PyramidRows->_NumSeq_Coord_oeis_anum()->{'step=0,align=centre,n_start=0'},
      # OEIS-Other: A000004 planepath=CellularRule,rule=4,n_start=0 coordinate_type=X
      # OEIS-Other: A000004 planepath=CellularRule,rule=4,n_start=0 coordinate_type=Min
      # OEIS-Other: A001477 planepath=CellularRule,rule=4,n_start=0 coordinate_type=Y
      # OEIS-Other: A001477 planepath=CellularRule,rule=4,n_start=0 coordinate_type=Max
      # OEIS-Other: A001477 planepath=CellularRule,rule=4,n_start=0 coordinate_type=Sum
      # OEIS-Other: A001477 planepath=CellularRule,rule=4,n_start=0 coordinate_type=DiffYX
      # OEIS-Other: A001489 planepath=CellularRule,rule=4,n_start=0 coordinate_type=DiffXY
      # OEIS-Other: A001477 planepath=CellularRule,rule=4,n_start=0 coordinate_type=AbsDiff
      # OEIS-Other: A001477 planepath=CellularRule,rule=4,n_start=0 coordinate_type=Radius
      # OEIS-Other: A001489 planepath=CellularRule,rule=4,n_start=0 coordinate_type=DiffXY
      # OEIS-Other: A000290 planepath=CellularRule,rule=4,n_start=0 coordinate_type=RSquared
      # OEIS-Other: A033428 planepath=CellularRule,rule=4,n_start=0 coordinate_type=TRSquared
    };

  # CellularRule starts i=1 value=0, but A000027 is OFFSET=1 value=1
  # } elsif ($planepath_object->isa('Math::PlanePath::CellularRule::Line')) {
  #   # for all "rule" parameter values
  #   if ($coordinate_type eq 'Y'
  #       || ($planepath_object->{'sign'} == 0
  #           && ($coordinate_type eq 'Sum'
  #               || $coordinate_type eq 'DiffYX'
  #               || $coordinate_type eq 'AbsDiff'
  #               || $coordinate_type eq 'Radius'))) {
  #     return 'A000027'; # natural numbers 1,2,3
  #     # OEIS-Other: A000027 planepath=CellularRule,rule=2 coordinate_type=Y
  #     # OEIS-Other: A000027 planepath=CellularRule,rule=4 coordinate_type=Sum
  #     # OEIS-Other: A000027 planepath=CellularRule,rule=4 coordinate_type=DiffYX
  #     # OEIS-Other: A000027 planepath=CellularRule,rule=4 coordinate_type=AbsDiff
  #     # OEIS-Other: A000027 planepath=CellularRule,rule=4 coordinate_type=Radius
  #   }
}
{ package Math::PlanePath::CellularRule::OddSolid;
  use constant _NumSeq_Coord_Y_non_decreasing => 1; # rows upwards
  use constant _NumSeq_Coord_Max_non_decreasing => 1; # Max=Y
  use constant _NumSeq_Coord_MaxAbs_non_decreasing => 1; # -Y<=X<=Y so MaxAbs=Y
  use constant _NumSeq_Coord_ExperimentalParity_max => 0; # always even points
}
{ package Math::PlanePath::CellularRule54;
  use constant _NumSeq_Coord_Y_non_decreasing => 1; # rows upwards
  use constant _NumSeq_Coord_Max_non_decreasing => 1; # Max=Y
  use constant _NumSeq_Coord_MaxAbs_non_decreasing => 1; # -Y<=X<=Y so MaxAbs=Y
  use constant _NumSeq_Coord_IntXY_min => -1;
}
{ package Math::PlanePath::CellularRule57;
  use constant _NumSeq_Coord_Y_non_decreasing => 1; # rows upwards
  use constant _NumSeq_Coord_Max_non_decreasing => 1; # Max=Y
  use constant _NumSeq_Coord_MaxAbs_non_decreasing => 1; # -Y<=X<=Y so MaxAbs=Y
  use constant _NumSeq_Coord_IntXY_min => -1;
}
{ package Math::PlanePath::CellularRule190;
  use constant _NumSeq_Coord_Y_non_decreasing => 1; # rows upwards
  use constant _NumSeq_Coord_Max_non_decreasing => 1; # Max=Y
  use constant _NumSeq_Coord_MaxAbs_non_decreasing => 1; # -Y<=X<=Y so MaxAbs=Y
  use constant _NumSeq_Coord_IntXY_min => -1;
}
{ package Math::PlanePath::UlamWarburton;
  use constant _NumSeq_Coord_filling_type => 'plane';
  use constant _NumSeq_Coord_ExperimentalLeafDistance_max => 4;
}
{ package Math::PlanePath::UlamWarburtonQuarter;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
  use constant _NumSeq_Coord_ExperimentalLeafDistance_max => 4;
  use constant _NumSeq_Coord_ExperimentalParity_max => 0;  # even always
}
{ package Math::PlanePath::DiagonalRationals;
  use constant _NumSeq_Coord_Sum_non_decreasing => 1; # X+Y diagonals
  use constant _NumSeq_Coord_SumAbs_non_decreasing => 1; # X+Y diagonals
  use constant _NumSeq_Coord_BitAnd_min => 0;  # at X=1,Y=2

  use constant _NumSeq_Coord_oeis_anum =>
    { 'direction=down,n_start=1' =>
      { X           => 'A020652',  # numerators
        Y           => 'A020653',  # denominators
        ExperimentalNumerator   => 'A020652',  # ExperimentalNumerator=X
        ExperimentalDenominator => 'A020653',  # ExperimentalDenominator=Y
        # OEIS-Catalogue: A020652 planepath=DiagonalRationals coordinate_type=X
        # OEIS-Catalogue: A020653 planepath=DiagonalRationals coordinate_type=Y
        # OEIS-Other:     A020652 planepath=DiagonalRationals coordinate_type=ExperimentalNumerator
        # OEIS-Other:     A020653 planepath=DiagonalRationals coordinate_type=ExperimentalDenominator

        # Not quite, A038567 has OFFSET=0 to include 0/1
        # Sum    => 'A038567', # num+den, is den of fractions X/Y <= 1
        # SumAbs => 'A038567'
      },
      'direction=down,n_start=0' =>
      { AbsDiff => 'A157806', # abs(num-den), OFFSET=0
        # OEIS-Other: A157806 planepath=DiagonalRationals,n_start=0 coordinate_type=AbsDiff
      },

      'direction=up,n_start=1' =>
      { X           => 'A020653',  # transposed is denominators
        Y           => 'A020652',  # transposed is numerators
        ExperimentalNumerator   => 'A020653',  # ExperimentalNumerator=X
        ExperimentalDenominator => 'A020652',  # ExperimentalDenominator=Y
        # OEIS-Other: A020652 planepath=DiagonalRationals,direction=up coordinate_type=Y
        # OEIS-Other: A020653 planepath=DiagonalRationals,direction=up coordinate_type=X
        # OEIS-Other: A020653 planepath=DiagonalRationals,direction=up coordinate_type=ExperimentalNumerator
        # OEIS-Other: A020652 planepath=DiagonalRationals,direction=up coordinate_type=ExperimentalDenominator

        # Not quite, A038567 has OFFSET=0 to include 0/1
        # Sum => 'A038567', # num+den, is den of fractions X/Y <= 1
      },
      'direction=up,n_start=0' =>
      { AbsDiff => 'A157806', # abs(num-den), OFFSET=0
        # OEIS-Other: A157806 planepath=DiagonalRationals,direction=up,n_start=0 coordinate_type=AbsDiff
      },
    };
}
{ package Math::PlanePath::FactorRationals;
  use constant _NumSeq_Coord_BitAnd_min => 0;  # at X=1,Y=2

  use constant _NumSeq_Coord_oeis_anum =>
    { 'factor_coding=even/odd' =>
      { X       => 'A071974',  # numerators
        Y       => 'A071975',  # denominators
        Product => 'A019554',  # replace squares by their root
        # OEIS-Catalogue: A071974 planepath=FactorRationals coordinate_type=X
        # OEIS-Catalogue: A071975 planepath=FactorRationals coordinate_type=Y
        # OEIS-Catalogue: A019554 planepath=FactorRationals coordinate_type=Product
      },
      'factor_coding=odd/even' =>
      { X       => 'A071975',  # denominators
        Y       => 'A071974',  # numerators
        Product => 'A019554',  # replace squares by their root
        # OEIS-Other: A071975 planepath=FactorRationals,factor_coding=odd/even coordinate_type=X
        # OEIS-Other: A071974 planepath=FactorRationals,factor_coding=odd/even coordinate_type=Y
        # OEIS-Other: A019554 planepath=FactorRationals,factor_coding=odd/even coordinate_type=Product
      },
    };
}
{ package Math::PlanePath::GcdRationals;
  use constant _NumSeq_Coord_BitAnd_min => 0;  # at X=1,Y=2

  use constant _NumSeq_Coord_oeis_anum =>
    { 'pairs_order=rows' =>
      { X => 'A226314',
        Y => 'A054531',  # T(n,k) = n/GCD(n,k), being denominators
        # OEIS-Catalogue: A226314 planepath=GcdRationals coordinate_type=X
        # OEIS-Catalogue: A054531 planepath=GcdRationals coordinate_type=Y
      },
      'pairs_order=rows_reverse' =>
      { Y => 'A054531',  # same
        # OEIS-Other: A054531 planepath=GcdRationals,pairs_order=rows coordinate_type=Y
      },
    };
}
{ package Math::PlanePath::CoprimeColumns;
  use constant _NumSeq_Coord_X_non_decreasing         => 1; # columns across
  use constant _NumSeq_Coord_ExperimentalNumerator_non_decreasing => 1; # ExperimentalNumerator==X
  use constant _NumSeq_Coord_Max_non_decreasing       => 1; # Max==X
  use constant _NumSeq_Coord_IntXY_min => 1; # octant Y<=X so X/Y>=1
  use constant _NumSeq_Coord_BitAnd_min => 0;  # at X=2,Y=1

  use constant _NumSeq_Coord_oeis_anum =>
    { 'direction=up,n_start=0' =>
      { X      => 'A038567',  # fractions denominator
        Max    => 'A038567',  #  Max=X since Y <= X
        MaxAbs => 'A038567',  #  MaxAbs=Max
        # OEIS-Catalogue: A038567 planepath=CoprimeColumns coordinate_type=X
        # OEIS-Other:     A038567 planepath=CoprimeColumns coordinate_type=Max
        # OEIS-Other:     A038567 planepath=CoprimeColumns coordinate_type=MaxAbs
      },

      'direction=up,n_start=0,i_start=1' =>
      { DiffXY => 'A020653', # diagonals denominators, starting N=1
        # OEIS-Other: A020653 planepath=CoprimeColumns coordinate_type=DiffXY i_start=1
      },

      'direction=up,n_start=1' =>
      { Y      => 'A038566',  # fractions numerator
        Min    => 'A038566',  #  Min=Y since Y <= X
        MinAbs => 'A038566',  #  MinAbs=Min
        # OEIS-Catalogue: A038566 planepath=CoprimeColumns,n_start=1 coordinate_type=Y
        # OEIS-Other:     A038566 planepath=CoprimeColumns,n_start=1 coordinate_type=Min
        # OEIS-Other:     A038566 planepath=CoprimeColumns,n_start=1 coordinate_type=MinAbs
      },
    };
}
{ package Math::PlanePath::DivisibleColumns;
  use constant _NumSeq_Coord_X_non_decreasing => 1; # columns across

  sub _NumSeq_Coord_IntXY_min {
    my ($self) = @_;
    return ($self->{'proper'} ? 2 : 1);
  }
  use constant _NumSeq_Coord_FracXY_max => 0; # frac(X/Y)=0 always
  use constant _NumSeq_Coord_FracXY_integer => 1;
  use constant _NumSeq_FracXY_max_is_supremum => 0;

  sub _NumSeq_Coord_ExperimentalNumerator_min {
    my ($self) = @_;
    return ($self->{'proper'} ? 2 : 1);
  }

  # X/Y = Z/1 since X divisible by Y, ExperimentalDenominator=1 always
  use constant _NumSeq_Coord_ExperimentalDenominator_min => 1;
  use constant _NumSeq_Coord_ExperimentalDenominator_max => 1;
  use constant _NumSeq_Coord_ExperimentalDenominator_non_decreasing => 1;

  use constant _NumSeq_Coord_BitAnd_min => 0;  # at X=2,Y=1
  sub _NumSeq_Coord_BitXor_min {
    my ($self) = @_;
    # octant Y<=X so X-Y>=0
    return ($self->{'proper'} ? 2   # at X=3,Y=1
            :                   0); # at X=1,Y=1
  }

  use constant _NumSeq_Coord_Max_non_decreasing => 1; # Max==X
  sub _NumSeq_Coord_MaxAbs_min { return $_[0]->x_minimum } # Max=X

  use constant _NumSeq_Coord_ExperimentalHammingDist_min => 1; # X!=Y

  use constant _NumSeq_Coord_oeis_anum =>
    { 'divisor_type=all,n_start=1' =>
      { X      => 'A061017',  # n appears divisors(n) times
        Max    => 'A061017',  #  Max=X since Y <= X
        MaxAbs => 'A061017',  #  MaxAbs=Max
        Y      => 'A027750',  # triangle divisors of n
        Min    => 'A027750',  #  Min=Y since Y <= X
        MinAbs => 'A027750',  #  MinAbs=Min
        GCD    => 'A027750',  # Y since Y is a divisor of X
        IntXY  => 'A056538',  # divisors in reverse order, X/Y give high to low
        ExperimentalNumerator => 'A056538', # same as int(X/Y)
        # OEIS-Catalogue: A061017 planepath=DivisibleColumns,n_start=1 coordinate_type=X
        # OEIS-Other:     A061017 planepath=DivisibleColumns,n_start=1 coordinate_type=Max
        # OEIS-Other:     A061017 planepath=DivisibleColumns,n_start=1 coordinate_type=MaxAbs
        # OEIS-Catalogue: A027750 planepath=DivisibleColumns,n_start=1 coordinate_type=Y
        # OEIS-Other:     A027750 planepath=DivisibleColumns,n_start=1 coordinate_type=Min
        # OEIS-Other:     A027750 planepath=DivisibleColumns,n_start=1 coordinate_type=GCD
        # OEIS-Catalogue: A056538 planepath=DivisibleColumns,n_start=1 coordinate_type=IntXY
        # OEIS-Other:     A056538 planepath=DivisibleColumns,n_start=1 coordinate_type=ExperimentalNumerator
      },

      'divisor_type=proper,n_start=2' =>
      { DiffXY  => 'A208460',  # X-Y
        AbsDiff => 'A208460',  # abs(X-Y) same since Y<=X so X-Y>=0
        # OEIS-Catalogue: A208460 planepath=DivisibleColumns,divisor_type=proper,n_start=2 coordinate_type=DiffXY
        # OEIS-Other:     A208460 planepath=DivisibleColumns,divisor_type=proper,n_start=2 coordinate_type=AbsDiff

        # Not quite, A027751 has an extra 1 at the start from reckoning by
        # convention 1 as a proper divisor of 1 -- though that's
        # inconsistent with A032741 count of proper divisors being 0.
        #
        # 'divisor_type=proper,n_start=0' =>
        # { Y,Min,GCD => 'A027751',  # proper divisors by rows
        #   # OEIS-Catalogue: A027751 planepath=DivisibleColumns,divisor_type=proper coordinate_type=Y
        # },
      },
    };

}
# { package Math::PlanePath::File;
#   # File                   points from a disk file
#   # FIXME: analyze points for min/max maybe
# }
# { package Math::PlanePath::QuintetCurve;
#   # inherit from QuintetCentres
# }
{ package Math::PlanePath::QuintetCentres;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::QuintetReplicate;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::AR2W2Curve;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
}
{ package Math::PlanePath::BetaOmega;
  use constant _NumSeq_Coord_filling_type => 'half';
}
{ package Math::PlanePath::KochelCurve;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
}
# { package Math::PlanePath::DekkingCurve;
# }
{ package Math::PlanePath::DekkingCentres;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
}
{ package Math::PlanePath::CincoCurve;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
}
{ package Math::PlanePath::SquareReplicate;
  use constant _NumSeq_Coord_filling_type => 'plane';
}
{ package Math::PlanePath::CornerReplicate;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
  use constant _NumSeq_Coord_oeis_anum =>
    { '' =>
      { Y           => 'A059906',  # alternate bits second (ZOrderCurve Y)
        BitXor      => 'A059905',  # alternate bits first  (ZOrderCurve X)
        ExperimentalHammingDist => 'A139351',  # count 1-bits at even bit positions
        # OEIS-Other: A059906 planepath=CornerReplicate coordinate_type=Y
        # OEIS-Other: A059905 planepath=CornerReplicate coordinate_type=BitXor
        # OEIS-Catalogue: A139351 planepath=CornerReplicate coordinate_type=ExperimentalHammingDist
      },
    };
}
{ package Math::PlanePath::DigitGroups;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
  # # Not quite, A073089 is OFFSET=1 not N=0, also A073089 has extra initial 0
  # use constant _NumSeq_Coord_oeis_anum =>
  #   { 'radix=2' =>
  #     { ExperimentalParity => 'A073089',  # DragonMidpoint AbsdY Nodd ^ bit-above-low-0
  #       # OEIS-Other: A073089 planepath=DigitGroups coordinate_type=ExperimentalParity
  #     },
  #   };
}
# { package Math::PlanePath::FibonacciWordFractal;
# }
{ package Math::PlanePath::LTiling;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
  # X=1,Y=1 doesn't occur, only X=1,Y=2 or X=2,Y=1
  {
    my %_NumSeq_Coord_Max_min = (upper => 1,   # X=0,Y=0 not visited by these
                                 left  => 1,
                                 ends  => 1);
    sub _NumSeq_Coord_Max_min {
      my ($self) = @_;
      return $_NumSeq_Coord_Max_min{$self->{'L_fill'}} || 0;
    }
  }

  sub _NumSeq_Coord_TRSquared_min {
    my ($self) = @_;
    return ($self->{'L_fill'} eq 'upper' ? 3    # X=0,Y=1
            : ($self->{'L_fill'} eq 'left'
               || $self->{'L_fill'} eq 'ends') ? 1   # X=1,Y=0
            : 0);  # 'middle','all' X=0,Y=0
  }
  {
    my %BitOr_min = (upper => 1,   # X=0,Y=0 not visited by these
                     left  => 1,
                     ends  => 1);
    sub _NumSeq_Coord_BitOr_min {
      my ($self) = @_;
      return $BitOr_min{$self->{'L_fill'}} || 0;
    }
  }
  *_NumSeq_Coord_BitXor_min = \&_NumSeq_Coord_BitOr_min;

  {
    my %_NumSeq_Coord_ExperimentalHammingDist_min = (upper => 1,  # X!=Y for these
                                         left  => 1,
                                         ends  => 1);
    sub _NumSeq_Coord_ExperimentalHammingDist_min {
      my ($self) = @_;
      return $_NumSeq_Coord_ExperimentalHammingDist_min{$self->{'L_fill'}} || 0;
    }
    *_NumSeq_Coord_MaxAbs_min = \&_NumSeq_Coord_ExperimentalHammingDist_min;
  }

  # Not quite, A112539 OFFSET=1 versus start N=0 here
  # use constant _NumSeq_Coord_oeis_anum =>
  #   { 'L_fill=left' =>
  #     { ExperimentalParity => 'A112539',  # thue-morse count1bits mod 2
  #       # OEIS-Catalogue: A112539 planepath=LTiling,L_fill=left coordinate_type=ExperimentalParity
  #     },
  #   };
}
{ package Math::PlanePath::WythoffArray;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
  # FIXME: if x_start=1 but y_start=0 then want corresponding mixture of
  # A-nums.  DiffXY is whenever x_start==y_start.
  use constant _NumSeq_Coord_oeis_anum =>
    { 'x_start=0,y_start=0' =>
      { Y      => 'A019586', # row containing N
        DiffXY => 'A191360', # diagonal containing N
        # OEIS-Catalogue: A019586 planepath=WythoffArray coordinate_type=Y
        # OEIS-Catalogue: A191360 planepath=WythoffArray coordinate_type=DiffXY

        # Not quite, A035614 has OFFSET start n=0 whereas path starts N=1
        # X => 'A035614',
      },
      'x_start=1,y_start=1' =>
      { X      => 'A035612', # column number containing N, start column=1
        Y      => 'A003603', # row number containing N, starting row=1
        DiffXY => 'A191360', # diagonal containing N
        # OEIS-Catalogue: A035612 planepath=WythoffArray,x_start=1,y_start=1
        # OEIS-Catalogue: A003603 planepath=WythoffArray,x_start=1,y_start=1 coordinate_type=Y
        # OEIS-Other:     A191360 planepath=WythoffArray,x_start=1,y_start=1 coordinate_type=DiffXY
      },
    };
}
{ package Math::PlanePath::PowerArray;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
  use constant _NumSeq_Coord_oeis_anum =>
    { 'radix=2' =>
      { X => 'A007814', # base 2 count low 0s, starting n=1
        # main generator Math::NumSeq::DigitCountLow
        # OEIS-Other: A007814 planepath=PowerArray,radix=2

        # Not quite, A025480 starts OFFSET=0 for the k in n=(2k+1)*2^j-1
        # Y => 'A025480',
        # # OEIS-Almost: A025480 i_to_n_offset=-1 planepath=PowerArray,radix=2 coordinate_type=Y
      },
      'radix=3' =>
      { X => 'A007949', # k of greatest 3^k dividing n
        # OEIS-Other: A007949 planepath=PowerArray,radix=3
        # main generator Math::NumSeq::DigitCountLow
      },
      'radix=5' =>
      { X => 'A112765',
        # OEIS-Other: A112765 planepath=PowerArray,radix=5
      },
      'radix=6' =>
      { X => 'A122841',
        # OEIS-Other: A122841 planepath=PowerArray,radix=6
      },
      'radix=10' =>
      { X => 'A122840',
        # OEIS-Other: A112765 planepath=PowerArray,radix=5
      },
    };
}

{ package Math::PlanePath::ToothpickTree;
  sub _NumSeq_Coord_Max_min {
    my ($self) = @_;
    if ($self->{'parts'} eq '3') { return 0; }
    return $self->SUPER::_NumSeq_Coord_Max_min;
  }

  {
    my %_NumSeq_Coord_IntXY_min = (1      => 0,
                                   octant => 0,   # X>=Y-1 so X/Y >= 1-1/Y
                                   wedge  => -1,  # X>=-Y,Y>=0 so X/Y<=-1
                                  );
    sub _NumSeq_Coord_IntXY_min {
      my ($self) = @_;
      return $_NumSeq_Coord_IntXY_min{$self->{'parts'}};
    }
  }
  {
    my %_NumSeq_Coord_IntXY_max = (octant_up => 0,
                                   # except wedge 0/0 = infinity
                                   # wedge     => 1,  # Y>=X so X/Y<=1
                                  );
    sub _NumSeq_Coord_IntXY_max {
      my ($self) = @_;
      return $_NumSeq_Coord_IntXY_max{$self->{'parts'}};
    }
  }

  sub _NumSeq_Coord_BitAnd_min {
    my ($self) = @_;
    return ($self->{'parts'} eq '4'
            ? undef   # X<0,Y<0
            : 0);     # otherwise X>0 or Y>0 so BitAnd>=0
  }

  {
    my %_NumSeq_Coord_TRSquared_min = (2         => 3,  # X=0,Y=1
                                       1         => 4,  # X=1,Y=1
                                       octant    => 4,  # X=1,Y=1
                                       octant_up => 13, # X=1,Y=2
                                      );
    sub _NumSeq_Coord_TRSquared_min {
      my ($self) = @_;
      return ($_NumSeq_Coord_TRSquared_min{$self->{'parts'}} || 0);
    }
  }
  {
    # usually 7, but in these 8
    my %_NumSeq_Coord_ExperimentalLeafDistance_max = (octant    => 8,
                                          octant_up => 8,
                                          wedge     => 8,
                                         );
    sub _NumSeq_Coord_ExperimentalLeafDistance_max {
      my ($self) = @_;
      return ($_NumSeq_Coord_ExperimentalLeafDistance_max{$self->{'parts'}} || 7);
    }
  }
}
{ package Math::PlanePath::ToothpickReplicate;
  *_NumSeq_Coord_BitAnd_min
    = \&Math::PlanePath::ToothpickTree::_NumSeq_Coord_BitAnd_min;
  *_NumSeq_Coord_TRSquared_min
    = \&Math::PlanePath::ToothpickTree::_NumSeq_Coord_TRSquared_min;
}
{ package Math::PlanePath::ToothpickUpist;
  use constant _NumSeq_Coord_Y_non_decreasing => 1; # rows upwards
  use constant _NumSeq_Coord_Max_non_decreasing => 1; # X<=Y so max=Y
  use constant _NumSeq_Coord_MaxAbs_non_decreasing => 1; # -Y<=X<=Y so MaxAbs=Y

  use constant _NumSeq_Coord_ExperimentalLeafDistance_max => 9;
}

{ package Math::PlanePath::LCornerTree;
  sub _NumSeq_Coord_Max_min {
    my ($self) = @_;
    return ($self->{'parts'} eq '4' ? undef : 0);
  }
  {
    my %_NumSeq_Coord_IntXY_min
      = (1             => 0,
         octant        => 1,  # X>=Y so X/Y>=1, and 0/0
         'octant+1'    => 0,  # X>=Y-1 so int(X/Y)>=0
         octant_up     => 0,  # X>=0 so X/Y>=1, and 0/0
         'octant_up+1' => 0,  # X>=0 so X/Y>=1, and 0/0
         wedge         => -2, # X>=-Y-1 so X/Y>=-2
         'wedge+1'     => -3, # X>=-Y-2 so X/Y>=-3
        );
    sub _NumSeq_Coord_IntXY_min {
      my ($self) = @_;
      return $_NumSeq_Coord_IntXY_min{$self->{'parts'}};
    }
  }

  use constant _NumSeq_Coord_ExperimentalLeafDistance_max => 2;
}
{ package Math::PlanePath::LCornerReplicate;
  use constant _NumSeq_Coord_filling_type => 'quadrant';
}
# { package Math::PlanePath::PeninsulaBridge;
# }

{ package Math::PlanePath::OneOfEight;
  sub _NumSeq_Coord_Max_min {
    my ($self) = @_;
    return ($self->{'parts'} eq '4' ? undef : 0);
  }

  sub _NumSeq_Coord_IntXY_min {
    my ($self) = @_;
    if ($self->{'parts'} eq 'octant') { return 1; }
    return $self->SUPER::_NumSeq_Coord_IntXY_min;
  }

  {
    # usually 2, but in 3side only 1
    my %_NumSeq_Coord_ExperimentalLeafDistance_max = ('3side'   => 1,
                                         );
    sub _NumSeq_Coord_ExperimentalLeafDistance_max {
      my ($self) = @_;
      return $_NumSeq_Coord_ExperimentalLeafDistance_max{$self->{'parts'}} || 2;
    }
  }
}

{ package Math::PlanePath::HTree;
  use constant _NumSeq_Coord_Depth_non_decreasing => 0;
  use constant _NumSeq_Coord_NumSiblings_non_decreasing => 1;
}

#------------------------------------------------------------------------------
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
#   my $coordinate_type = $self->{'coordinate_type'};
#   if ($coordinate_type eq 'X') {
#     if ($planepath_object->x_negative) {
#       return 1;
#     } else {
#       return ($value >= 0);
#     }
#   } elsif ($coordinate_type eq 'Y') {
#     if ($planepath_object->y_negative) {
#       return 1;
#     } else {
#       return ($value >= 0);
#     }
#   } elsif ($coordinate_type eq 'Sum') {
#     if ($planepath_object->x_negative || $planepath_object->y_negative) {
#       return 1;
#     } else {
#       return ($value >= 0);
#     }
#   } elsif ($coordinate_type eq 'RSquared') {
#     # FIXME: only sum of two squares, and for triangular same odd/even.
#     # Factorize or search ?
#     return ($value >= 0);
#   }
#
#   return undef;
# }


=for stopwords Ryde Math-PlanePath PlanePath DiffXY AbsDiff IntXY FracXY OEIS NumSeq SquareSpiral SumAbs Manhattan ie TRadius TRSquared RSquared DiffYX BitAnd BitOr BitXor bitand bitwise gnomon MinAbs gnomons MaxAbs

=head1 NAME

Math::NumSeq::PlanePathCoord -- sequence of coordinate values from a PlanePath module

=head1 SYNOPSIS

 use Math::NumSeq::PlanePathCoord;
 my $seq = Math::NumSeq::PlanePathCoord->new
             (planepath => 'SquareSpiral',
              coordinate_type => 'X');
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is a tie-in to make a C<NumSeq> sequence giving coordinate values from
a C<Math::PlanePath>.  The NumSeq "i" index is the PlanePath "N" value.

The C<coordinate_type> choices are as follows.  Generally they have some
sort of geometric interpretation or are related to fractions X/Y.

    "X"            X coordinate
    "Y"            Y coordinate
    "Min"          min(X,Y)
    "Max"          max(X,Y)
    "MinAbs"       min(abs(X),abs(Y))
    "MaxAbs"       max(abs(X),abs(Y))
    "Sum"          X+Y sum
    "SumAbs"       abs(X)+abs(Y) sum
    "Product"      X*Y product
    "DiffXY"       X-Y difference
    "DiffYX"       Y-X difference (negative of DiffXY)
    "AbsDiff"      abs(X-Y) difference
    "Radius"       sqrt(X^2+Y^2) radial distance
    "RSquared"     X^2+Y^2 radius squared (norm)
    "TRadius"      sqrt(X^2+3*Y^2) triangular radius
    "TRSquared"    X^2+3*Y^2 triangular radius squared (norm)
    "IntXY"        int(X/Y) division rounded towards zero
    "FracXY"       frac(X/Y) division rounded towards zero
    "BitAnd"       X bitand Y
    "BitOr"        X bitor Y
    "BitXor"       X bitxor Y
    "GCD"          greatest common divisor X,Y
    "Depth"        tree_n_to_depth()
    "SubHeight"    tree_n_to_subheight()
    "NumChildren"  tree_n_num_children()
    "NumSiblings"  not including self
    "RootN"        the N which is the tree root
    "IsLeaf"       0 or 1 whether a leaf node (no children)
    "IsNonLeaf"    0 or 1 whether a non-leaf node (has children)
                     also called an "internal" node

=head2 Min and Max

"Min" and "Max" are the minimum or maximum of X and Y.  The geometric
interpretation of "Min" is to select X at any point above the X=Y diagonal
or Y for any point below.  Conversely "Max" is Y above and X below.  On the
X=Y diagonal itself X=Y=Min=Max.

    Max=Y      / X=Y diagonal
    Min=X   | /
            |/
         ---o----
           /|
          / |     Max=X
         /        Min=Y

X<Gnomon>Min and Max can also be interpreted as counting which gnomon shaped
line the X,Y falls on.

    | | | |     Min=gnomon           2 ------------.  Max=gnomon
    | | | |                          1 ----------. |
    | | | |      ...                 0 --------o | |
    | | |  ------ 1                 -1 ------. | | |
    | | o-------- 0                 ...      | | | |
    |  ---------- -1                         | | | |
     ------------ -2                         | | | |

=head2 MinAbs

X<Gnomon>MinAbs = min(abs(X),abs(Y)) can be interpreted geometrically as
counting gnomons successively away from the origin.  This is like Min above,
but within the quadrant containing X,Y.

         | | | | |          MinAbs=gnomon counted away from the origin
         | | | | |
    2 ---  | | |  ---- 2
    1 -----  |  ------ 1
    0 -------o-------- 0
    1 -----  |  ------ 1
    2 ---  | | |  ---- 2
         | | | | |
         | | | | |

=head2 MaxAbs

MaxAbs = max(abs(X),abs(Y)) can be interpreted geometrically as counting
successive squares around the origin.

    +-----------+       MaxAbs=which square
    | +-------+ |
    | | +---+ | |
    | | | o | | |
    | | +---+ | |
    | +-------+ |
    +-----------+

For example L<Math::PlanePath::SquareSpiral> loops around in squares and so
its MaxAbs is unchanged until it steps out to the next bigger square.

=head2 Sum and Diff

"Sum"=X+Y and "DiffXY"=X-Y can be interpreted geometrically as coordinates
on 45-degree diagonals.  Sum is a measure up along the leading diagonal and
DiffXY down an anti-diagonal,

    \           /
     \   s=X+Y /
      \       ^\
       \     /  \
        \ | /    v
         \|/      * d=X-Y
       ---o----
         /|\
        / | \
       /  |  \
      /       \
     /         \
    /           \

Or "Sum" can be thought of as a count of which anti-diagonal stripe contains
X,Y, or a projection onto the X=Y leading diagonal.

           Sum
    \     = anti-diag
     2      numbering          / / / /   DiffXY
    \ \       X+Y            -1 0 1 2   = diagonal
     1 2                     / / / /      numbering
    \ \ \                  -1 0 1 2         X-Y
     0 1 2                   / / /
      \ \ \                 0 1 2

=head2 DiffYX

"DiffYX" = Y-X is simply the negative of DiffXY.  It's included to give
positive values on paths which are above the X=Y leading diagonal.  For
example DiffXY is positive in C<CoprimeColumns> which is below X=Y, whereas
DiffYX is positive in C<CellularRule> which is above X=Y.

=head2 SumAbs

X<Diamonds>"SumAbs" = abs(X)+abs(Y) is similar to the projection described above for
Sum or Diff, but SumAbs projects onto the central diagonal of whichever
quadrant contains the X,Y.  Or equivalently it's a numbering of
anti-diagonals within that quadrant, so numbering which diamond shape the
X,Y falls on.

         |
        /|\       SumAbs = which diamond X,Y falls on
       / | \
      /  |  \
    -----o-----
      \  |  /
       \ | /
        \|/
         |

As an example, the C<DiamondSpiral> path loops around on such diamonds, so
its SumAbs is unchanged until completing a loop and stepping out to the next
bigger.

X<Taxi cab>X<Manhattan>SumAbs is also a "taxi-cab" or "Manhattan" distance,
being how far to travel through a square-grid city to get to X,Y.

    SumAbs = taxi-cab distance, by any square-grid travel

    +-----o       +--o          o
    |             |             |
    |          +--+       +-----+
    |          |          |
    *          *          *

If a path is entirely XE<gt>=0,YE<gt>=0 in the first quadrant then Sum and
SumAbs are identical.

=head2 AbsDiff

"AbsDiff" = abs(X-Y) can be interpreted geometrically as the distance away
from the X=Y diagonal, measured at right-angles to that line.

     d=abs(X-Y)
           ^    / X=Y line
            \  /
             \/
             /\
            /  \
          |/    \
        --o--    \
         /|       v
        /           d=abs(X-Y)

If a path is entirely below the X=Y line, so XE<gt>=Y, then AbsDiff is the
same as DiffXY.  Or if a path is entirely above the X=Y line, so YE<gt>=X,
then AbsDiff is the same as DiffYX.

=head2 Radius and RSquared

Radius and RSquared are per C<$path-E<gt>n_to_radius()> and
C<$path-E<gt>n_to_rsquared()> respectively (see L<Math::PlanePath/Coordinate
Methods>).

=head2 TRadius and TRSquared

"TRadius" and "TRSquared" are designed for use with points on a triangular
lattice as per L<Math::PlanePath/Triangular Lattice>.  For points on the X
axis TRSquared is the same as RSquared but off the axis Y is scaled up by
factor sqrt(3).

Most triangular paths use "even" points X==Y mod 2 and for them TRSquared is
always even.  Some triangular paths such as C<KochPeaks> have an offset from
the origin and use "odd" points X!=Y mod 2 and for them TRSquared is odd.

=head2 IntXY and FracXY

"IntXY" = int(X/Y) is the quotient from X divide Y rounded to an integer
towards zero.  This is like the integer part of a fraction, for example
X=9,Y=4 is 9/4 = 2+1/4 so IntXY=2.  Negatives are reckoned with the fraction
part negated too, so -2 1/4 is -2-1/4 and thus IntXY=-2.

Geometrically IntXY gives which wedge of slope 1, 2, 3, etc the point X,Y
falls in.  For example IntXY is 3 for all points in the wedge
3YE<lt>=XE<lt>4Y.

                               X=Y    X=2Y   X=3Y   X=4Y
    *  -2  *  -1  *   0  |  0   *  1   *  2   *   3  *
       *     *     *     |     *     *     *     *
          *    *    *    |    *    *    *    *
             *   *   *   |   *   *   *   *
                *  *  *  |  *  *  *  *
                   * * * | * * * *
                      ***|****
    ---------------------+----------------------------
                       **|**
                     * * | * *
                   *  *  |  *  *
                 *   *   |   *   *
               *    *    |    *    *
         2   *  1  *  0  |  0  * -1  *  -2

"FracXY" is the fraction part which goes with IntXY.  In all cases

    X/Y = IntXY + FracXY

IntXY rounds towards zero so the remaining FracXY has the same sign as
IntXY.

=head2 BitAnd, BitOr, BitXor

"BitAnd", "BitOr" and "BitXor" treat negative X or negative Y as infinite
twos-complement 1-bits, which means for example X=-1,Y=-2 has X bitand Y
= -2.

    ...11111111    X=-1
    ...11111110    Y=-2
    -----------
    ...11111110    X bitand Y = -2

This twos-complement is per C<Math::BigInt> (which has bitwise operations in
Perl 5.6 and up).  The code here arranges the same on ordinary scalars.

If X or Y are not integers then the fractional parts are treated bitwise
too, but currently only to limited precision.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::PlanePathCoord-E<gt>new (planepath =E<gt> $name, coordinate_type =E<gt> $str)>

Create and return a new sequence object.  The options are

    planepath          string, name of a PlanePath module
    planepath_object   PlanePath object
    coordinate_type    string, as described above

C<planepath> can be either the module part such as "SquareSpiral" or a
full class name "Math::PlanePath::SquareSpiral".

=item C<$value = $seq-E<gt>ith($i)>

Return the coordinate at N=$i in the PlanePath.

=item C<$i = $seq-E<gt>i_start()>

Return the first index C<$i> in the sequence.  This is the position
C<rewind()> returns to.

This is C<$path-E<gt>n_start()> from the PlanePath, since the i numbering is
the N numbering of the underlying path.  For some of the
C<Math::NumSeq::OEIS> generated sequences there may be a higher C<i_start()>
corresponding to a higher starting point in the OEIS, though this is
slightly experimental.

=item C<$str = $seq-E<gt>oeis_anum()>

Return the A-number (a string) for C<$seq> in Sloane's Online Encyclopedia
of Integer Sequences, or return C<undef> if not in the OEIS or not known.

Known A-numbers are also presented through C<Math::NumSeq::OEIS::Catalogue>.
This means PlanePath related OEIS sequences can be created with
C<Math::NumSeq::OEIS> by giving their A-number in the usual way for that
module.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::PlanePathDelta>,
L<Math::NumSeq::PlanePathTurn>,
L<Math::NumSeq::PlanePathN>,
L<Math::NumSeq::OEIS>

L<Math::PlanePath>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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

#------------------------------------------------------------------------------
# Maybe:
#
# LeafDist
# LeafDistDown
#
# ExperimentalNumerator = X*sgn(Y) / gcd(X,Y)    X/Y in least terms, num + or -
# ExperimentalDenominator = abs(Y) / gcd(X,Y)    den >=0
#   X/0 keep as numerator=X ?   or reduce to 1/0 ?
#   0/Y keep as denominator=Y ? or reduce to 0/1 ?
#
# ParentDegree -- num siblings and also self
#
# CfracLength,ExperimentalGcdDivisions,GcdSteps,EuclidSteps
#   -- terms in cfrac(X/Y), excluding int=0 if X<Y
#
# I,J,K   TI,TJ,TK  Ti,Tj,Tk
#   i=(x-y)/2 is DiffXY/2
#   j=Y
#   k=(-X-Y)/2 is Sum
# but div 2 for points=even paths?
#
# GF2Product A051775,A051776  multiply with xor no carry
# ExperimentalNumOverlap       xy_to_n_list()  n_overlap_list()  n_num_overlap()
# NumAround
# PrevNeighbours4
#
# RemXY X mod Y 0<=R<Y + or -; if Y=0 then R=0, or inf?
# ModXY = X mod Y range 0 to abs(Y)-1
# ModYX
# DivXY = X/Y fractional
# DivYX = Y/X fractional
# ExactDivXY = X/Y if X divisible by Y, or 0 if not A126988 X,Y>=1
#
# ExperimentalKroneckerSymbol(a,b)     (a/2)=(2/a), or (a/2)=0 if a even
#
# Theta angle in radians
# AngleFrac
# AngleRadians
# Theta360 angle matching Radius,RSquared
# TTheta360 angle matching TRadius,TRSquared
#
# IsRational -- Chi(x) = 1 if x rational, 0 if irrational
# Dirichlet function D(x) = 1/b if rational x=a/b least terms, 0 if irrational
# Multiplicative distance A130836 X,Y>=1
#     sum abs(exponent-exponent) of each prime
#     A130849 total/2 muldist along diagonal
