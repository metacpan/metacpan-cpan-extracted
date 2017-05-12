#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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

use 5.006;
use strict;
use warnings;
use FindBin;
use File::Locate::Iterator;

chdir $FindBin::Bin or die;
open my $out, '>', 'neg.locatedb' or die;
print $out "\0LOCATE02\0" or die;
print $out "\200\200\000foo\0" or die;
close $out or die;

my $it = File::Locate::Iterator->new (database_file => 'neg.locatedb',
                                     );
while (my ($str) = $it->next) {
  print "got '$str'\n";
}

exit 0;


