# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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


# Christopher Williamson, "An Overview of the Thue-Morse Sequence",
# www.math.washington.edu/~morrow/336_12/papers/christopher.pdf


package Math::NumSeq::DigitLengthModulo;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::DigitLength;

# uncomment this to run the ### lines
#use Smart::Comments;


use Math::NumSeq::Base::Digits;
use constant parameter_info_array =>
  [ Math::NumSeq::Base::Digits->parameter_info_list,
    { name        => 'modulus',
      share_key   => 'modulus_0',
      type        => 'integer',
      display     => Math::NumSeq::__('Modulus'),
      default     => 0,
      minimum     => 0,
      width       => 3,
      description => Math::NumSeq::__('Modulus, or 0 to use the radix.'),
    },
  ];

use constant i_start => 0;
use constant characteristic_smaller => 1;
use constant characteristic_integer => 1;
use constant values_min => 0;
sub values_max {
  my ($self) = @_;
  if (my $modulus = $self->{'modulus'}) {
    return $modulus;
  }
  return $self->{'radix'} - 1;
}

# use constant name => Math::NumSeq::__('Digit Length Modulo');
use constant description => Math::NumSeq::__('Length in digits in the given radix, then modulo that radix or a given modulus.');

my @oeis_anum = (
                 # OEIS-Catalogue array begin
                 undef,
                 undef,

                 # OEIS-Catalogue array end
                );
sub oeis_anum {
  my ($self) = @_;
  if ($self->{'modulus'} == 1) {
    return 'A000004'; # all zeros
  }
  return $oeis_anum[$self->{'radix'}];
}

sub ith {
  my ($self, $i) = @_;
  my $radix = $self->{'radix'};

  if (_is_infinite ($i)) {
    return $i;
  }

  my $value = $self->Math::NumSeq::DigitLength::ith($i);
  if (my $modulus = $self->{'modulus'}) {
    return $value % $modulus;
  }
  return $value % $radix;
}

sub pred {
  my ($self, $value) = @_;
  return ($value == int($value)
          && $value >= 0
          && $value <= $self->values_max);
}

1;
__END__
