# Copyright 2012, 2013, 2014 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.


package Math::NumSeq::Pow2Mod10;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 72;
use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::NumAronson 8; # new in v.8
*_round_down_pow = \&Math::NumSeq::NumAronson::_round_down_pow;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Numbers which are 2^j mod 10^k for some j,k.');
use constant default_i_start => 1;
use constant values_min => 1;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;


#------------------------------------------------------------------------------
use constant oeis_anum => 'A095810';

#------------------------------------------------------------------------------

# 2^j = q * 10^k + r
#
# Cannot have r multiple of 5, as then RHS a multiple of 5.
#
# Must have r a multiple of 2^k.  q*10^k for q>=1 is a multiple of 2^k, so r
# multiple 2^k otherwise RHS is !=0 mod 2^k.  When q>=1 have j>=k.  If q=0
# then r=2^j exactly.
#

sub rewind {
  my ($self) = @_;
  $self->{'k'} = 0;
  $self->{'power'} = 1;
  $self->{'limit'} = 1;
  $self->{'value'} = 0;
  $self->{'step'} = 1;
  $self->{'skip'} = 1;
  $self->{'i'} = $self->i_start;
}

sub next {
  my ($self) = @_;
  ### next(): "i=$self->{'i'} value=$self->{'value'}"

  my $value = ($self->{'value'} += $self->{'step'});
  ### new value: $value

  if (++$self->{'skip'} >= 5) {
    $value = ($self->{'value'} += $self->{'step'});
    $self->{'skip'} = 1;
    ### extra skip: $value
  }

  if ($value > $self->{'limit'}) {
    ### past limit ...

    my $power = $self->{'power'};
    $value = $power + $self->{'step'};  # old step
    my $step = ($self->{'step'} *= 2);  # new step
    $power = ($self->{'power'} *= 10);  # new power
    $self->{'limit'} = $power - $step;
    $self->{'skip'} = ($value / $step) % 5;

    ### new limit ...
    ### $power
    ### $value
    ### $step
    ### skip: $self->{'skip'}
    ### limit: $self->{'limit'}
    ### assert: ($value % $step) == 0
    ### assert: ($value % 5) != 0
  }
  return ($self->{'i'}++, $value);
}

# N is not a power of 2
#   if and only if
#   -- the number given by those digits is divisible by 5
#   -- OR not a multiple of 2^k
#   -- OR a value > 2^k*(5^k-1)
# Francisco Salinas
#
# N is a power of 2
#   if and only if
#   -- the value not divisible by 5
#   -- AND value a multiple of 2^k
#   -- AND value <= 2^k*(5^k-1)
#
# 1, 2, 4, 6, 8, 12, 16, 24, 28, 32, 36, 44, 48, 52, 56, 64, 68, 72, 76,    
#
# In range N=100 to N=999 multiples of 2^2=4, not multiples of 5, to <=100-4.
#
sub pred {
  my ($self, $value) = @_;

  if (_is_infinite($value)) {
    return undef;
  }
  unless ($value == int($value)) {
    return 0;
  }
  if ($value == 1) {
    return 1;
  }
  if (($value % 5) == 0) {
    return 0;
  }
  my ($pow10, $k) = _round_down_pow ($value, 10);
  $k += 1;
  my $pow2 = 2**$k;
  if ($value % $pow2) {
    return 0;
  }
  if ($value > 10*$pow10 - $pow2) {
    return 0;
  }
  return 1;
}

1;
__END__
