# Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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

package Math::NumSeq::OEIS::Catalogue::Plugin::SqrtDigits;
use 5.004;
use strict;
use List::Util 'max'; # FIXME: 5.6 only, maybe

use vars '@ISA';
use Math::NumSeq::OEIS::Catalogue::Plugin::FractionDigits;
@ISA = ('Math::NumSeq::OEIS::Catalogue::Plugin::FractionDigits');

use vars '$VERSION';
$VERSION = 72;

# uncomment this to run the ### lines
use Smart::Comments;

use constant num_first => 10467;
use constant num_last  => 10550;

sub make_info {
  my ($class, $num) = @_;
  ### SqrtDigits make_info(): $num
  # num = S - sqrt(S)
  my $sqrt = $num + (-10467 + 10);
  ### $sqrt
  $sqrt += max (0, int(sqrt($sqrt)) - 3);
  return { num => $num,
           class => 'Math::NumSeq::SqrtDigits',
           parameters => [ sqrt  => $sqrt, radix => 10 ] };
}

1;
__END__

