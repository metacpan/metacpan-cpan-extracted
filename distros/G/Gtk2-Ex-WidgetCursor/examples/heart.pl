#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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


# A heart cursor activated and deactivated under a timer.

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetCursor;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });
$toplevel->set_default_size (300, 200);

my $heart = Gtk2::Ex::WidgetCursor->new (widget => $toplevel,
                                         cursor => 'heart');
sub beat {
  $heart->active (! $heart->active);   # toggle
  return 1; # Glib::SOURCE_CONTINUE
}
Glib::Timeout->add (800, \&beat);  # 800 milliseconds


$toplevel->show_all;
Gtk2->main;
exit 0;
