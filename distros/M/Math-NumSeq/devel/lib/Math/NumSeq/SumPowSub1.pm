# Copyright 2013, 2014, 2016 Kevin Ryde

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


package Math::NumSeq::SumPowSub1;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq',
        'Math::NumSeq::Base::IterateIth');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Repdigits;
*_digit_split_lowtohigh = \&Math::NumSeq::Repdigits::_digit_split_lowtohigh;

use Math::NumSeq::NumAronson;
*_round_down_pow = \&Math::NumSeq::NumAronson::_round_down_pow;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__();
use constant description => Math::NumSeq::__('Sums of 2^k-1');
use constant default_i_start => 0;
use constant characteristic_integer => 1;
use constant values_min => 0;

use constant parameter_info_array =>
  [ { name      => 'radix',
      share_key => 'radix_2',
      type      => 'integer',
      display   => Math::NumSeq::__('Radix'),
      default   => 2,
      minimum   => 2,
      width     => 3,
      description => Math::NumSeq::__('Radix, ie. base, for the values calculation.  Default is binary (base 2).'),
    } ];

#------------------------------------------------------------------------------
# cf A079559 characteristic 1,0
#    A055938 not sums of 2^k-1

my @oeis_anum;
$oeis_anum[2] = 'A005187';
# OEIS-Catalogue: A005187
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}


#------------------------------------------------------------------------------

# radix=2   1, 3,  7, 15
# radix=3   2, 8, 26, 80, 242, 728
#   818 = 728 + 80 + 8 + 2
#

sub ith {
  my ($self, $i) = @_;
  ### SumPowSub1 ith(): "$i"

  if ($i <= 0) {
    if ($i == 0) {
      return 0;
    }
    return undef;
  }
  if (_is_infinite($i)) {
    return $i;
  }
  my $pow = $self->{'radix'} + $i*0;
  my $value = 0;
  foreach my $bit (_digit_split_lowtohigh($i,2)) {
    if ($bit) {
      $value += $pow;
      $value -= 1;
    }
    $pow *= $self->{'radix'};
  }
  return $value;
}

sub pred {
  my ($self, $value) = @_;
  ### SumPowSub1 pred(): "$value"

  if (_is_infinite($value)) {
    return undef;
  }
  if ($value != int($value) || $value < 0) {
    return 0;
  }

  my $radix = $self->{'radix'};
  my ($pow, $exp) = _round_down_pow ($value+1, $radix);
  while (--$exp >= 0) {
    ### at: "pow=$pow exp=$exp consider ".($pow-1)
    if ($value >= $pow-1) {
      $value -= $pow-1;
      if ($value >= $pow-1) {
        return 0;
      }
    }
    $pow /= $radix;
  }
  return ($value == 0);
}

1;
__END__

