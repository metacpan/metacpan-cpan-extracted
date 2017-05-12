#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde.
#
# This file is part of File-Locate-Iterator.
#
# File-Locate-Iterator is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# File-Locate-Iterator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with File-Locate-Iterator; see the file COPYING.  Failing that, go to
# <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Devel::Peek;
use FindBin;
# use lib::abs $FindBin::Bin;
use File::Spec;

use File::Map 'map_file';

my $filename;
$filename = '/tmp/x';
$filename = '/proc/meminfo';
$filename = File::Spec->devnull;
$filename = '/dev/zero';

my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
    $atime,$mtime,$ctime,$blksize,$blocks)
  = stat($filename);
printf "%o\n", $mode;

my $str;
map_file ($str, $filename, '<', 0, 0);
print "length ",length($str),"\n";

# open
exit 0;
