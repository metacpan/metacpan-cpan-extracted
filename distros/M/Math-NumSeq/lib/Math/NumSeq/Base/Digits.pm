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

package Math::NumSeq::Base::Digits;
use 5.004;
use strict;

use vars '$VERSION', '@ISA', '@EXPORT_OK';
$VERSION = 74;

use Exporter;
use Math::NumSeq;
@ISA = ('Math::NumSeq', 'Exporter');
@EXPORT_OK = ('parameter_info_array');

sub characteristic_digits {
  my ($self) = @_;
  return $self->{'radix'};
}
use constant characteristic_increasing => 0;
# use constant characteristic_non_decreasing => 0;
use constant characteristic_smaller => 1;
use constant characteristic_integer => 1;
use constant values_min => 0;
sub values_max {
  my ($self) = @_;
  return $self->{'radix'} - 1;
}

use constant parameter_common_radix =>
  { name    => 'radix',
    type    => 'integer',
    display => Math::NumSeq::__('Radix'),
    default => 10,
    minimum => 2,
    width   => 3,
    description => Math::NumSeq::__('Radix, ie. base, for the values calculation.  Default is decimal (base 10).'),
  };
use constant parameter_info_array => [ parameter_common_radix() ];

sub pred {
  my ($self, $value) = @_;
  return ($value == int($value)
          && $value >= 0
          && $value < $self->{'radix'});
}

1;
__END__
