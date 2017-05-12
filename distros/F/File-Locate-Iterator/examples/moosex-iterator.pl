#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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


# Using the MooseX::Iterator::Locate module.

use strict;
use warnings;
use MooseX::Iterator::Locate;

my $it = MooseX::Iterator::Locate->new (glob => '*.c');
my $count = 0;

while ($it->has_next) {
  print $it->next,"\n";

  if ($count++ > 10) {
    print "...\n";
    last;
  }
}
exit 0;
