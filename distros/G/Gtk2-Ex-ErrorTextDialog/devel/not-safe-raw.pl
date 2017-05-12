#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-ErrorTextDialog.
#
# Gtk2-Ex-ErrorTextDialog is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ErrorTextDialog is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ErrorTextDialog.  If not, see <http://www.gnu.org/licenses/>.



# __WARN__ handler can run with compilation errors in force.
#

use 5.008;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;

$SIG{__WARN__} = sub {
  my ($msg) = @_;
  print "my warn handler(): $msg\n";
  print "my warn handler(): now loading Quux\n";
  print "\n";
  require UsingBegin;
  return 1;
};

print "loading MyRunawayWarnAndError\n";
if (! eval { require MyRunawayWarnAndError }) {
  my $msg = $@;
  print "my load(): $msg\n";
}

print "done\n";
