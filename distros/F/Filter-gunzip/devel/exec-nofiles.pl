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
  require Filter::exec;

  { my ($soft, $hard) = getrlimit(BSD::Resource::RLIMIT_NOFILE);
    print "RLIMIT_NOFILE $soft $hard\n"; }

  setrlimit(BSD::Resource::RLIMIT_NOFILE, 0, 0)
    or die "cannot setrlimit: $!";

  { my ($soft, $hard) = getrlimit(BSD::Resource::RLIMIT_NOFILE);
    print "RLIMIT_NOFILE $soft $hard\n"; }
}

BEGIN { eval "use Filter::exec 'cat';" }
print "filtered code\n";
exit 0;
