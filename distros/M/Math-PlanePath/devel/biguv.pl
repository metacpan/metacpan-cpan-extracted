#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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

use 5.004;
use strict;
use Inline 'C';
use Math::BigInt try => 'GMP';


# uncomment this to run the ### lines
use Smart::Comments;

my $big = - Math::BigInt->new(2) ** 65;
### $big
print "big ",ref $big,"\n";

my $uv = touv($big);
print "touv $uv\n";

my $nv = $big->numify;
print "as_number $nv\n";

exit 0;


__END__
__C__
unsigned touv(unsigned n) {
  return n;
}
