#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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

use 5.006;
use strict;
use warnings;

use FindBin;
my $progname = $FindBin::Script;
use lib $FindBin::Bin;

our $in_progress = 0;
sub hook {
  my ($self, $filename) = @_;

  print "hook $filename in_progress=$in_progress\n";
  if ($filename eq 'Foo.pm' && ! $in_progress) {
    local $in_progress = 1;
    print "hook require Foo\n";
    require Foo;
    print "  done hook require Foo\n";
  }
  return;
}
unshift @INC, \&hook;

print "require\n";
require Foo;
print "require done\n";
