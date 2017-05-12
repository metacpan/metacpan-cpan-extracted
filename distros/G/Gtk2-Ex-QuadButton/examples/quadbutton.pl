#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Gtk2-Ex-QuadButton.
#
# Gtk2-Ex-QuadButton is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-QuadButton is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-QuadButton.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::QuadButton;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $qb = Gtk2::Ex::QuadButton->new;
$qb->signal_connect_after (clicked => sub {
                             my ($qb, $scrolltype) = @_;
                             print "clicked: $scrolltype\n";
                           });
$vbox->pack_start ($qb, 1,1,0);

my $label = Gtk2::Label->new (
"Click, press keys, or mouse wheel..
Hold <Ctrl> down for pages.");
$vbox->pack_start ($label, 0, 0, 0);

$toplevel->show_all;
Gtk2->main;
exit 0;
