#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Xor.
#
# Gtk2-Ex-Xor is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Xor is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Xor.  If not, see <http://www.gnu.org/licenses/>.


# This is a simple example with a CheckButton to enable or disable the
# CrossHair.  It shows how to put a label (which is a no-window widget) in
# an EventBox to make it work.
#
# As a gratuitous plug ... you'll notice the 'active' from the CheckButton
# is copied directly to the 'active' on the CrossHair.  The author's
# Glib::Ex::ConnectProperties is a good way to do that.
#


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::CrossHair;
use Data::Dumper;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $eventbox = Gtk2::EventBox->new;
$vbox->pack_start ($eventbox, 1,1,0);

my $label = Gtk2::Label->new
  ('This is a few lines of text.
Click the checkbutton below to turn
on the red cross lines following
the mouse (while it\'s within the
window).');
$eventbox->add ($label);

my $cross = Gtk2::Ex::CrossHair->new (widget => $eventbox,
                                      foreground => 'red');

my $check = Gtk2::CheckButton->new_with_label ('CrossHair');
$vbox->pack_start ($check, 0,0,0);
$check->signal_connect (toggled => sub {
                          my $active = $check->get ('active');
                          $cross->set (active => $active);
                        });

$toplevel->show_all;
Gtk2->main;
exit 0;
