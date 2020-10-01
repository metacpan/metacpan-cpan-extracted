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



# math-image --path=CellularRule --all --scale=10
#
# math-image --path=CellularRule --all --output=numbers --size=80x50

# Maybe:
# @rules = Math::PlanePath::CellularRule->rule_equiv_list($rule)
#   list of equivalents
# $bool = Math::PlanePath::CellularRule->rules_are_equiv($rule1,$rule2)
# $rule = Math::PlanePath::CellularRule->rule_to_first($rule)
#   first equivalent
# $bool = Math::PlanePath::CellularRule->rules_are_mirror($rule1,$rule2)
# $rule = Math::PlanePath::CellularRule->rule_to_mirror($rule)
#   or undef if no mirror
# $bool = Math::PlanePath::CellularRule->rule_is_symmetric($rule)



package Math::PlanePath::CellularRule;
use 5.004;
use strict;
use Carp 'croak';

use vars '$VERSION', '@ISA';
$VERSION = 128;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';

use Math::PlanePath::CellularRule54;
*_rect_for_V = \&Math::PlanePath::CellularRule54::_rect_for_V;


# uncomment this to run the ### lines
# use Smart::Comments;


use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;

use constant 1.02 _default_rule => 30;
use constant parameter_info_array =>
  [ { name        => 'rule',
      display     => 'Rule',
      type        => 'integer',
      default     => _default_rule(),
      minimum     => 0,
      maximum     => 255,
      width       => 3,
      type_hint   => 'cellular_rule',
      description => 'Rule number 0 to 255, encoding how triplets 111 through 000 turn into 0 or 1 in the next row.',
    },
    Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];

sub turn_any_straight {
  my ($self) = @_;
  return (($self->{'rule'} & 0x17) == 0         # single cell only
          || ($self->{'rule'} & 0x5F) == 0x0E   # left line 2
          || ($self->{'rule'} & 0x5F) == 0x54   # right line 2
          ? 0    # never straight
          : 1);
}
sub turn_any_left {
  my ($self) = @_;
  return (($self->{'rule'} & 0x17) == 0         # single cell only
          ? 0
          : 1);
}
sub turn_any_right {
  my ($self) = @_;
  return (($self->{'rule'} & 0x17) == 0         # single cell only
          ? 0
          : 1);
}


#------------------------------------------------------------------------------
# x,y range

# rule=1 000->1 goes negative if 001->0 to keep left empty
# so rule&3 == 1
#
# any 001->1, rule&2 goes left initially

sub x_negative {
  my ($self) = @_;
  return (($self->{'rule'} & 2)
          || ($self->{'rule'} & 3) == 1);
}
sub x_maximum {
  my ($self) = @_;
  return (($self->{'rule'} & 0x17) == 0         # single cell only
          || $self->{'rule'}==70 || $self->{'rule'}==198
          || $self->{'rule'}==78
          || $self->{'rule'}==110
          || $self->{'rule'}==230
          ? 0
          : undef);
}
{
  my @x_negative_at_n
    = (
       undef,     2, undef,     1, undef,     3, undef,     1,    # rule=0
       undef,     3, undef,     1, undef,     4, undef,     1,    # rule=8
       undef,     2, undef,     1, undef,     3,     1,     1,    # rule=16
       undef,     2, undef,     1, undef,     4,     1,     1,    # rule=24
       undef,     2, undef,     1, undef,     2, undef,     1,    # rule=32
       undef,     3, undef,     1, undef,     2, undef,     1,    # rule=40
       undef,     2, undef,     1, undef,     3, undef,     1,    # rule=48
       undef, undef, undef,     1, undef,     3,     1,     1,    # rule=56
       undef,     1, undef,     1, undef,     2,     1,     1,    # rule=64
       undef,     1, undef,     1, undef,     2,     1,     1,    # rule=72
       undef,     2, undef,     1, undef,     3,     1,     1,    # rule=80
       undef,     2, undef,     1, undef,     3,     1,     1,    # rule=88
       undef,     1, undef, undef, undef,     2, undef,     1,    # rule=96
       undef,     1, undef,     1, undef,     2,     1,     1,    # rule=104
       undef,     2, undef,     1, undef,     3,     1,     1,    # rule=112
       undef,     2, undef,     1, undef,     3,     1,     1,    # rule=120
       undef,     2, undef,     1, undef,     4, undef,     1,    # rule=128
       undef,     5, undef,     1, undef,     7, undef,     1,    # rule=136
       undef,     2, undef,     1, undef,     5,     1, undef,    # rule=144
       undef,     2, undef,     1, undef,     6,     1, undef,    # rule=152
       undef,     2, undef,     1, undef,     2, undef,     1,    # rule=160
       undef,     6, undef,     1, undef,     2, undef,     1,    # rule=168
       undef,     2, undef, undef, undef,     3,     1, undef,    # rule=176
       undef,     2, undef,     1, undef,     3, undef, undef,    # rule=184
       undef,     1, undef,     1, undef,     2,     1,     1,    # rule=192
       undef,     1, undef,     1, undef,     2, undef,     1,    # rule=200
       undef,     2, undef,     1, undef,     3,     1, undef,    # rule=208
       undef,     2, undef,     1, undef,     3, undef, undef,    # rule=216
       undef,     1, undef,     1, undef,     2,     1,     1,    # rule=224
       undef,     1, undef,     1, undef,     2, undef,     1,    # rule=232
       undef,     2, undef,     1, undef,     3, undef, undef,    # rule=240
       undef,     2, undef,     1, undef,     3,                  # rule=248
      );
  sub x_negative_at_n {
    my ($self) = @_;
    my $x_negative_at_n = $x_negative_at_n[$self->{'rule'}];
    return (defined $x_negative_at_n
            ? $self->n_start + $x_negative_at_n
            : undef);
  }
}

sub y_maximum {
  my ($self) = @_;
  return (($self->{'rule'} & 0x17) == 0         # single cell only
          ? 0
          : undef);
}

#------------------------------------------------------------------------------
# sumxy,diffxy range

use constant sumxy_minimum => 0;  # triangular X>=-Y so X+Y>=0
sub sumxy_maximum {
  my ($self) = @_;
  if (($self->{'rule'} & 0x5F) == 0x0E) {   # left line 2
    return 1;
  }
  return undef;
}

sub diffxy_minimum {
  my ($self) = @_;
  if (($self->{'rule'} & 0x5F) == 0x54) {  # right line 2
    return -1;
  }
  return undef;
}
use constant diffxy_maximum => 0; # triangular X<=Y so X-Y<=0

#------------------------------------------------------------------------------
# dx range

sub dx_minimum {
  my ($self) = @_;
  return (($self->{'rule'} & 0x17) == 0        # single cell only
          || ($self->{'rule'} & 0x5F) == 0x54  # right line 2
          ? 0

          : ($self->{'rule'} & 0x5F) == 0x0E   # left line 2
          ? -2

          : undef);
}
{
  # Eg. rule=25 jumps +5
  my @dx_maximum = (
     undef,     4, undef,     3, undef,     2, undef,     1,
     undef,     2, undef,     2, undef,     2,     1,     2,
     undef,     3, undef,     2, undef,     1, undef,     1,
     undef,     5, undef,     2,     2,     2, undef,     1,
     undef,     4, undef,     3, undef, undef, undef,     2,
     undef,     3, undef,     2, undef, undef,     1,     2,
     undef,     3, undef,     2, undef,     2, undef,     1,
     undef, undef, undef,     2, undef,     4,     4,     1,
     undef,     2, undef,     5, undef,     2,     2,     2,
     undef, undef, undef, undef, undef,     2,     2,     2,
     undef,     1, undef,     2,     1,     1, undef,     1,
     undef, undef, undef,     4,     2,     2,     2,     1,
     undef,     3, undef, undef, undef, undef, undef,     4,
     undef, undef, undef, undef, undef,     4, undef,     4,
     undef,     1, undef,     2,     1,     1,     4,     1,
     undef, undef, undef,     2, undef,     4, undef,     1,
     undef, undef, undef,     5, undef,     2, undef, undef,
     undef, undef, undef,     3, undef,     2,     1,     3,
     undef,     5, undef,     4, undef, undef, undef, undef,
     undef, undef, undef,     3,     2,     2,     3, undef,
     undef, undef, undef,     3, undef,     2, undef,     2,
     undef, undef, undef,     3, undef,     1,     1,     2,
     undef,     3, undef, undef, undef,     2,     2, undef,
     undef,     2, undef,     2,     2,     1, undef, undef,
     undef, undef, undef, undef, undef,     2,     2,     2,
     undef,     4, undef,     2, undef,     2, undef,     2,
     undef,     3, undef,     3,     1,     3,     3, undef,
     undef,     2, undef,     2, undef,     2, undef, undef,
     undef, undef, undef,     2, undef,     1,     2,     1,
     undef,     2, undef,     2, undef,     1, undef,     1,
     undef,     3, undef,     2,     1,     2, undef, undef,
     undef,     2, undef,     2, undef,     1,
                   );
  sub dx_maximum {
    my ($self) = @_;
    return $dx_maximum[$self->{'rule'}];
  }
}

#------------------------------------------------------------------------------
# dy range

#   23,  31,  55,  63,87,95, 119, 127
# 0x17,0x1F,0x37,0x3F,...,  0x77,0x7F alts
# is rule & 0x98 = 0x17
# Math::PlanePath::CellularRule::Line handles the dY=+1 always lines,
# everything else has some row with 2 or more (except the single cell only
# patterns).
use constant dy_minimum => 0;
sub dy_maximum {
  my ($self) = @_;
  # 0x1,0x9,0x
  return (($self->{'rule'} & 0x17) == 1       # single cell only
          || $self->{'rule'}==7 || $self->{'rule'}==21  # alternating rows
          || $self->{'rule'}==19              # alternating rows
          || ($self->{'rule'} & 0x97) == 0x17
          ? 2
          : 1);
}

#------------------------------------------------------------------------------
# absdx

# left 2 cell line 14,46,142,174
# 111 -> any, doesn't occur
# 110 -> 0
# 101 -> any, doesn't occur
# 100 -> 0
# 011 -> 1
# 010 -> 1
# 001 -> 1
# 000 -> 0
# so (rule & 0x5F) == 0x0E
#
# left 1,2 cell line 6,38,134,166
# 111 -> any, doesn't occur
# 110 -> 0
# 101 -> any, doesn't occur
# 100 -> 0
# 011 -> 0
# 010 -> 1
# 001 -> 1
# 000 -> 0
# so (rule & 0x5F) == 0x06
#
{
  my @absdx_minimum = (
     undef,     0, undef,     1, undef,     0, undef,     1,
     undef,     0, undef,     1, undef,     0,     1,     1,
     undef,     1, undef,     1, undef,     0,     1,     1,
     undef,     1, undef,     0,     0,     0,     1,     1,
     undef,     0, undef,     1, undef,     0, undef,     1,
     undef,     0, undef,     1, undef,     0,     1,     1,
     undef,     1, undef,     1, undef,     0, undef,     1,
     undef, undef, undef,     1, undef,     0,     1,     1,
     undef,     0, undef,     0, undef,     0,     1,     0,
     undef,     1, undef,     0, undef,     0,     1,     0,
     undef,     0, undef,     1,     0,     0,     1,     1,
     undef,     1, undef,     1,     0,     0,     1,     1,
     undef,     1, undef, undef, undef,     0, undef,     0,
     undef,     1, undef,     0, undef,     0,     1,     0,
     undef,     0, undef,     1,     0,     0,     1,     1,
     undef,     1, undef,     1,     0,     0,     1,     1,
     undef,     0, undef,     1, undef,     0, undef,     1,
     undef,     0, undef,     1, undef,     0,     1,     1,
     undef,     1, undef,     1, undef,     0,     1, undef,
     undef,     1, undef,     1,     0,     0,     1, undef,
     undef,     0, undef,     1, undef,     0, undef,     1,
     undef,     0, undef,     1, undef,     0,     1,     1,
     undef,     1, undef, undef, undef,     0,     1, undef,
     undef,     1, undef,     1,     0,     0, undef, undef,
     undef,     1, undef,     1, undef,     0,     1,     1,
     undef,     1, undef,     1, undef,     0, undef,     1,
     undef,     1, undef,     1,     0,     0,     1, undef,
     undef,     1, undef,     1, undef,     0, undef, undef,
     undef,     1, undef,     1, undef,     0,     1,     1,
     undef,     1, undef,     1, undef,     0, undef,     1,
     undef,     1, undef,     1,     0,     0, undef, undef,
     undef,     1, undef,     1, undef,     0,
                   );
  sub absdx_minimum {
    my ($self) = @_;
    return $absdx_minimum[$self->{'rule'}];
  }
}

#------------------------------------------------------------------------------
# dsumxy

sub dsumxy_minimum {
  my ($self) = @_;
  return (($self->{'rule'} & 0x5F) == 0x54  # right line 2, const dSum=+1
          ? 1
          : ($self->{'rule'} & 0x5F) == 0x0E     # left line 2
          ? -1
          : undef);
}
{
  my @dsumxy_maximum = (
     undef,     4, undef,     3, undef,     2, undef,     1,
     undef,     3, undef,     3, undef,     2,     1,     3,
     undef,     3, undef,     2, undef,     1, undef,     1,
     undef,     5, undef,     2,     2,     2, undef,     1,
     undef,     4, undef,     3, undef, undef, undef,     2,
     undef,     4, undef,     3, undef, undef,     1,     3,
     undef,     3, undef,     2, undef,     2, undef,     1,
     undef, undef, undef,     2, undef,     4,     4,     1,
     undef,     3, undef,     5, undef,     2,     2,     2,
     undef, undef, undef, undef, undef,     2,     2,     2,
     undef,     2, undef,     2,     1,     1, undef,     1,
     undef, undef, undef,     4,     2,     2,     2,     1,
     undef,     3, undef, undef, undef, undef, undef,     4,
     undef, undef, undef, undef, undef,     4, undef,     4,
     undef,     2, undef,     2,     1,     1,     4,     1,
     undef, undef, undef,     2, undef,     4, undef,     1,
     undef, undef, undef,     5, undef,     2, undef, undef,
     undef, undef, undef,     3, undef,     2,     1,     3,
     undef,     5, undef,     4, undef, undef, undef, undef,
     undef, undef, undef,     3,     2,     2,     3, undef,
     undef, undef, undef,     3, undef,     2, undef,     2,
     undef, undef, undef,     3, undef,     1,     1,     2,
     undef,     3, undef, undef, undef,     2,     2, undef,
     undef,     2, undef,     2,     2,     1, undef, undef,
     undef, undef, undef, undef, undef,     2,     2,     2,
     undef,     4, undef,     2, undef,     2, undef,     2,
     undef,     3, undef,     3,     1,     3,     3, undef,
     undef,     2, undef,     2, undef,     2, undef, undef,
     undef, undef, undef,     2, undef,     1,     2,     1,
     undef,     2, undef,     2, undef,     1, undef,     1,
     undef,     3, undef,     2,     1,     2, undef, undef,
     undef,     2, undef,     2, undef,     1,
                   );
  sub dsumxy_maximum {
    my ($self) = @_;
    return $dsumxy_maximum[$self->{'rule'}];
  }
}
# sub dsumxy_maximum {
#   my ($self) = @_;
#   return (($self->{'rule'} & 0x5F) == 0x54  # right line 2
#           ? 1                               #   is constant dSum=+1
#           : ($self->{'rule'} & 0x5F) == 0x0E     # left line 2
#           ? 1
#           : $self->{'rule'}==3 || $self->{'rule'}==35 ? 3
#           : $self->{'rule'} == 5 ? 2
#           : $self->{'rule'} == 7 ? 1
#           : $self->{'rule'} == 9 ? 3
#           : $self->{'rule'}==11 || $self->{'rule'}==43 ? 3
#           : $self->{'rule'} == 13 ? 2
#           : $self->{'rule'} == 15 ? 3
#           : $self->{'rule'}==17 || $self->{'rule'}==49 ? 3
#           : $self->{'rule'}==19 ? 2
#           : $self->{'rule'}==21 ? 1
#           : ($self->{'rule'} & 0x97) == 0x17     # 0x17,...,0x7F
#           ? 1
#           : $self->{'rule'}==27 ? 2
#           : $self->{'rule'}==28 || $self->{'rule'}==156 ? 2
#           : $self->{'rule'}==29 ? 2
#           : $self->{'rule'}==31 ? 1
#           : $self->{'rule'}==39 ? 2
#           : $self->{'rule'}==47 ? 3
#           : $self->{'rule'}==51 ? 2
#           : $self->{'rule'}==53 ? 2
#           : $self->{'rule'}==59 ? 2
#           : $self->{'rule'}==65 ? 3
#           : $self->{'rule'}==69 ? 2
#           : $self->{'rule'}==70 || $self->{'rule'}==198 ? 2
#           : $self->{'rule'}==71 ? 2
#           : $self->{'rule'}==77 ? 2
#           : $self->{'rule'}==78 ? 2
#           : $self->{'rule'}==79 ? 2
#           : $self->{'rule'}==81 || $self->{'rule'}==113 ? 2
#           : undef);
# }

#------------------------------------------------------------------------------
# ddiffxy range

sub ddiffxy_minimum {
  my ($self) = @_;
  return (($self->{'rule'} & 0x5F) == 0x54   # right line 2, dDiffXY=-1 or +1
          ? -1
          : ($self->{'rule'} & 0x5F) == 0x0E  # left line 2, dDiffXY=-3 or +1
          ? -3
          : undef);
}
{
  my @ddiffxy_maximum = (
     undef,     4, undef,     3, undef,     2, undef,     1,
     undef,     2, undef,     1, undef,     2,     1,     1,
     undef,     3, undef,     2, undef,     1, undef,     1,
     undef,     5, undef,     2,     2,     2, undef,     1,
     undef,     4, undef,     3, undef, undef, undef,     2,
     undef,     3, undef,     1, undef, undef,     1,     1,
     undef,     3, undef,     2, undef,     2, undef,     1,
     undef, undef, undef,     2, undef,     4,     4,     1,
     undef,     2, undef,     5, undef,     2,     2,     2,
     undef, undef, undef, undef, undef,     2,     2,     2,
     undef,     1, undef,     2,     1,     1, undef,     1,
     undef, undef, undef,     4,     2,     2,     2,     1,
     undef,     3, undef, undef, undef, undef, undef,     4,
     undef, undef, undef, undef, undef,     4, undef,     4,
     undef,     1, undef,     2,     1,     1,     4,     1,
     undef, undef, undef,     2, undef,     4, undef,     1,
     undef, undef, undef,     5, undef,     2, undef, undef,
     undef, undef, undef,     3, undef,     2,     1,     3,
     undef,     5, undef,     4, undef, undef, undef, undef,
     undef, undef, undef,     3,     2,     2,     3, undef,
     undef, undef, undef,     3, undef,     2, undef,     2,
     undef, undef, undef,     3, undef,     1,     1,     2,
     undef,     3, undef, undef, undef,     2,     2, undef,
     undef,     2, undef,     2,     2,     1, undef, undef,
     undef, undef, undef, undef, undef,     2,     2,     2,
     undef,     4, undef,     2, undef,     2, undef,     2,
     undef,     3, undef,     3,     1,     3,     3, undef,
     undef,     2, undef,     2, undef,     2, undef, undef,
     undef, undef, undef,     2, undef,     1,     2,     1,
     undef,     2, undef,     2, undef,     1, undef,     1,
     undef,     3, undef,     2,     1,     2, undef, undef,
     undef,     2, undef,     2, undef,     1,
                   );
  sub ddiffxy_maximum {
    my ($self) = @_;
    return $ddiffxy_maximum[$self->{'rule'}];
  }
}
# sub ddiffxy_maximum {
#   my ($self) = @_;
#   return (($self->{'rule'} & 0x5F) == 0x0E     # left line 2
#           ? 1
#           : $self->{'rule'}==3 || $self->{'rule'}==35 ? 3
#           : $self->{'rule'} == 5 ? 2
#           : $self->{'rule'} == 7 ? 1
#           : $self->{'rule'} == 9 ? 2
#           : $self->{'rule'}==11 || $self->{'rule'}==43 ? 1
#           : $self->{'rule'} == 13 ? 2
#           : $self->{'rule'} == 15 ? 1
#           : $self->{'rule'}==17 || $self->{'rule'}==49 ? 3
#           : $self->{'rule'}==19 ? 2
#           : $self->{'rule'}==21 ? 1
#           : ($self->{'rule'} & 0x97) == 0x17     # 0x17=23,...,0x7F
#           ? 1
#           : $self->{'rule'}==27 ? 2
#           : $self->{'rule'}==28 || $self->{'rule'}==156 ? 2
#           : $self->{'rule'}==29 ? 2
#           : $self->{'rule'}==31 ? 1
#           : $self->{'rule'}==39 ? 2
#           : $self->{'rule'}==41 ? 3
#           : $self->{'rule'}==47 ? 1
#           : $self->{'rule'}==51 ? 2
#           : $self->{'rule'}==53 ? 2
#           : $self->{'rule'}==55 ? 1
#           : $self->{'rule'}==59 ? 2
#           : $self->{'rule'}==65 ? 2
#           : $self->{'rule'}==69 ? 2
#           : $self->{'rule'}==70 || $self->{'rule'}==198 ? 2
#           : $self->{'rule'}==71 ? 2
#           : $self->{'rule'}==77 ? 2
#           : $self->{'rule'}==78 ? 2
#           : $self->{'rule'}==79 ? 2
#           : $self->{'rule'}==81 || $self->{'rule'}==113 ? 1
#           : undef);
# }

#------------------------------------------------------------------------------
# dir range

sub dir_maximum_dxdy {
  my ($self) = @_;
  return (($self->{'rule'} & 0x5F) == 0x54  # right line 2
          ? (0,1)    # north

          : ($self->{'rule'} & 0x5F) == 0x0E     # left line 2
          ? (-2,1)

          : (-1,0));  # supremum, west and 1 up
}


#------------------------------------------------------------------------------

# cf 60 is right half Sierpinski
#    129 is inverse Sierpinski, except for initial N=1 cell
#    119 etc alternate rows PyramidRows step=4 with 2*Y
#    50 PyramidRows with 2*N
#
my @rule_to_class;
{
  my $store = sub {
    my ($rule, $aref) = @_;
    if ($rule_to_class[$rule] && $rule_to_class[$rule] != $aref) {
      die "Oops, already have rule_to_class[] $rule";
    }
    $rule_to_class[$rule] = $aref;
  };

  $store->(54, [ 'Math::PlanePath::CellularRule54' ]);
  $store->(57, [ 'Math::PlanePath::CellularRule57' ]);
  $store->(99, [ 'Math::PlanePath::CellularRule57', mirror => 1 ]);
  $store->(190, [ 'Math::PlanePath::CellularRule190' ]);
  $store->(246, [ 'Math::PlanePath::CellularRule190', mirror => 1 ]);

  {
    # *************      whole solid
    #  ***********
    #   *********
    #    *******
    #     *****
    #      ***
    #       *
    # 0xDE and 0xFE = 222, 254
    # 111 -> 1   solid
    # 110 -> 1   right side
    # 101        any, doesn't occur
    # 100 -> 1   initial
    # 011 -> 1   left side
    # 010 -> 1   initial
    # 001 -> 1   initial
    # 000 -> 0   sides blank
    #
    # -*************-     whole solid with full sides
    # --***********--
    # ---*********---
    # ----*******----
    # -----*****-----
    # ------***------
    #        *
    # and with sides
    # 111 -> 1   solid middle
    # 110        any, doesn't occur
    # 101        any, doesn't occur
    # 100 -> 1   initial
    # 011        any, doesn't occur
    # 010 -> 1   initial
    # 001 -> 1   initial
    # 000 -> 1   sides blank

    my $solid = [ 'Math::PlanePath::PyramidRows', step => 2 ];
    $store->(222, $solid);
    $store->(254, $solid);
    foreach my $i (0 .. 255) {
      $store->(($i&0x68)|0x97, $solid);
    }
  }
  {
    # *******      right half solid
    # ******
    # *****
    # ****
    # ***
    # **
    # *
    #     111 -> 1   solid
    #     110 -> 1   to right
    #     101        any, doesn't occur
    #     100 -> 1   initial
    #     011 -> 1   vertical
    #     010 -> 1   initial
    #     001 -> 0   not to left
    #     000 -> 0
    my $solid_half = [ 'Math::PlanePath::PyramidRows', step => 1 ];
    $store->(220, $solid_half);
    $store->(252, $solid_half);
  }
  {
    # * * * * * * * *
    #  *   *   *   *
    #   * *     * *
    #    *       *
    #     * * * *
    #      *   *
    #       * *
    #        *
    # 18,26,82,90,146,154,210,218
    # 111      any, doesn't occur
    # 110      any, doesn't occur
    # 101 -> 0
    # 100 -> 1 initial
    # 011      any, doesn't occur
    # 010 -> 0 initial
    # 001 -> 1 initial
    # 000 -> 0 for outsides
    #
    my $sierpinski_triangle = [ 'Math::PlanePath::SierpinskiTriangle',
                                n_start => 1 ];
    foreach my $i (0 .. 255) {
      $store->(($i&0xC8)|0x12, $sierpinski_triangle);
    }
  }
  $store->(60, [ 'Math::PlanePath::SierpinskiTriangle',
                 n_start => 1, align => "right" ]);
  $store->(102, [ 'Math::PlanePath::SierpinskiTriangle',
                  n_start => 1, align => "left" ]);

  {
    # left negative line, rule=2,10,...
    # 111      any, doesn't occur
    # 110      any, doesn't occur
    # 101      any, doesn't occur
    # 100 -> 0 initial
    # 011      any, doesn't occur
    # 010 -> 0 initial
    # 001 -> 1 initial towards left
    # 000 -> 0 for outsides
    #
    my $left_line = [ 'Math::PlanePath::CellularRule::Line',
                      align => 'left' ];
    foreach my $i (0 .. 255) {
      $store->(($i&0xE8)|0x02, $left_line);
    }
  }
  {
    # right positive line, rule=16,...
    # 111      any, doesn't occur
    # 110      any, doesn't occur
    # 101      any, doesn't occur
    # 100 -> 1 initial
    # 011      any, doesn't occur
    # 010 -> 0 initial
    # 001 -> 0 initial towards left
    # 000 -> 0 for outsides
    #
    my $right_line = [ 'Math::PlanePath::CellularRule::Line',
                       align => 'right' ];
    foreach my $i (0 .. 255) {
      $store->(($i&0xE8)|0x10, $right_line);
    }
  }
  {
    # central vertical line 4,...
    # 111      any
    # 110      any
    # 101      any
    # 100 -> 0
    # 011      any
    # 010 -> 1 initial cell
    # 001 -> 0
    # 000 -> 0
    my $centre_line = [ 'Math::PlanePath::CellularRule::Line',
                        align => 'centre' ];
    foreach my $i (0 .. 255) {
      $store->(($i&0xE8)|0x04, $centre_line);
    }
  }

  {
    # 1,2 alternating line left  rule=6,38,134,166
    # 111      any, doesn't occur
    # 110 -> 0
    # 101      any, doesn't occur
    # 100 -> 0 initial
    # 011 -> 0
    # 010 -> 1 initial
    # 001 -> 1 angle towards left
    # 000 -> 0 for outsides
    #
    my $left_onetwo = [ 'Math::PlanePath::CellularRule::OneTwo',
                        align => 'left' ];
    foreach my $i (0 .. 255) {
      $store->(($i&0xA0)|0x06, $left_onetwo);
    }
  }
  {
    # 1,2 alternating line right  rule=20,52,148,180 = 0x14,34,94,B4
    # 111      any, doesn't occur
    # 110 -> 0
    # 101      any, doesn't occur
    # 100 -> 1 angle towards right
    # 011 -> 0
    # 010 -> 1 vertical
    # 001 -> 0 not to left
    # 000 -> 0 for outsides
    # so (rule & 0x5F) == 0x14
    #
    my $right_onetwo = [ 'Math::PlanePath::CellularRule::OneTwo',
                        align => 'right' ];
    foreach my $i (0 .. 255) {
      $store->(($i&0xA0)|0x14, $right_onetwo);
    }
  }

  {
    # left line 2  rule=14,46,142,174
    # 111      any, doesn't occur
    # 110 -> 0
    # 101      any, doesn't occur
    # 100 -> 0 initial
    # 011 -> 1
    # 010 -> 1 initial
    # 001 -> 1 angle towards left
    # 000 -> 0 for outsides
    #
    my $left_onetwo = [ 'Math::PlanePath::CellularRule::Two',
                        align => 'left' ];
    foreach my $i (0 .. 255) {
      $store->(($i&0xA0)|0x0E, $left_onetwo);
    }
  }
  {
    # right line 2  rule=84,116,212,244
    # 111      any, doesn't occur
    # 110 -> 1
    # 101      any, doesn't occur
    # 100 -> 1 right, including initial
    # 011 -> 0
    # 010 -> 1 initial vertical
    # 001 -> 0 not to left
    # 000 -> 0 for outsides
    # so (rule & 0x5F) == 0x54
    #
    my $right_onetwo = [ 'Math::PlanePath::CellularRule::Two',
                        align => 'right' ];
    foreach my $i (0 .. 255) {
      $store->(($i&0xA0)|0x54, $right_onetwo);
    }
  }

  {
    # solid every second cell, 50,58,114,122,178,186,242,250, 179
    # http://mathworld.wolfram.com/Rule250.html
    # 111      any, doesn't occur
    # 110      any, doesn't occur
    # 101 -> 1 middle
    # 100 -> 1 initial
    # 011      any, doesn't occur
    # 010 -> 0 initial
    # 001 -> 1 initial
    # 000 -> 0 outsides
    #
    my $odd_solid = [ 'Math::PlanePath::CellularRule::OddSolid' ];
    foreach my $i (0 .. 255) {
      $store->(($i&0xC8)|0x32, $odd_solid);
    }
    $store->(179, $odd_solid);
  }
  {
    # *******   left half solid 206,238 = 0xCE,0xEE
    #  ******
    #   *****
    #    ****
    #     ***
    #      **
    #       *
    # 111 -> 1 middle
    # 110 -> 1 vertical
    # 101      any, doesn't occur
    # 100 -> 0 initial
    # 011 -> 1 left
    # 010 -> 1 initial
    # 001 -> 1 initial
    # 000 -> 0 outsides
    my $left_solid = [ 'Math::PlanePath::PyramidRows',
                       step => 1, align => 'left' ];
    foreach my $i (0 .. 255) {
      $store->(($i&0x20)|0xCE, $left_solid);
    }
  }
}

### rule_to_class count: do { my @k = grep {defined} @rule_to_class; scalar(@k) }
### rule_to_class: [ map {defined($_) && join(',',@$_)} @rule_to_class ]

# ### zap %rule_to_class for testing ...
# %rule_to_class = ();


sub new {
  ### CellularRule new() ...
  my $self = shift->SUPER::new(@_);

  my $rule = $self->{'rule'};
  if (! defined $rule) {
    $rule = $self->{'rule'} = _default_rule();
  }
  ### $rule

  my $n_start = $self->{'n_start'};
  if (! defined $n_start) {
    $n_start = $self->{'n_start'} = $self->default_n_start;
  }

  unless ($self->{'use_bitwise'}) { # secret undocumented option
    if (my $aref = $rule_to_class[$rule]) {
      my ($class, @args) = @$aref;
      ### $class
      ### @args
      $class->can('new')
        or eval "require $class; 1"
          or die;
      return $class->new (rule    => $rule,
                          n_start => $n_start,
                          @args);
    }
  }

  $self->{'rows'} = [ "\001" ];
  $self->{'row_end_n'} = [ $n_start ];
  $self->{'left'} = 0;
  $self->{'right'} = 0;
  $self->{'rule_table'} = [ map { ($rule >> $_) & 1 } 0 .. 7 ];

  ### $self
  return $self;
}

#
# Y=2   L 0 1 2 3 4 R     right=2*Y+2
# Y=1     L 0 1 2 R
# Y=0       L 0 R

sub _extend {
  my ($self) = @_;
  ### _extend()

  my $rule_table = $self->{'rule_table'};
  my $rows = $self->{'rows'};
  my $row = $rows->[-1];
  my $newrow = '';
  my $rownum = $#$rows;
  my $count = 0;
  my $bits = $self->{'left'} * 7;
  $self->{'left'} = $rule_table->[$bits];

  ### $row
  ### $rownum

  foreach my $i (0 .. 2*$rownum) {
    $bits = (($bits<<1) + vec($row,$i,1)) & 7;

    ### $i
    ### $bits
    ### new: $rule_table->[$bits]
    $count +=
      (vec($newrow,$i,1) = $rule_table->[$bits]);
  }

  my $rbit = $self->{'right'};
  $self->{'right'} = $rule_table->[7*$rbit];
  ### $rbit
  ### new right: $self->{'right'}

  # right, second last
  $bits = (($bits<<1) + $rbit) & 7;
  $count +=
    (vec($newrow,2*$rownum+1,1) = $rule_table->[$bits]);
  ### $bits
  ### new second last: $rule_table->[$bits]

  # right end
  $bits = (($bits<<1) + $rbit) & 7;
  $count +=
    (vec($newrow,2*$rownum+2,1) = $rule_table->[$bits]);
  ### $bits
  ### new right end: $rule_table->[$bits]

  ### $count
  ### $newrow
  push @$rows, $newrow;

  my $row_end_n = $self->{'row_end_n'};
  push @$row_end_n, $row_end_n->[-1] + $count;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### CellularRule n_to_xy(): $n

  my $int = int($n);
  $n -= $int;   # now fraction part
  if (2*$n >= 1) {
    $n -= 1;
    $int += 1;
  }
  # -0.5 <= $n < 0.5 fractional part
  ### assert: 2*$n >= -1   || $n+1==$n || $n!=$n
  ### assert: 2*$n < 1     || $n+1==$n || $n!=$n

  if ($int < $self->{'n_start'}) {
    return;
  }
  if (is_infinite($int)) { return ($int,$int); }

  my $row_end_n = $self->{'row_end_n'};
  my $y = 0;
  for (;;) {
    if (scalar(@$row_end_n) >= 3
        && $row_end_n->[-1] == $row_end_n->[-2]
        && $row_end_n->[-2] == $row_end_n->[-3]) {
      ### no more cells in three rows means rest is blank ...
      return;
    }
    if ($y > $#$row_end_n) {
      _extend($self);
    }
    if ($int <= $row_end_n->[$y]) {
      last;
    }
    $y++;
  }

  ### $y
  ### row_end_n: $row_end_n->[$y]
  ### remainder: $int - $row_end_n->[$y]

  $int -= $row_end_n->[$y];
  my $row = $self->{'rows'}->[$y];
  my $x = 2*$y+1;   # for first vec 2*Y
  ### $row

  for ($x = 2*$y+1; $x >= 0; $x--) {
    if (vec($row,$x,1)) {
      ### step bit: "x=$x"
      if (++$int > 0) {
        last;
      }
    }
  }

  ### result: ($n + $x - $y).",$y"

  return ($n + $x - $y,
          $y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### CellularRule xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  if ($y < 0 || ! ($x <= $y && ($x+=$y) >= 0)) {
    return undef;
  }

  my $row_end_n = $self->{'row_end_n'};
  while ($y > $#$row_end_n) {
    if (scalar(@$row_end_n) >= 3
        && $row_end_n->[-1] == $row_end_n->[-2]
        && $row_end_n->[-2] == $row_end_n->[-3]) {
      ### no more cells in three rows means rest is blank ...
      return undef;
    }
    _extend($self);
  }

  my $row = $self->{'rows'}->[$y];
  if (! vec($row,$x,1)) {
    return undef;
  }
  my $n = $row_end_n->[$y];
  foreach my $i ($x+1 .. 2*$y) {
    $n -= vec($row,$i,1);
  }
  return $n;
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### CellularRule rect_to_n_range(): "$x1,$y1  $x2,$y2"

  ($x1,$y1, $x2,$y2) = _rect_for_V ($x1,$y1, $x2,$y2)
    or return (1,0);  # rect outside pyramid

  if (is_infinite($y1)) { return ($self->{'n_start'}, $y1); }  # for nan
  if (is_infinite($y2)) { return ($self->{'n_start'}, $y2); }  # for nan or inf

  my $row_end_n = $self->{'row_end_n'};
  while ($#$row_end_n < $y2) {
    if (scalar(@$row_end_n) >= 3
        && $row_end_n->[-1] == $row_end_n->[-2]
        && $row_end_n->[-2] == $row_end_n->[-3]) {
      ### rect_to_n_range() no more cells in three rows means rest is blank ...
      last;
    }
    _extend($self);
  }

  $y1 -= 1; # to be 1 past end of prev row
  if ($y1 > $#$row_end_n) { $y1 = $#$row_end_n; }

  if ($y2 > $#$row_end_n) { $y2 = $#$row_end_n; }
  ### y range: "$y1 to $y2"

  return ($y1 < 0
          ? $self->{'n_start'}
          : $row_end_n->[$y1] + 1,

          $row_end_n->[$y2]);
}

#------------------------------------------------------------------------------

# 000,001,010,100 = 0,1,2,4 used always
# if 000=1 then 111 used

sub _UNDOCUMENTED__rule_is_finite {
  my ($class, $rule) = @_;
  # zeros 1,0,0  ->   bit4     # total 16 finites
  #       0,1,0  ->   bit2
  #       0,0,1  ->   bit1
  #       0,0,0  ->   bit0
  return ($rule & ((1<<4)|(1<<2)|(1<<1)|(1<<0))) == 0;
}

sub _any_101 {
  my ($rule) = @_;
  # or 0,0,0  ->   bit0  1    & 111 == 011
  #    0,1,0  ->   bit2  0
  #    0,0,1  ->   bit1  1
  # or 0,0,0  ->   bit0  1    & 111 == 011
  #    0,1,0  ->   bit2  0
  #    1,0,0  ->   bit4  1
  return ($rule & 1) || ($rule & 0x16) == 0x16;
}
sub _any_110 {
  my ($rule) = @_;
}
sub _any_011 {
  my ($rule) = @_;
}
sub _any_111 {
  my ($rule) = @_;
  return ($rule & 1) || ($rule & 0x16) == 0x16;
}

# $bool = Math::PlanePath::CellularRule->_NOTWORKING__rules_are_equiv($rule)
sub _NOTWORKING__rules_are_equiv {
  my ($class, $a,$b) = @_;

  my $a_low = $a & 0x17;

  # same 1,0,0  ->   bit4      # 00010111 = 0x17
  #      0,1,0  ->   bit2
  #      0,0,1  ->   bit1
  #      0,0,0  ->   bit0
  return 0 unless $a_low == ($b & 0x17);

  # if 1,0,0  ->   bit4  1      # & 00010111 = 10010
  #    0,1,0  ->   bit2  0
  #    0,0,1  ->   bit1  1
  #    0,0,0  ->   bit0  any
  # or 1,0,0  ->   bit4  0      # & 00010111 = 00101
  #    0,1,0  ->   bit2  1
  #    0,0,1  ->   bit1  any
  #    0,0,0  ->   bit0  1
  # or 1,0,0  ->   bit4  any    # & 00010111 = 00101
  #    0,1,0  ->   bit2  1
  #    0,0,1  ->   bit1  0
  #    0,0,0  ->   bit0  1
  # then
  # same 1,0,1  ->  bit5     # 01001000 = 0x48
  if ($a_low == 0x12 || $a_low == 5) {
    return 0 unless ($a & (1<<5)) == ($b & (1<<5));
  }

  return 1;
}

# $bool = Math::PlanePath::CellularRule->rule_is_symmetric($rule)
sub _NOTWORKING__rule_is_symmetric {
  my ($class, $rule) = @_;
  return ($class->_UNDOCUMENTED__rule_is_finite($rule)  # single cell
          ||
          # same 1,1,0  ->  bit6   # if it is ever reached
          #      0,1,1  ->  bit3
          (($rule & (1<<6)) >> 3) == ($rule & (1<<3))
          &&
          # same 1,0,0  ->  bit4   # if it is ever reached
          #      0,0,1  ->  bit1
          (($rule & (1<<4)) >> 3) == ($rule & (1<<1)));
}

# =item C<$mirror_rule = Math::PlanePath::CellularRule-E<gt>rule_to_mirror ($rule)>
#
# Return a rule number which is a horizontal mirror image of C<$rule>.  This
# is a swap of bits 3E<lt>-E<gt>6 and 1E<lt>-E<gt>4.
#
# If the pattern is already symmetric then the returned C<$mirror_rule> will
# generate the same pattern, though its value might be different.  This
# occurs if some bits in the rule value never occur and so don't affect the
# result.
#
sub _UNDOCUMENTED__rule_to_mirror {
  my ($class, $rule) = @_;

  # 7,6,5,4,3,2,1,0
  # 1 0 1 0 0 1 0 1 = 0xA5
  return (($rule & 0xA5)

          # swap 1,1,0   ->   bit6
          #      0,1,1   ->   bit3
          | (($rule & (1<<6)) >> 3)
          | (($rule & (1<<3)) << 3)

          # swap 1,0,0   ->   bit4
          #      0,0,1   ->   bit1
          | (($rule & (1<<4)) >> 3)
          | (($rule & (1<<1)) << 3)
         );
}



#------------------------------------------------------------------------------
{
  package Math::PlanePath::CellularRule::Line;
  use strict;
  use Carp 'croak';
  use vars '$VERSION', '@ISA';
  $VERSION = 128;
  use Math::PlanePath;
  @ISA = ('Math::PlanePath');

  use Math::PlanePath::Base::Generic
    'is_infinite',
      'round_nearest';

  use constant parameter_info_array =>
    [ { name        => 'align',
        display     => 'Align',
        type        => 'enum',
        default     => 'left',
        choices     => ['left','centre','right'],
      },
      Math::PlanePath::Base::Generic::parameter_info_nstart1(),
    ];

  use constant class_y_negative => 0;
  use constant n_frac_discontinuity => .5;

  sub x_negative {
    my ($self) = @_;
    return ($self->{'align'} eq 'left');
  }
  sub x_maximum {
    my ($self) = @_;
    return ($self->{'align'} eq 'right'
            ? undef
            : 0);
  }
  sub x_negative_at_n {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? $self->n_start + 1 : undef);
  }

  use constant sumxy_minimum => 0;  # triangular X>=-Y so X+Y>=0

  sub sumxy_maximum {
    my ($self) = @_;
    return ($self->{'align'} eq 'left'
            ? 0       # left X=-Y so X+Y=0 always
            : undef);
  }

  sub diffxy_minimum {
    my ($self) = @_;
    return ($self->{'align'} eq 'right'
            ? 0       # right X=Y so X-Y=0 always
            : undef);
  }
  use constant diffxy_maximum => 0; # triangular X<=Y so X-Y<=0

  # always dX=sign,dY=+1 so dSumXY = sign+1
  sub dsumxy_minimum {
    my ($self) = @_;
    return $self->{'sign'}+1;
  }
  *dsumxy_maximum = \&dsumxy_minimum;

  # always dX=sign,dY=+1 so dDiffXY = sign-1
  sub ddiffxy_minimum {
    my ($self) = @_;
    return $self->{'sign'}-1;
  }
  *ddiffxy_maximum = \&ddiffxy_minimum;

  sub absdx_minimum {
    my ($self) = @_;
    return ($self->{'align'} eq 'centre' ? 0 : 1);
  }
  use constant absdy_minimum => 1; # dY=1 always

  sub dir_minimum_dxdy {
    my ($self) = @_;
    return ($self->dx_minimum, 1);
  }
  *dir_maximum_dxdy = \&dir_minimum_dxdy;  # same direction always

  sub dx_minimum {
    my ($self) = @_;
    return $self->{'sign'};
  }
  *dx_maximum = \&dx_minimum;  # same step always
  use constant dy_minimum => 1;
  use constant dy_maximum => 1;
  sub _UNDOCUMENTED__dxdy_list {
    my ($self) = @_;
    return ($self->{'sign'}, 1);
  }
  *_UNDOCUMENTED__dxdy_list_at_n = __PACKAGE__->can('n_start');

  # straight ahead only
  use constant turn_any_left  => 0;
  use constant turn_any_right => 0;


  #-----------------------------------------------------------
  my %align_to_sign = (left   => -1,
                       centre => 0,
                       right  => 1);
  sub new {
    my $self = shift->SUPER::new (@_);
    if (! defined $self->{'n_start'}) {
      $self->{'n_start'} = $self->default_n_start;
    }
    $self->{'align'} ||= 'left';
    $self->{'sign'} = $align_to_sign{$self->{'align'}};
    if (! defined $self->{'sign'}) {
      croak "Unrecognised align parameter: ",$self->{'align'};
    }
    return $self;
  }

  sub n_to_xy {
    my ($self, $n) = @_;
    ### CellularRule-Line n_to_xy(): $n

    $n = $n - $self->{'n_start'};   # to N=0 basis

    my $int = int($n);
    $n -= $int;   # now fraction part
    if (2*$n >= 1) {
      $n -= 1;
      $int += 1;
    }
    # -0.5 <= $n < 0.5 fractional part
    ### assert: 2*$n >= -1
    ### assert: 2*$n < 1
    ### $int

    if ($int < 0) {
      return;
    }
    if (is_infinite($int)) { return ($int,$int); }

    return ($n + $int*$self->{'sign'},
            $int);
  }

  sub n_to_radius {
    my ($self, $n) = @_;
    $n = $n - $self->{'n_start'};  # to N=0 start
    if ($n < 0) { return undef; }
    if ($self->{'align'} ne 'centre') {
      $n *= sqrt(2 + $n*0);  # inherit bigfloat etc from $n
    }
    return $n;
  }
  sub n_to_rsquared {
    my ($self, $n) = @_;
    $n = $n - $self->{'n_start'};  # to N=0 start
    if ($n < 0) { return undef; }
    $n *= $n;                      # squared
    if ($self->{'align'} ne 'centre') {
      $n *= 2;
    }
    return $n;
  }

  sub xy_to_n {
    my ($self, $x, $y) = @_;
    ### CellularRule-Line xy_to_n(): "$x,$y"

    $x = round_nearest ($x);
    $y = round_nearest ($y);
    if (is_infinite($x)) { return $x; }

    if ($y >= 0 && $x == $y*$self->{'sign'}) {
      return $y + $self->{'n_start'};
    } else {
      return undef;
    }
  }

  # not exact
  sub rect_to_n_range {
    my ($self, $x1,$y1, $x2,$y2) = @_;

    $x1 = round_nearest ($x1);
    $y1 = round_nearest ($y1);
    $x2 = round_nearest ($x2);
    $y2 = round_nearest ($y2);
    if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); } # swap to y1<=y2

    if ($y2 < 0) {
      return (1, 0);
    }
    if ($y1 < 0) { $y1 *= 0; }
    return ($y1 + $self->{'n_start'},
            $y2 + $self->{'n_start'});
  }
}

#------------------------------------------------------------------------------
{
  package Math::PlanePath::CellularRule::OddSolid;
  use strict;
  use vars '$VERSION', '@ISA';
  $VERSION = 128;
  use Math::PlanePath;
  @ISA = ('Math::PlanePath');

  use Math::PlanePath::Base::Generic
    'is_infinite',
      'round_nearest';

  use Math::PlanePath::PyramidRows;

  use constant parameter_info_array =>
    [ Math::PlanePath::Base::Generic::parameter_info_nstart1(),
    ];
  use constant class_y_negative => 0;
  use constant n_frac_discontinuity => .5;

  sub x_negative_at_n {
    my ($self) = @_;
    return $self->n_start + 1;
  }
  use constant sumxy_minimum => 0;  # triangular X>=-Y so X+Y>=0
  use constant diffxy_maximum => 0; # triangular X<=Y so X-Y<=0
  use constant dx_maximum => 2;
  use constant dy_minimum => 0;
  use constant dy_maximum => 1;
  use constant absdx_minimum => 1;
  use constant dsumxy_maximum => 2; # straight E dX=+2
  use constant ddiffxy_maximum => 2; # straight E dX=+2
  use constant dir_maximum_dxdy => (-1,0); # West, supremum

  sub new {
    my $self = shift->SUPER::new (@_);

    if (! defined $self->{'n_start'}) {
      $self->{'n_start'} = $self->default_n_start;
    }
    # delegate to sub-object
    $self->{'pyramid'}
      = Math::PlanePath::PyramidRows->new (n_start => $self->{'n_start'},
                                           step => 1);
    return $self;
  }
  sub n_to_xy {
    my ($self, $n) = @_;
    ### CellularRule-OddSolid n_to_xy(): $n
    my ($x,$y) = $self->{'pyramid'}->n_to_xy($n)
      or return;
    ### pyramid: "$x, $y"
    return ($x+round_nearest($x) - $y, $y);
  }
  sub xy_to_n {
    my ($self, $x, $y) = @_;
    ### CellularRule-OddSolid xy_to_n(): "$x,$y"
    $x = round_nearest ($x);
    $y = round_nearest ($y);
    if (($x+$y)%2) {
      return undef;
    }
    return $self->{'pyramid'}->xy_to_n(($x+$y)/2, $y);
  }

  # (y2+1)*(y2+2)/2 - 1
  # = (y2^2 + 3*y2 + 2 - 2)/2
  # = y2*(y2+3)/2

  # not exact
  sub rect_to_n_range {
    my ($self, $x1,$y1, $x2,$y2) = @_;
    ### OddSolid rect_to_n_range() ...

    $y1 = round_nearest ($y1);
    $y2 = round_nearest ($y2);

    if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); } # swap to y1<=y2
    if ($y1 < 0) { $y1 *= 0; }

    return ($y1*($y1+1)/2 + $self->{'n_start'},   # start of row, triangular+1
            $y2*($y2+3)/2 + $self->{'n_start'});  # end of row, prev triangular
  }
}

#------------------------------------------------------------------------------
{
  package Math::PlanePath::CellularRule::OneTwo;
  use strict;
  use Carp 'croak';
  use vars '$VERSION', '@ISA';
  $VERSION = 128;
  use Math::PlanePath;
  @ISA = ('Math::PlanePath');
  *_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

  use Math::PlanePath::Base::Generic
    'is_infinite',
      'round_nearest';

  # rule=6,38,134,166   sign=-1
  #    **
  #     *
  #      **
  #       *
  #
  # rule=20,52,148,180   sign=1
  #      **
  #      *
  #    **
  #    *
  #
  use constant parameter_info_array =>
    [ { name        => 'align',
        display     => 'Align',
        type        => 'enum',
        default     => 'left',
        choices     => ['left','right'],
      },
      Math::PlanePath::Base::Generic::parameter_info_nstart1(),
    ];

  use constant class_y_negative => 0;
  use constant n_frac_discontinuity => .5;

  sub x_negative {
    my ($self) = @_;
    return ($self->{'align'} eq 'left');
  }
  sub x_negative_at_n {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? $self->n_start + 1 : undef);
  }
  sub x_maximum {
    my ($self) = @_;
    return ($self->{'align'} eq 'left'
            ? 0
            : undef);
  }

  use constant sumxy_minimum => 0;  # triangular X>=-Y so X+Y>=0
  {
    my %sumxy_maximum = (left => 1);
    sub sumxy_maximum {
      my ($self) = @_;
      return $sumxy_maximum{$self->{'align'}};
    }
  }

  {
    my %diffxy_minimum = (right => -1);
    sub diffxy_minimum {
      my ($self) = @_;
      return $diffxy_minimum{$self->{'align'}};
    }
  }
  use constant diffxy_maximum => 0; # triangular X<=Y so X-Y<=0

  {
    my %dx_minimum = (left  => -2,
                      right => 0);
    sub dx_minimum {
      my ($self) = @_;
      return $dx_minimum{$self->{'align'}};
    }
  }
  use constant dx_maximum => 1;
  use constant dy_minimum => 0;
  use constant dy_maximum => 1;
  {
    my %_UNDOCUMENTED__dxdy_list = (left  => [ 1,0,    # E
                                -1,1,   # NW
                                -2,1 ], # WNW
                     right => [ 1,0,    # E
                                1,1,    # NE
                                0,1 ]); # N
    sub _UNDOCUMENTED__dxdy_list {
      my ($self) = @_;
      return @{$_UNDOCUMENTED__dxdy_list{$self->{'align'}}};
    }
  }
  {
    my %_UNDOCUMENTED__dxdy_list_at_n = (left  => 2,
                                         right => 2);
    sub _UNDOCUMENTED__dxdy_list_at_n {
      my ($self) = @_;
      return $self->n_start + $_UNDOCUMENTED__dxdy_list_at_n{$self->{'align'}};
    }
  }

  {
    my %absdx_minimum = (left  => 1,   # -2 or +1, so minimum abs is 1
                         right => 0);  # 0 or +1, so minimum abs is 0
    sub absdx_minimum {
      my ($self) = @_;
      return $absdx_minimum{$self->{'align'}};
    }
  }

  sub dsumxy_minimum {
    my ($self) = @_;
    return $self->{'sign'};
    # ? -1   # left, ENE
    # : 1);  # right, N, going as a stairstep so always increase
  }
  sub dsumxy_maximum {
    my ($self) = @_;
    return ($self->{'sign'} < 0
            ? 1   # left, East
            : 2); # right, NE diagonal
  }

  sub ddiffxy_minimum {
    my ($self) = @_;
    return ($self->{'sign'} < 0
            ? -3   # left, ENE
            : -1);  # right, N, going as a stairstep so always increase
  }
  sub ddiffxy_maximum {
    my ($self) = @_;
    return ($self->{'sign'} < 0
            ? 1   # left, East
            : 1); # right, NE diagonal
  }

  sub dir_maximum_dxdy {
    my ($self) = @_;
    return ($self->{'align'} eq 'left'
            ? (-2,1)
            : (0,1)); # North
  }

  use constant turn_any_straight => 0; # never straight


  #---------------------------------------------
  my %align_to_sign = (left  => -1,
                       right => 1);
  sub new {
    my $self = shift->SUPER::new (@_);
    if (! defined $self->{'n_start'}) {
      $self->{'n_start'} = $self->default_n_start;
    }
    $self->{'align'} ||= 'left';
    $self->{'sign'} = $align_to_sign{$self->{'align'}}
      || croak "Unrecognised align parameter: ",$self->{'align'};
    return $self;
  }

  sub n_to_xy {
    my ($self, $n) = @_;
    ### CellularRule-OneTwo n_to_xy(): $n

    $n = $n - $self->{'n_start'} + 1;  # to N=1 basis, and warn if $n undef

    my $int = int($n);
    $n -= $int;   # $n now fraction part
    if (2*$n >= 1) {
      $n -= 1;
    } else {
      $int -= 1;  # to N=0 basis
    }
    # -0.5 <= $n < 0.5 fractional part
    ### $int

    if ($int < 0) {
      return;
    }
    if (is_infinite($int)) { return ($int,$int); }

    ### assert: 2*$n >= -1   || $n+1==$n || $n!=$n
    ### assert: 2*$n < 1     || $n+1==$n || $n!=$n

    my $x = _divrem_mutate($int,3);
    $int *= 2;
    if ($x) {
      $int += 1;
      $x += ($self->{'align'} eq 'left' ? -1 : -2);
    }
    return ($n + $x + $int*$self->{'sign'},
            $int);
  }

  sub xy_to_n {
    my ($self, $x, $y) = @_;
    ### CellularRule-OneTwo xy_to_n(): "$x,$y"

    $x = round_nearest ($x);
    $y = round_nearest ($y);
    if ($y < 0) { return undef; }
    if (is_infinite($y)) { return $y; }

    $x -= $y*$self->{'sign'};
    if ($y % 2) {
      ### odd row: "x=$x y=$y"
      if ($self->{'sign'} > 0) { $x += 1; }
      if ($x < 0 || $x > 1) { return undef; }
      return (3*$y-1)/2 + $x + $self->{'n_start'};
    } else {
      ### even row: "x=$x y=$y"
      if ($x != 0) { return undef; }
      return ($y/2)*3 + $self->{'n_start'};
    }
  }

  # not exact
  sub rect_to_n_range {
    my ($self, $x1,$y1, $x2,$y2) = @_;

    $x1 = round_nearest ($x1);
    $y1 = round_nearest ($y1);
    $x2 = round_nearest ($x2);
    $y2 = round_nearest ($y2);
    if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); } # swap to y1<=y2
    if ($y2 < 0) {
      return (1, 0);
    }
    if ($y1 < 0) { $y1 *= 0; }
    if (is_infinite($y1)) { return (1, $y1+1); }
    if (is_infinite($y2)) { return (1, $y2+1); }
    $y1 -= ($y1%2);
    $y2 += ($y2%2);
    return ($y1/2*3 + $self->{'n_start'},
            $y2/2*3 + $self->{'n_start'});
  }
}

#------------------------------------------------------------------------------
{
  package Math::PlanePath::CellularRule::Two;
  use strict;
  use Carp 'croak';
  use vars '$VERSION', '@ISA';
  $VERSION = 128;
  use Math::PlanePath;
  @ISA = ('Math::PlanePath');
  *_divrem = \&Math::PlanePath::_divrem;

  use Math::PlanePath::Base::Generic
    'is_infinite',
      'round_nearest';

  # left 2 cell line rule=14,46,142,174   sign=-1
  #    **
  #     **
  #      **
  #       *
  #
  # right 2 cell line rule=84,116,212,244   sign=1
  # rule & 0x5F == 0x54
  #      **
  #     **
  #    **
  #    *
  #
  use constant parameter_info_array =>
    [ { name        => 'align',
        display     => 'Align',
        type        => 'enum',
        default     => 'left',
        choices     => ['left','right'],
      },
      Math::PlanePath::Base::Generic::parameter_info_nstart1(),
    ];

  use constant class_y_negative => 0;
  use constant n_frac_discontinuity => .5;

  sub x_negative {
    my ($self) = @_;
    return ($self->{'align'} eq 'left');
  }
  sub x_maximum {
    my ($self) = @_;
    return ($self->{'align'} eq 'left'
            ? 0
            : undef);
  }
  sub x_negative_at_n {
    my ($self) = @_;
    return ($self->{'align'} eq 'left' ? $self->n_start + 1 : undef);
  }

  use constant sumxy_minimum => 0;  # triangular X>=-Y so X+Y>=0
  {
    my %sumxy_maximum = (left => 1);
    sub sumxy_maximum {
      my ($self) = @_;
      return $sumxy_maximum{$self->{'align'}};
    }
  }

  {
    my %diffxy_minimum = (right => -1);
    sub diffxy_minimum {
      my ($self) = @_;
      return $diffxy_minimum{$self->{'align'}};
    }
  }
  use constant diffxy_maximum => 0;

  {
    my %dx_minimum = (left  => -2,
                      right => 0);
    sub dx_minimum {
      my ($self) = @_;
      return $dx_minimum{$self->{'align'}};
    }
  }
  use constant dx_maximum => 1;
  use constant dy_minimum => 0;
  use constant dy_maximum => 1;
  {
    my %_UNDOCUMENTED__dxdy_list = (left  => [ 1,0,   # E
                                -1,1,  # NW at N=1
                                -2,1,  # WNW
                              ],
                     right => [ 1,0,  # E
                                0,1,  # N
                              ]);
    sub _UNDOCUMENTED__dxdy_list {
      my ($self) = @_;
      return @{$_UNDOCUMENTED__dxdy_list{$self->{'align'}}};
    }
  }
  {
    my %_UNDOCUMENTED__dxdy_list_at_n = (left  => 2,
                                         right => 1);
    sub _UNDOCUMENTED__dxdy_list_at_n {
      my ($self) = @_;
      return $self->n_start + $_UNDOCUMENTED__dxdy_list_at_n{$self->{'align'}};
    }
  }

  {
    my %absdx_minimum = (left  => 1,   # -2 or +1, so minimum abs is 1
                         right => 0);  # 0 or +1, so minimum abs is 0
    sub absdx_minimum {
      my ($self) = @_;
      return $absdx_minimum{$self->{'align'}};
    }
  }

  # left  => -1,  # WNW dX=-2,dY=1
  # right => 1;   # N or E
  sub dsumxy_minimum {
    my ($self) = @_;
    return $self->{'sign'};
  }
  use constant dsumxy_maximum => 1; # E for left, or N or E for right

  sub ddiffxy_minimum {
    my ($self) = @_;
    return ($self->{'sign'} < 0
            ? -3   # left, ENE
            : -1);  # right, N, going as a stairstep so always increase
  }
  sub ddiffxy_maximum {
    my ($self) = @_;
    return ($self->{'sign'} < 0
            ? 1   # left, East
            : 1); # right, NE diagonal
  }

  sub dir_maximum_dxdy {
    my ($self) = @_;
    return ($self->{'align'} eq 'left'
            ? (-2,1)
            : (0,1)); # North
  }

  use constant turn_any_straight => 0; # never straight


  #---------------------------------------------
  my %align_to_sign = (left  => -1,
                       right => 1);
  sub new {
    my $self = shift->SUPER::new (@_);
    if (! defined $self->{'n_start'}) {
      $self->{'n_start'} = $self->default_n_start;
    }
    $self->{'align'} ||= 'left';
    $self->{'sign'} = $align_to_sign{$self->{'align'}}
      || croak "Unrecognised align parameter: ",$self->{'align'};
    return $self;
  }

  # N=-.5 X=-.5, Y=0
  # N=0   X=0,   Y=0
  # N=.49 X=.49, Y=0
  #
  # N=.5  X=-.5, Y=1    2N=1    Y=(2N+3)/4
  # N=1   X=0,   Y=1            X=
  # N=2   X=1,   Y=1
  # N=2.4 X=1.4, Y=1
  #
  # N=2.5  X=-.5, Y=2   2N=5
  # N=3    X=0,   Y=2
  # N=4    X=1,   Y=2
  # N=4.4  X=1.4, Y=2
  #
  sub n_to_xy {
    my ($self, $n) = @_;
    ### CellularRule-Two n_to_xy(): $n

    $n = 2*($n - $self->{'n_start'});  # to N=0 basis, and warn if $n undef
    if ($n < -1) { return; }

    my ($y, $x) = _divrem ($n+3, 4);
    if ($y == 0) { $x += $self->{'sign'} - 1; }
    return (($x - $self->{'sign'} - 2)/2 + $y*$self->{'sign'},
            $y);
  }

  sub xy_to_n {
    my ($self, $x, $y) = @_;
    ### CellularRule-Two xy_to_n(): "$x,$y"

    $x = round_nearest ($x);
    $y = round_nearest ($y);
    if ($y < 0) { return undef; }
    if (is_infinite($y)) { return $y; }

    if ($self->{'align'} eq 'left') {
      $x += $y;
      if ($y) { $x -= 1; }
    } else {
      $x -= $y;
    }
    if ($x < ($y ? -1 : 0) || $x > 0) {
      return undef;
    }

    return 2*$y + $x + $self->{'n_start'};
  }

  # not exact
  sub rect_to_n_range {
    my ($self, $x1,$y1, $x2,$y2) = @_;
    ### CellularRule-Two rect_to_n_range() ...

    $x1 = round_nearest ($x1);
    $y1 = round_nearest ($y1);
    $x2 = round_nearest ($x2);
    $y2 = round_nearest ($y2);
    if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); } # swap to y1<=y2
    if ($y2 < 0) {
      return (1, 0);
    }
    if ($y1 < 0) { $y1 *= 0; }
    ### $y1
    ### $y2

    if (is_infinite($y1)) { return (1, $y1); }
    if (is_infinite($y2)) { return (1, $y2); }
    return (2*$y1 + $self->{'n_start'} - ($y1 == 0 ? 0 : 1),
            2*$y2 + $self->{'n_start'});
  }
}

1;
__END__


# For reference the specifics currently are
#
#     54                              CellularRule54
#     57,99                           CellularRule57
#     190,246                         CellularRule190
#     18,26,82,90,146,154,210,218     SierpinskiTriangle n_start=1
#     151,159,183,191,215,223,247,    PyramidRows step=2
#       254,222,255
#     220,252                         PyramidRows step=1
#     206,238                         PyramidRows step=1 left
#     4,12,36,44,68,76,100,108,132,   Rows width=1
#       140,164,172,196,204,228,236     single-cell column



=for stopwords Ryde Math-PlanePath PlanePath ie Xmax-Xmin superclass eg OEIS MathWorld

=head1 NAME

Math::PlanePath::CellularRule -- cellular automaton points of binary rule

=head1 SYNOPSIS

 use Math::PlanePath::CellularRule;
 my $path = Math::PlanePath::CellularRule->new (rule => 30);
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Wolfram, Stephen>This is the patterns of Stephen Wolfram's bit-rule
cellular automatons

=over

L<http://mathworld.wolfram.com/ElementaryCellularAutomaton.html>

=back

Points are numbered left to right in rows so for example

    rule => 30

    51 52    53 54 55 56    57 58       59          60 61 62       9
       44 45       46          47 48 49                50          8
          32 33    34 35 36 37       38 39 40 41 42 43             7
             27 28       29             30       31                6
                18 19    20 21 22 23    24 25 26                   5
                   14 15       16          17                      4
                       8  9    10 11 12 13                         3
                          5  6        7                            2
                             2  3  4                               1
                                1                              <- Y=0

    -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8  9

The automaton starts from a single point N=1 at the origin and grows into
the rows above.  The C<rule> parameter controls how the 3 cells below and
diagonally below produce a new cell,

             +-----+
             | new |              next row, Y+1
             +-----+
            ^   ^   ^
          /     |     \
         /      |      \
    +-----+  +-----+  +-----+
    |  A  |  |  B  |  |  C  |     row Y
    +-----+  +-----+  +-----+

There's 8 combinations of ABC being each 0 or 1.  Each such combination can
become 0 or 1 in the "new" cell.  Those 0 or 1 for "new" is encoded as 8
bits to make a rule number 0 to 255,

    ABC cells below     new cell bit from rule

           1,1,1   ->   bit7
           1,1,0   ->   bit6
           1,0,1   ->   bit5
           ...
           0,0,1   ->   bit1
           0,0,0   ->   bit0

When cells 0,0,0 become 1, ie. C<rule> bit0 is 1 (an odd number), the "off"
cells either side of the initial N=1 become all "on" infinitely to the
sides.  Or if rule bit7 for 1,1,1 is a 0 (ie. S<rule E<lt> 128>) then they
turn on and off alternately in odd and even rows.  In both cases only the
pyramid portion part -YE<lt>=XE<lt>=Y is considered for the N points but the
infinite cells to the sides are included in the calculation.

The full set of patterns can be seen at the MathWorld page above, or can be
printed with the F<examples/cellular-rules.pl> here.  The patterns range
from simple to complex.  For some, the N=1 cell doesn't grow at all such as
rule 0 or rule 8.  Some grow to mere straight lines such as rule 2 or
rule 5.  Others make columns or patterns with "quadratic" style stepping of
1 or 2 rows, or self-similar replications such as the Sierpinski triangle of
rule 18 and 60.  Some rules have complicated non-repeating patterns when
there's feedback across from one half to the other, such as rule 30.

For some rules there's specific PlanePath code which this class dispatches
to, such as C<CellularRule54>, C<CellularRule57>, C<CellularRule190> or
C<SierpinskiTriangle> (with C<n_start=1>).

For rules without specific code, the current implementation is not
particularly efficient as it builds and holds onto the bit pattern for all
rows through to the highest N or X,Y used.  There's no doubt better ways to
iterate an automaton, but this module offers the patterns in PlanePath
style.

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, in the same pattern.  For example to
start at 0,

=cut

# math-image --path=CellularRule,rule=62,n_start=0 --all --output=numbers --size=75x6

=pod

    n_start => 0, rule => 62

    18 19    20 21    22    23 24 25          5
       13 14    15 16          17             4
           7  8     9 10 11 12                3
              4  5        6                   2
                 1  2  3                      1
                    0                     <- Y=0

    -5 -4 -3 -2 -1 X=0 1  2  3  4  5

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::CellularRule-E<gt>new (rule =E<gt> 123)>

=item C<$path = Math::PlanePath::CellularRule-E<gt>new (rule =E<gt> 123, n_start =E<gt> $n)>

Create and return a new path object.  C<rule> should be an integer 0 to 255.
A C<rule> should be given always.  There is a default, but it's secret and
likely to change.

If there's specific PlanePath code implementing the pattern then the
returned object is from that class and generally is not
C<isa('Math::PlanePath::CellularRule')>.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are each
rounded to the nearest integer, which has the effect of treating each cell
as a square of side 1.  If C<$x,$y> is outside the pyramid or on a skipped
cell the return is C<undef>.

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path can be found in the OEIS index

=over

L<http://oeis.org/wiki/Index_to_OEIS:_Section_Ce#cell>

=back

and in addition the following

=over

L<http://oeis.org/A061579> (etc)

=back

    rule=50,58,114,122,178,186,242,250, 179
      (solid every second cell)
      A061579     permutation N at -X,Y (mirror horizontal)

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::CellularRule54>,
L<Math::PlanePath::CellularRule57>,
L<Math::PlanePath::CellularRule190>,
L<Math::PlanePath::SierpinskiTriangle>,
L<Math::PlanePath::PyramidRows>

L<Cellular::Automata::Wolfram>

L<http://mathworld.wolfram.com/ElementaryCellularAutomaton.html>

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
