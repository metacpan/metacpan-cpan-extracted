#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-MenuView.
#
# Gtk2-Ex-MenuView is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-MenuView is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-MenuView.  If not, see <http://www.gnu.org/licenses/>.


# This example ues Gtk2::CellView in each menu item, similar to what
# Gtk2::ComboBox does.
#
# The renderer here is only a CellRendererText, which is not very exciting,
# but in principle it could be anything, including multiple renderers side
# by side, etc.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::MenuView;
use POSIX ();

my $liststore = Gtk2::ListStore->new ('Glib::String');
foreach my $str ('Item one',
                 'Item <u>two</u>',
                 'Item three',
                 'Item <b>four</b>',
                 'Time item') {
  $liststore->set ($liststore->append, 0 => $str);
}

# fun making row 4 of the model show the time
sub timer_callback {
  my $str = POSIX::strftime ("Time <tt>%H:%M:%S</tt>", localtime(time()));
  $liststore->set_value ($liststore->iter_nth_child(undef,4), 0, $str);
  return 1; # Glib::SOURCE_CONTINUE
}
timer_callback(); # initial time display
Glib::Timeout->add (1000, \&timer_callback); # periodic updates

#------------------------------------------------------------------------------

my $menuview = Gtk2::Ex::MenuView->new (model => $liststore);
$menuview->signal_connect (item_create_or_update => \&my_create_or_update);
$menuview->signal_connect (activate => \&my_activate);

my $renderer = Gtk2::CellRendererText->new;

sub my_create_or_update {
  my ($menuview, $item, $model, $path, $iter) = @_;
  if (! $item) {
    $item = Gtk2::MenuItem->new;
    my $cellview = Gtk2::CellView->new;
    $cellview->pack_start ($renderer, 1);
    $cellview->add_attribute ($renderer, markup => 0);  # from column 0
    $item->add ($cellview);
  }
  # Set the model in case it changes.
  # Set displayed-row each time to force the CellView to redraw changed row
  # contents.
  my $cellview = $item->get_child;
  $cellview->set_model ($menuview->get('model'));
  $cellview->set_displayed_row ($path);
  return $item;
}

sub my_activate {
  my ($menuview, $item, $model, $path, $iter) = @_;
  print "activate '", $model->get($iter,0), "\n";
}

#------------------------------------------------------------------------------
my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $menubar = Gtk2::MenuBar->new;
$toplevel->add ($menubar);

my $item = Gtk2::MenuItem->new_with_label ('Click to Popup');
$item->set_submenu ($menuview);
$menubar->add ($item);

$toplevel->show_all;
Gtk2->main;
exit 0;
