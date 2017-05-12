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


# Doesn't work properly ...


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::MenuView;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $menubar = Gtk2::MenuBar->new;
$toplevel->add ($menubar);

my $baritem = Gtk2::MenuItem->new_with_label ('Click to Popup');
$menubar->add ($baritem);

my $liststore = Gtk2::ListStore->new ('Glib::Int', 'Glib::String');
foreach my $row ([0, 'Red'],
                 [0, 'Green'],
                 [0, 'Blue'],
                 [3, 'Apple'],
                 [3, 'Orange'],
                 [3, 'Pear']) {
  $liststore->set ($liststore->append,
                   0 => $row->[0],
                   1 => $row->[1]);
}

sub my_item_create {
  my ($menu) = @_;
  return Gtk2::RadioMenuItem->new_with_label (undef, '');
}
sub my_item_data {
  my ($menu, $model, $iter, $item) = @_;
  my $groupnum = $model->get_value ($iter, 0);
  my $group_item = $menu->get_nth_item ($groupnum);
  if ($item == $group_item) {
    $item->set_group (undef);
  } else {
    $item->set_group ($group_item);
  }
  my $str = $model->get_value ($iter, 1);
  $item->get_child->set_text ($str);
}
my $menu = Gtk2::Ex::MenuView->new (model => $liststore,
                                    item_create_func => \&my_item_create,
                                    item_data_func => \&my_item_data);
$baritem->set_submenu ($menu);

my $tearoff = Gtk2::TearoffMenuItem->new;
$tearoff->show;
$menu->prepend ($tearoff);


$toplevel->show_all;
Gtk2->main;
exit 0;
