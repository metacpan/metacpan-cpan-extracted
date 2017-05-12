#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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

print "malloc_info() from the GNU C Library:\n";
defined &Devel::Mallinfo::malloc_info_string
  or die "malloc_info() not available";

my $str = Devel::Mallinfo::malloc_info_string(0);
defined $str
  or die "Cannot get malloc_info(): $!";

$str =~ /system type="max" size="(\d+)/
  or die "oops, cannot parse malloc_info() output";

print "  peak memory use so far is $1\n";
exit 0;
