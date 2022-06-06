# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

package Math::NumSeq::PrimeQuadraticHonaker;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');

use constant name => Math::NumSeq::__('Prime Generating Quadratic of Honaker');
use constant description => Math::NumSeq::__('The quadratic numbers 4*k^2 + 4*k + 59.');
use constant values_min => 59;
use constant characteristic_increasing => 2;

# http://oeis.org/A048988  # only the primes ones
# use constant oeis_anum => undef;


sub ith {
  my ($self, $i) = @_;
  return 4*($i + 1)*$i + 59;
}
sub pred {
  my ($self, $n) = @_;
  return ($n >= 59
          && do {
            my $i = sqrt((1/4) * $n - 29/2) -1/2;
            ($i==int($i))
          });
}

1;
__END__
