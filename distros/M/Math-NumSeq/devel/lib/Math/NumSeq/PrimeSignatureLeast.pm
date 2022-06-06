# prime factor exponents non-increasing




# Copyright 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

package Math::NumSeq::PrimeSignatureLeast;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;

use Math::NumSeq;
use Math::NumSeq::Base::IteratePred;
@ISA = ('Math::NumSeq',
        'Math::NumSeq::Base::IteratePred');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Primes;
use Math::NumSeq::Squares;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('...');
use constant default_i_start => 1;
use constant values_min => 1;

#------------------------------------------------------------------------------
# cf A046523 least with same prime sig as n
#
# use constant oeis_anum => undef;


#------------------------------------------------------------------------------

sub pred {
  my ($self, $value) = @_;
  ### PrimeSignatureLeast pred(): "$value"

  if (_is_infinite($value)) {
    return undef;
  }
  if ($value < 1) {
    return 0;
  }

  my $k = 0;
  until ($value % 2) {
    $value /= 2;
    $k++;
  }
  if ($k == 0 || ($k == 1 && $value > 1)) {
    return 0;
  }

  my $limit = sqrt($value);
  for (my $p = 3; $p <= $limit; $p += 2) {
    if ($p > 65536) {
      return undef;
    }
    next if $value % $p;   # if not a prime factor

    ### $p
    my $count = 1;
    while (($value % $p) == 0) {
      $value /= $p;
      if (++$count > $k) {
        return 0;
      }
    }
    $k = $count;
    if ($k == 1) {
      if ($value > 1) {
        return 0;
      }
    }
    $limit = sqrt($value);
  }
  return 1;
}

1;
__END__
