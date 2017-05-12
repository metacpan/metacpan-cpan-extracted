#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of File-Locate-Iterator.
#
# File-Locate-Iterator is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# File-Locate-Iterator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with File-Locate-Iterator.  If not, see <http://www.gnu.org/licenses/>.

# print "perl $]\n";


use strict;
use warnings;
use File::Map 0.27;

my $string = 'abc';

my $fh;
open $fh, '<', \$string
  or die "oops, cannot open string";

my $mmap;
File::Map::map_handle ($mmap, $fh);

if ($mmap =~ /^xx/) {
  print "match\n";
} else {
  print "no match\n";
}
