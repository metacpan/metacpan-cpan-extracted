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

use strict;
use warnings;
use POSIX;

BEGIN {
  $ENV{'LANG'} = 'de_DE';
  $ENV{'LANGUAGE'} = 'de';
#   setlocale(LC_ALL,'');
#   print setlocale(LC_NUMERIC),"\n";
}

use Gtk2 '-init';
BEGIN {
  print "after -init ",setlocale(LC_NUMERIC),"\n";
}
require Gtk2::Ex::ErrorTextDialog;
BEGIN {
  print "main after ErrText ",setlocale(LC_NUMERIC),"\n";
}

print 1.5,"\n";
print Locale::TextDomain->VERSION,"\n";
Locale::TextDomain->VERSION(1.16);

print "running ",setlocale(LC_NUMERIC),"\n";








# BEGIN {
#   use POSIX;
#   print "ErrText module ",setlocale(LC_NUMERIC),"\n";
# }
# BEGIN {
#   use POSIX;
#   print "  after ",setlocale(LC_NUMERIC)," ",setlocale(LC_MESSAGES),"\n";
# }
E
