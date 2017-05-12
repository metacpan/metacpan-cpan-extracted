#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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


# This program displays a group of RadioMenuItems.
#
# The only thing to note is that because RadioMenuItem is a sub-class of
# CheckMenuItem its "activate" signal, and in turn the MenuView "activate",
# is emitted for both on the item losing the radio selection and the item
# gaining it.  Sometimes this is good, or other times only the new choice is
# interesting.  In the MenuView "activate" handler an $item->get_active
# gives the current state.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::MenuView;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $label = Gtk2::Label->new ("Press mouse button\nto popup menu");
$toplevel->add ($label);

my $liststore = Gtk2::ListStore->new ('Glib::String');
foreach my $str ('Choice One',
                 'Choice Two',
                 'Choice Three') {
  $liststore->set ($liststore->append, 0 => $str);
}

my $menuview = Gtk2::Ex::MenuView->new (model => $liststore);
$menuview->signal_connect (item_create_or_update => \&my_create_or_update);
$menuview->signal_connect (activate => \&my_activate);

sub my_create_or_update {
  my ($menuview, $item, $model, $path, $iter) = @_;
  my $n = ($path->get_indices)[-1];
  my $group = ($menuview->get_children)[0];
  return Gtk2::RadioMenuItem->new_with_label ($group, $model->get($iter,0));
}

sub my_activate {
  my ($menuview, $item, $model, $path, $iter) = @_;
  if ($item->get_active) {
    print $model->get($iter,0), " is now active\n";
  }
}

$toplevel->add_events ('button-press-mask');
$toplevel->signal_connect (button_press_event => \&my_button_event);
sub my_button_event {
  my ($toplevel, $event) = @_;
  $menuview->popup (undef, undef, undef, undef, $event->button, $event->time);
}

$toplevel->show_all;
Gtk2->main;
exit 0;
