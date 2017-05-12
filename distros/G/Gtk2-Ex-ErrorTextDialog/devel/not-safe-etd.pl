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
use Gtk2 '-init';
use Data::Dumper;

use Gtk2::Ex::ErrorTextDialog::Handler;
$SIG{'__WARN__'} = \&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler;
Glib->install_exception_handler
  (\&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler);

print "loading MyRunawayWarnAndError\n";
if (! eval { require MyRunawayWarnAndError }) {
  my $msg = $@;
  print "my load(): $msg\n";
  my $filename = 'Gtk2/Ex/ErrorTextDialog.pm';
  if (! exists $INC{$filename}) {
    print "INC{$filename} doesn't exist\n";
  } elsif (! defined $INC{$filename}) {
    print "INC{$filename} undef\n";
  } else {
    print "INC{$filename} '$INC{$filename}'\n";
  }
  print "outermost handler run\n";
  Gtk2::Ex::ErrorTextDialog::Handler::exception_handler($msg);
}

warn "Look to your orb";
print "main loop\n";
Gtk2->main;






#   use Devel::StackTrace;
#   my $stacktrace = Devel::StackTrace->new;
#   print STDERR "\n\n".$stacktrace->as_string."\n";
