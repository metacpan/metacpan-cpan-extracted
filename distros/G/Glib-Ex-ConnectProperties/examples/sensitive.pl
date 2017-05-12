#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Glib::Ex::ConnectProperties;


# This is a simple but fairly typical use where a control widget (a
# CheckButton) is tied to a property on another widget (a Label).
#
# Notice that the label is the first in the ConnectProperties setup.  That
# means an initial propagation is done copying the label sensitive value to
# the checkbutton.  You can choose which of the properties is the initial
# value, after that they're all the same.
#

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (0,0);
$toplevel->add ($vbox);

my $label = Gtk2::Label->new ('Hello');
$label->set_alignment (0.5, 0.5);
$label->set_padding (0, 20);
$vbox->pack_start ($label, 1,1,0);

my $button = Gtk2::CheckButton->new_with_label ('Click Me');
$vbox->pack_start ($button, 0,0,0);

Glib::Ex::ConnectProperties->new ([$label, 'sensitive'],
                                  [$button, 'active']);

$toplevel->show_all;
Gtk2->main;
exit 0;
