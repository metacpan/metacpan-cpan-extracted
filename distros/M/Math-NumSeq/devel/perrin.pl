#!/usr/bin/perl -w

# Copyright 2010, 2012 Kevin Ryde

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

use strict;
my $x = 451659150174378.0;
my $y = 598320986789900.0;
my $z = $x + $y;
print "$z\n";
printf ("%.20g\n", $z);
printf ("%f\n", $z);
my $k = "1049980136964278";
print $z==$k;
# /* 1.04998013696428e+15 */
