#!/usr/bin/perl -w

# Copyright 2010, 2011, 2014, 2019 Kevin Ryde

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

use 5.006;
use strict;
use warnings;
$|=1;

BEGIN {
  require Filter::gunzip;
  print "diagnostics\n";

  my $filters = Filter::gunzip::_rsfp_filters();
  print "PL_rsfp_filters aref = ",(defined $filters ? "$filters" : '[undef]'), "\n";
  if (defined $filters) {
    print "  length ",scalar(@$filters), "\n";
  }

  my $fh = Filter::gunzip::_rsfp();
  print "PL_rsfp = ",$fh;
  if (defined $fh) {
    my @layers = PerlIO::get_layers($fh);
    print "  layers: ",join(' ',@layers), "\n";
    print "  ftell:  ",tell($fh), "\n";
  }
  undef $fh;
}

print "mainline\n";

BEGIN {
  print "final BEGIN\n";
}
CHECK {
  print "CHECK block\n";
}
