#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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
use Gtk2;
use Gtk2::Ex::ComboBox::Enum;

use FindBin;
my $progname = $FindBin::Script;

# uncomment this to run the ### lines
use Smart::Comments;


my $read_signal = 'direction-changed';
# my $get_method = 'get_direction';
# my $set_method = 'set_direction';
my $get_method = sub {
  my ($widget, $pname) = @_;
  ### get direction ...
  return $widget->get_direction;
};
my $set_method = sub {
  my ($widget, $pname, $dir) = @_;
  ### set direction ...
  return $widget->set_direction($dir);
};
my $pspec = Glib::ParamSpec->enum ('direction',
                                   'direction',
                                   '',          # blurb
                                   'Gtk2::TextDirection',
                                   'none',      # default, unused
                                   Glib::G_PARAM_READWRITE);



my $toplevel = Gtk2::Window->new('toplevel');
# $toplevel->set_policy (1, 1, 1);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (0,0);
$toplevel->add ($vbox);

my $dir_combo = Gtk2::Ex::ComboBox::Enum->new
  (enum_type => 'Gtk2::TextDirection');
$vbox->pack_start ($dir_combo, 1,1,0);

my $label = Gtk2::Label->new ('Hello');
$label->set (xalign => 0);
$vbox->add ($label);
my $label2 = Gtk2::Label->new ('');
$vbox->pack_start ($label2, 0,0,0);

my $conn = Glib::Ex::ConnectProperties->new
  ([$label, 'parent',  # widget-direction#dir
    read_signal => 'direction-changed',
    get_method  => $get_method,
    set_method  => $set_method,
    pspec       => $pspec,
   ],
   [$dir_combo, 'active-nick']);

# Glib::Ex::ConnectProperties->new
#   ([$label, 'widget#direction'' ],
#    [$label2, 'label']);

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
