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


# This example uses a "hash_out" to turn the 0/1 boolean from a CheckBox
# into an xalign value for a label.  (xalign comes from Gtk2::Misc.)
#
# The label property in this case is treated as if it was write-only so
# there's no corresponding hash_in or func_in to handle a value coming back
# out of the label property.  If some other part of the program could update
# the label too then you'd have to think about how an arbitrary value from
# it should be turned into a boolean for the checkbox.
#

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (0,0);
$toplevel->add ($vbox);

my $button = Gtk2::CheckButton->new_with_label ('Label Align Right');
$vbox->pack_start ($button, 0,0,0);

my $label = Gtk2::Label->new ('ABC');
$vbox->pack_start ($label, 1,1,0);

Glib::Ex::ConnectProperties->new ([$button, 'active',
                                   hash_out => { 0 => 0.1, 1 => 0.9 } ],
                                  [$label, 'xalign']);

$toplevel->show_all;
Gtk2->main;
exit 0;
