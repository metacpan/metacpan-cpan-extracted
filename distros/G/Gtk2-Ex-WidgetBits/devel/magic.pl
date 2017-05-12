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

# uncomment this to run the ### lines
use Smart::Comments;

# magic runs in its own stack

{
  package Foo;
  sub TIESCALAR {
    my ($class) = @_;
    return bless {}, $class;
  }
  my $count = 0;
  sub FETCH {
    my ($self) = @_;
    print "Foo FETCH\n";
    if (++$count > 0) {
      grow_the_stack();
    }
    return Gtk2::Gdk::Color->new(0,0,0);
  }


  sub grow_the_stack {
    print "grow the stack\n";
    my @x = return_values(500);
  }
  sub return_values {
    0 .. $_[0];
  }
}

{
  $ENV{'DISPLAY'} ||= ':0';
  require Gtk2;
  Gtk2->init;

  my $c1;
  my $c2;
  tie $c1, 'Foo';
  tie $c2, 'Foo';

  my $screen = Gtk2::Gdk::Screen->get_default;
  my $colormap = $screen->get_default_colormap;
  print "alloc\n";
  my @c = $colormap->alloc_colors (0, 1,
                                   $c1, $c2);
  ### @c
  exit 0;
}


