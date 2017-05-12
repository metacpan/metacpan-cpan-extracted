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

# use strict;
# use warnings;
# use blib "$ENV{HOME}/p/other/File-Map-0.23/blib";
# use File::Map;
# print File::Map->VERSION,"\n";

use File::Map 'map_file';

my @array;
map_file ($array[1], '/etc/motd', '<');
print $array[1];

# my %hash;
# map_file ($hash{'foo'}, '/etc/motd', '<');
# print $hash{'foo'};
