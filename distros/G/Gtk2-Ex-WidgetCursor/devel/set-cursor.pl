#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetCursor.
#
# Gtk2-Ex-WidgetCursor is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetCursor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetCursor.  If not, see <http://www.gnu.org/licenses/>.


# BEGIN { $ENV{'DISPLAY'} = 'localhost:1'; }

use strict;
use warnings;
use Gtk2 '-init';

use FindBin;
my $progname = $FindBin::Script;

{
  my $cursor = Gtk2::Gdk::Cursor->new('watch');
  my $win = Gtk2::Gdk::Window->new (undef,
                                    { window_type => 'toplevel',
                                      wclass => 'GDK_INPUT_OUTPUT',
                                      width => 100,
                                      height => 100,
                                      cursor => $cursor,
                                    });
  $win->show;
  #  $win->set_cursor ($cursor);
  my $display = $win->get_display;
  $display->flush;
  sleep 5;
  Gtk2->main;
  exit 0;
}

{
  my $toplevel = Gtk2::Window->new ('toplevel');
  $toplevel->set_name ("my_toplevel_1");
  $toplevel->show_all;
  my $win = $toplevel->window;
  my $cursor = Gtk2::Gdk::Cursor->new('watch');
  $win->set_cursor ($cursor);
  my $display = $toplevel->get_display;
  $display->flush;
  #sleep 10;
  Gtk2->main;
}
