#!/usr/bin/perl

# Copyright 2009 Kevin Ryde

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

package Foo;
our $begin_done;
BEGIN {
  print "Foo begin @{[$begin_done//0]} @{[$INC{'Foo.pm'}]}\n";
  $begin_done = 1;
  # $INC{'Foo.pm'} = 'hello';
}

our $run_done;
print "Foo runs @{[$run_done//0]} @{[$INC{'Foo.pm'}]}\n";
$run_done = 1;
# $INC{'Foo.pm'} = 'hello';
1;
