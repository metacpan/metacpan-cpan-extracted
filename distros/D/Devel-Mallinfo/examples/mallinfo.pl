#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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


# Usage: perl info.pl
#
# Print the hash of information returned by Devel::Mallinfo::mallinfo().
#
# In this program mallinfo() is the first thing done, so the values will be
# near the minimum for any Perl program.  You can see how many megs your
# actual program and libraries add to it!
#
# The printf has a hard-coded 10 chars for the names and 7 for the values,
# but you could find the widest of each at runtime if you wanted.

use strict;
use Devel::Mallinfo;

my $h = Devel::Mallinfo::mallinfo();
print "mallinfo:\n";
my $field;
foreach $field (sort keys %$h) {
  printf "  %-10s  %7d\n", $field, $h->{$field};
}

print "\n";
print "or the same printed with Data::Dumper,\n";
require Data::Dumper;
print Data::Dumper->new([$h],['hashref'])->Sortkeys(1)->Indent(1)->Dump;

exit 0;
