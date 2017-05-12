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
use Gtk2 '-init';
use Gtk2::Ex::WidgetBits;
use Gtk2::Ex::GdkBits;

use FindBin;
my $progname = $FindBin::Script;

my $id = $ARGV[0];
print "$progname: id $id\n";

my $plug = Gtk2::Plug->new ($id);
$plug->signal_connect (destroy => sub { Gtk2->main_quit });

my $frame = Gtk2::Frame->new;
$plug->add ($frame);

my $eventbox = Gtk2::EventBox->new;
$frame->add ($eventbox);

my $label = Gtk2::Label->new ('Plug program');
$eventbox->add ($label);

$plug->show_all;

$plug->get_display->sync;
Glib::Idle->add
  (sub {
     my $window = $plug->window;
     for (;;) {
       my ($x,$y) = Gtk2::Ex::GdkBits::window_get_root_position ($window);
       printf "%s %7X  %d,%d\n", $window, $window->XID, $x,$y;
       $window = $window->get_parent || last;
     }
     return 0; # Glib::SOURCE_REMOVE;
   });

Glib::Idle->add
  (sub {
     my $widget = $label;
     for (;;) {
       my ($x,$y) = Gtk2::Ex::WidgetBits::get_root_position ($widget);
       my $window = $widget->window;
       printf "%s %7X  %d,%d\n", $widget, $window->XID, $x,$y;
       $widget = $widget->get_parent || last;
     }
     return 0; # Glib::SOURCE_REMOVE;
   });

Gtk2->main;
exit 0;
