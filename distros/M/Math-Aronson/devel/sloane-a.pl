#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Math-Aronson.
#
# Math-Aronson is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Aronson is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Aronson.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

# http://www.cs.uwaterloo.ca/journals/JIS/index.html
# http://arxiv.org/abs/math.NT/0305308
#
# a(1) = 1, a(2) = 4, then a(9*2^k-3+j) = 12*2^k-3+3*j/2+|j|/2
#  for k>=0, -3*2^k <= j <= 3*2^k.
#
#  Also a(3n) = 3*b(n/3), a(3n+1) = 2*b(n)+b(n+1), a(3n+2) = b(n)+2*b(n+1) for n>=2, where b = A079905. - N. J. A. Sloane (njas(AT)research.att.com) and Ben Cloitre, Feb 20, 2003

foreach my $k (0 .. 5) {
  print "k=$k\n";
  foreach my $j ((-3 * 2**$k) .. (3 * 2**$k - 1)) {
    my $i = 9 * 2**$k - 3 + $j;
    my $a = 12*2**$k - 3 + (3*$j + abs($j))/2;
    print "$i  $a\n";
  }
}

# a(1) = 1, a(2) = 4, then
#  for k>=0, -3*2^k <= j <= 3*2^k.
