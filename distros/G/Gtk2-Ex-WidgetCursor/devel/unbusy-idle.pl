#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

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


# The Gtk2::Ex::WidgetCursor->busy() turns off after the high idle stops
# itself.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetCursor;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });
$toplevel->set_default_size (300, 200);

my $high_count = 0;
sub high_idle {
  print "high idle\n";
  sleep(1);
  return (++$high_count <= 4);  # continue until 4
}

my $low_count = 0;
sub low_idle {
  print "low idle\n";
  sleep(2);
  return (++$low_count <= 4);  # continue until 4
}

Glib::Idle->add (\&high_idle, undef, Glib::G_PRIORITY_DEFAULT_IDLE - 1000);
Glib::Idle->add (\&low_idle,  undef, Glib::G_PRIORITY_DEFAULT_IDLE + 1000);

my $wc = Gtk2::Ex::WidgetCursor->busy;

$toplevel->show_all;
$toplevel->get_display->flush;
Gtk2->main;
exit 0;
