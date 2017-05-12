#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of Devel-Mallinfo.
#
# Devel-Mallinfo is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Devel-Mallinfo is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Devel-Mallinfo.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use Devel::Mallinfo;

{
  select STDERR;
  $| = 1;
  print "STDERR autoflush is ",$|,"\n";
  select STDOUT;
  print "STDOUT autoflush is ",$|,"\n";
}

my $h = Devel::Mallinfo::mallinfo;
require Data::Dumper;
print Data::Dumper->new([$h],['h'])->Sortkeys(1)->Dump;

print "\n";
if (defined &Devel::Mallinfo::malloc_stats) {
  print "malloc_stats()\n";
  $| = 1;
  Devel::Mallinfo::malloc_stats();
} else {
  print "malloc_stats() not available\n";
}

print "\n";
$h = Devel::Mallinfo::mallinfo;
print Data::Dumper->new([$h],['h'])->Sortkeys(1)->Dump;

exit 0;
