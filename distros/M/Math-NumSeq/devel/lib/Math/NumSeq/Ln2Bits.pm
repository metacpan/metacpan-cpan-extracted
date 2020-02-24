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

package Math::NumSeq::Ln2Bits;
use 5.004;
use strict;

use Math::NumSeq;
use base 'Math::NumSeq::PiBits';

use vars '$VERSION';
$VERSION = 74;

use constant name => Math::NumSeq::__('Log(2) Bits');
use constant description => Math::NumSeq::__('Natural log(2), being 0.693147..., written out in binary.');
use constant values_min => 0;
use constant characteristic_increasing => 1;

# A002391 - log3 decimal

# log(2) = Sum_{ k >= 1 } 1/(k*2^k) = Sum_{j >= 1} (-1)^(j+1)/j
# 'A002162' # 10
# A016730 continued fraction

sub new {
  my $class = shift;
  return $class->SUPER::new (file => 'ln2', @_);
}

1;
__END__

