#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;

use FindBin;
my $progname = $FindBin::Script;

{
  $ENV{'DISPLAY'} ||= ':0';
  require Gtk2;
  Gtk2->init;

  # my $entry = Gtk2::Entry->new;
  my $entry = Gtk2::DrawingArea->new;

  print "$entry\n";
  print "main select_region\n";
  $entry->select_region ('abc', 'def');
  print "main end\n";
  exit 0;
}

{
  my $foo;
  tie $foo, 'Foo';

  {
    package Foo;
    sub TIESCALAR {
      my ($class) = @_;
      return bless {}, $class;
    }
    sub FETCH {
      my ($self) = @_;
      print "Foo FETCH\n";
      return 0;
    }
  }

  sub func {
    print "func begin\n";
    my ($x) = @_;
    print "func got args\n";
    print $x,"\n";
    print "func end\n";
  }

  print "main begin\n";
  func ($foo);
  exit 0;
}
