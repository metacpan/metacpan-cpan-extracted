#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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
use Gtk2 '-init';
use Gtk2::Ex::SyncCall;

my $toplevel = Gtk2::Window->new('toplevel');

my $drawingarea = Gtk2::DrawingArea->new;
$drawingarea->set_size_request (100, 100);
$toplevel->add($drawingarea);

$toplevel->show_all;
my $widget = $drawingarea;
#my $widget = $toplevel;

$widget->add_events ('property-change-mask');
$widget->signal_connect
  (property_notify_event =>  sub {
     my ($widget, $event) = @_;
     print "property_notify_event\n";
     print "  ",$event->atom,"  ",$event->atom->name,"\n";
   });

my $win = $widget->window;
# print "$win  id=",$win->XID,"\n";

my $atom = Gtk2::Gdk::Atom->intern ('MyAtom');
# sleep 5;

print "initial\n";
$win->property_change ($atom,
                       Gtk2::Gdk::Atom->intern('STRING'),
                       Gtk2::Gdk::CHARS, 'append',
                       '');
Glib::Timeout->add
  (5000, sub {
     print "change\n";
     $win->property_change ($atom,
                            Gtk2::Gdk::Atom->intern('STRING'),
                            Gtk2::Gdk::CHARS, 'append',
                            '');
     return 1; # continue
   });

Gtk2->main;
exit 0;
