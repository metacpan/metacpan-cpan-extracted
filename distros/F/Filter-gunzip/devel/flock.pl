#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Filter-gunzip.
#
# Filter-gunzip is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Filter-gunzip is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Filter-gunzip.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Fcntl;

print "flock\n";
flock DATA, Fcntl::LOCK_EX()
  or die "$!";

if (fork() == 0) {
  print "flock again\n";
  flock DATA, Fcntl::LOCK_EX()
    or die "$!";
} else {
  sleep 3;
}

__DATA__
abc
