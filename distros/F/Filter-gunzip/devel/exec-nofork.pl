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

BEGIN {
  use BSD::Resource;

  { my ($soft, $hard) = getrlimit(BSD::Resource::RLIMIT_NPROC);
    print "RLIMIT_NPROC $soft $hard\n"; }

  setrlimit(BSD::Resource::RLIMIT_NPROC, 0, 0)
    or die "cannot setrlimit: $!";

  { my ($soft, $hard) = getrlimit(BSD::Resource::RLIMIT_NPROC);
    print "RLIMIT_NPROC $soft $hard\n"; }

  my $pid = fork();
  if (defined $pid) {
    print "fork pid $pid\n";
  } else {
    print "cannot fork: $!\n";
  }
}


use Filter::exec 'cat';
print "filtered code\n";
exit 0;
