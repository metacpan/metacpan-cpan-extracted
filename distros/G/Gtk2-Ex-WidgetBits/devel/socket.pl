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

use FindBin;
my $progname = $FindBin::Script;


my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->set_default_size (200, 100);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $eventbox = Gtk2::EventBox->new;
$toplevel->add ($eventbox);

my $vbox = Gtk2::VBox->new;
$eventbox->add ($vbox);

my $socket = Gtk2::Socket->new;
$vbox->pack_start ($socket, 1,1,0);

$toplevel->show_all;
my $id = $socket->get_id;
print "id $id\n";

my $plug_prog = File::Spec->catfile ($FindBin::Bin, 'plug.pl');
system ("$^X $plug_prog $id &");

Gtk2->main;
exit 0;
