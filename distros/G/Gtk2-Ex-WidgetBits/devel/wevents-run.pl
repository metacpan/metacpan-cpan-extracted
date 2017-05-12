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
use Gtk2::Ex::WidgetEvents;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->add_events ('enter-notify-mask');

my $area = Gtk2::DrawingArea->new;
$toplevel->add ($area);

$toplevel->show_all;

my $widget = $area;
my $window = $widget->window;

my $e = Gtk2::Ex::WidgetEvents->new ($widget);
$area->add_events ('enter-notify-mask');

print "$progname: add pointer-motion-mask\n";
$e->add ('pointer-motion-mask');
print "$progname:\n";
print "  widget ", $widget->get_events, "\n";
print "  window ", $window->get_events, "\n";

print "$progname: remove pointer-motion-mask\n";
$e->remove ('pointer-motion-mask');
print "$progname:\n";
print "  widget ", $widget->get_events,"\n";
print "  window ", $window->get_events,"\n";


# my $empty_events = bless do {my $zero=0; \$zero}, 'Gtk2::Gdk::EventMask';
# print $empty_events + [],"\n";
