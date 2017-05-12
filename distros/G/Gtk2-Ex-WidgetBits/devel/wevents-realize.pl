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
use Gtk2::Ex::CrossHair;
use Data::Dumper;

# hack for Gtk2-Perl prior to 1.183
Gtk2::Widget->signal_query ('realize');

Gtk2::Widget->signal_add_emission_hook
  (realize => sub {
     my ($hint, $parameters) = @_;
     my $widget = $parameters->[0];
     my $win = $widget->window;
     if (! $win) {
       print "$widget no window\n";
       return 1; # stay connected
     }
     my $f = $win->get_events;
     print "events $f\n";
     return 1; # stay connected
   });

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $area = Gtk2::DrawingArea->new;
$toplevel->add ($area);
# $area->add_events ('button-release-mask');

$toplevel->show_all;
exit 0;

