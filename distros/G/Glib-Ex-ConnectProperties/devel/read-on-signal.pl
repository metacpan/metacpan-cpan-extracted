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

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (0,0);
$toplevel->add ($vbox);

my $label = Gtk2::Label->new ('Hello');
$vbox->add ($label);

my $entry1 = Gtk2::Entry->new;
$vbox->add ($entry1);
$entry1->signal_connect
  ('notify::text' => sub {
     print "$progname: entry1 notify 'text' now ",
       $entry1->get('text'),"\n";
   });

my $entry2 = Gtk2::Entry->new;
$vbox->add ($entry2);
$entry2->signal_connect
  ('notify::text' => sub {
     print "$progname: entry2 notify 'text' now ",
       $entry2->get('text'),"\n";
   });

my $conn = Glib::Ex::ConnectProperties->new ([$label,'label'],
                                             [$entry1,'text'],
                                             [$entry2,'text',read_signal=>'activate']);

{
  my $button = Gtk2::Button->new_with_label ('Disconnect');
  $vbox->add ($button);
  $button->signal_connect (clicked => sub { $conn->disconnect });
}
{
  my $button = Gtk2::Button->new_with_label ('Freeze 1');
  $vbox->add ($button);
  $button->signal_connect (clicked => sub { $entry1->freeze_notify });
}
{
  my $button = Gtk2::Button->new_with_label ('Thaw 1');
  $vbox->add ($button);
  $button->signal_connect (clicked => sub { $entry1->thaw_notify });
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
