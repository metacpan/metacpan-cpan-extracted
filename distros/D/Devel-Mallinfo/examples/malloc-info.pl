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


# In a real program be aware that the FILE* interface in malloc_info() may
# bypass perlio layers on STDOUT (or whatever handle given), and may turn
# off a utf8 flag there too.

use strict;
use Devel::Mallinfo;

print "malloc_info() from the GNU C Library:\n";
if (defined &Devel::Mallinfo::malloc_info) {
  Devel::Mallinfo::malloc_info(0,\*STDOUT);
} else {
  print "  not available\n";
}

exit 0;
