#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

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


# This is pretty much the simplest program that displays a MenuView.  The
# model is a ListStore and the item-create-or-update handler shows column 0
# from it.
#
# The menu is popped-up from a mouse button press.  Generally a menu is
# handled in one of two ways, either the submenu of a MenuItem in a MenuBar
# etc, or an explicit popup from an event like below.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::MenuView;

my $liststore = Gtk2::ListStore->new ('Glib::String');
$liststore->set ($liststore->append, 0 => 'One');
$liststore->set ($liststore->append, 0 => 'Two');
$liststore->set ($liststore->append, 0 => 'Three');

my $menuview = Gtk2::Ex::MenuView->new (model => $liststore);

$menuview->signal_connect
  (item_create_or_update => sub {
     my ($menuview, $item, $model, $path, $iter) = @_;
     my $str = $model->get ($iter, 0);  # column 0
     return Gtk2::MenuItem->new_with_label ($str);
   });

$menuview->signal_connect
  (activate => sub {
     my ($menuview, $item, $model, $path, $iter) = @_;
     print "activate, path=", $path->to_string, "\n";
     print "          data=", $model->get($iter,0), "\n";
   });

#-----------------------------------------------------------------
my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $label = Gtk2::Label->new ("Press mouse button\nto popup menu");
$toplevel->add ($label);

$toplevel->add_events (['button-press-mask','button-release-mask']);
$toplevel->signal_connect
  (button_press_event => sub {
     my ($toplevel, $event) = @_;
     $menuview->popup (undef, undef, undef, undef,
                       $event->button, $event->time);
   });

$toplevel->show_all;
Gtk2->main;
exit 0;
