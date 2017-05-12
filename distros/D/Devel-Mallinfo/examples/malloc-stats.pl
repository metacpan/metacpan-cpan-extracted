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

# malloc_stats() goes to stderr, send prints the same
print STDERR "malloc_stats() from the GNU C Library:\n";
if (defined &Devel::Mallinfo::malloc_stats) {
  Devel::Mallinfo::malloc_stats();
} else {
  print STDERR "  not available\n";
}

exit 0;
