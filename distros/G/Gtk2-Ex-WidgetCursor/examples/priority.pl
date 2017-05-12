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


# This is a simple example of how a higher priority WidgetCursor has
# precedence over a lower one.  The two checkbuttons enable the respective
# higher or lower cursors.  Click them to see the effect of one, both, or
# neither enabled.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetCursor;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new (0, 0);
$toplevel->add ($vbox);

my $button1 = Gtk2::CheckButton->new_with_label ("Priority 10: Umbrella");
$vbox->pack_start ($button1, 1,1,0);
my $widgetcursor1 = Gtk2::Ex::WidgetCursor->new (widget => $toplevel,
                                                 cursor => 'umbrella',
                                                 priority => 10);
$button1->signal_connect (clicked => sub {
                            $widgetcursor1->active ($button1->get_active) });

my $button2 = Gtk2::CheckButton->new_with_label ("Priority 0: Boat");
$vbox->pack_start ($button2, 1,1,0);
my $widgetcursor2 = Gtk2::Ex::WidgetCursor->new (widget => $toplevel,
                                                 cursor => 'boat',
                                                 priority => 0);
$button2->signal_connect (clicked => sub {
                            $widgetcursor2->active ($button2->get_active) });

$toplevel->show_all;
Gtk2->main;
exit 0;
