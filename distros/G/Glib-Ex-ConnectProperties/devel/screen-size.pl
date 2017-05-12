#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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

my $screen = $toplevel->get_screen;

my $vbox = Gtk2::VBox->new (0,0);
$toplevel->add ($vbox);

my $label = Gtk2::Label->new ('Hello');
$label->signal_connect (notify => sub {
                          my ($label, $pspec) = @_;
                          my $pname = $pspec->get_name;
                          print "$progname: label set $pname\n";
                        });
$vbox->add ($label);

my $check = Gtk2::CheckButton->new_with_label ('Sensitive');
$vbox->add ($check);

Glib::Ex::ConnectProperties->new
  ([$screen, 'screen-size#width'],
   [$label, 'label']);

$toplevel->show_all;
Gtk2->main;
