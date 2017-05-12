#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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
use Glib::Ex::ConnectProperties;
use Gtk2 '-init';
use Gtk2 1.220; # 1.240 for find_child_property()

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
# $toplevel->set_policy (1, 1, 1);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (0,0);
$toplevel->add ($vbox);

my $padding_spin;
{
  my $hbox = Gtk2::HBox->new;
  $vbox->pack_start ($hbox, 0,0,0);
  $hbox->pack_start (Gtk2::Label->new ('Padding'),0,0,0);
  $padding_spin = Gtk2::SpinButton->new_with_range (0, 100, 1);
  $hbox->pack_start ($padding_spin, 1,1,0);
}

my $label = Gtk2::Label->new ('Hello');
$vbox->pack_start ($label, 1,1,0);
my $label2 = Gtk2::Label->new ('');
$vbox->pack_start ($label2, 1,1,0);

my $conn = Glib::Ex::ConnectProperties->new
  ([$label, 'container-child#padding' ],
   [$padding_spin, 'value']);

Glib::Ex::ConnectProperties->new
  ([$label, 'container-child#padding' ],
   [$label2, 'label']);

{
  my $button = Gtk2::Button->new_with_label ('Disconnect');
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect (clicked => sub { $conn->disconnect });
}
{
  my $button = Gtk2::Button->new_with_label ('Quit');
  $button->signal_connect (clicked => sub { $toplevel->destroy; });
  $vbox->pack_start ($button, 0, 0, 0);
}

$toplevel->show_all;
Gtk2->main;

print "$progname: conn ",(defined $conn ? "defined\n" : "not defined\n");
exit 0;
