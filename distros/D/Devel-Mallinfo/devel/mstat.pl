#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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
use warnings;
use Config;
use Devel::Peek;

foreach (qw(usemymalloc)) {
  print "$_ $Config::Config{$_}\n";
}
# my %h;
# mstats_fillhash(%h, 1);
# print keys %h,"\n";

exit 0;
