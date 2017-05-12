#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ComboBoxBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Gtk2::Ex::ComboBox::PixbufType;
use Gtk2 '-init';

use FindBin;
my $progname = $FindBin::Script;

# uncomment this to run the ### lines
use Smart::Comments;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $combo = Gtk2::Ex::ComboBox::PixbufType->new (
                                                 active_type => 'png',
                                                 for_width => 128,
                                                 for_height => 10,
                                                );
$vbox->pack_start ($combo, 0, 0, 0);

$combo->signal_connect
  ('notify::active' => sub {
     print "$progname: combo active now @{[$combo->get('active')]}\n";
   });
$combo->signal_connect
  ('notify::active-type' => sub {
     my $type = $combo->get('active-type');
     print "$progname: notify::active-type, value now ",
       (defined $type ? $type : '[undef]'),"\n";
   });

{
  my $button = Gtk2::Button->new_with_label ('Set "jpeg"');
  $button->signal_connect (clicked => sub { $combo->set(active_type => 'jpeg'); });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Set "nosuch"');
  $button->signal_connect (clicked => sub { $combo->set(active_type => 'nosuch'); });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Set 999');
  $button->signal_connect (clicked => sub { $combo->set_active(999); });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Set 999');
  $button->signal_connect (clicked => sub { $combo->set_active(999); });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  require POSIX;
  my $adj = Gtk2::Adjustment->new (0,  # initial
                                   0,  # min
                                   POSIX::INT_MAX(),  # max
                                   1,100,    # step,page increment
                                   0);      # page_size
  require Glib::Ex::ConnectProperties;
  Glib::Ex::ConnectProperties->new ([$combo,'for-width'],
                                    [$adj,'value']);
  my $spin = Gtk2::SpinButton->new ($adj, 10, 0);
  $vbox->pack_start ($spin, 0, 0, 0);
}


$toplevel->show_all;
Gtk2->main;

exit 0;
