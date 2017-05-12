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


# This program displays some Gtk2::CheckMenuItem widgets with their tick
# marks reflecting a column from the model.

use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::MenuView;

use constant { COLUMN_TEXT => 0,
               COLUMN_FLAG => 1 };

my $liststore = Gtk2::ListStore->new ('Glib::String', 'Glib::Boolean');
$liststore->set ($liststore->append,
                 COLUMN_TEXT, 'Tick One',
                 COLUMN_FLAG, 0);
$liststore->set ($liststore->append,
                 COLUMN_TEXT, 'Tick Two',
                 COLUMN_FLAG, 1);
$liststore->set ($liststore->append,
                 COLUMN_TEXT, 'Tick Three',
                 COLUMN_FLAG, 0);

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (0, 0);
$toplevel->add ($vbox);

#------------------------------------------------------------------------------
# menubar popping up a MenuView

my $menubar = Gtk2::MenuBar->new;
$vbox->pack_start ($menubar, 0,0,0);

my $baritem = Gtk2::MenuItem->new_with_label ('Click to popup menu');
$menubar->add ($baritem);

my $menuview = Gtk2::Ex::MenuView->new (model => $liststore);
$baritem->set_submenu ($menuview);
$menuview->signal_connect (item_create_or_update => \&my_item_create_or_update);
$menuview->signal_connect (activate => \&my_activate);

sub my_item_create_or_update {
  my ($menuview, $item, $model, $path, $iter) = @_;
  $item ||= Gtk2::CheckMenuItem->new_with_label ('');

  my $str = $model->get ($iter, COLUMN_TEXT);
  my $label = $item->get_child;
  $label->set_text ($str);

  my $flag = $model->get ($iter, COLUMN_FLAG);
  print "item-create-or-update path=",$path->to_string," flag='$flag'\n";
  $item->set_active ($flag);
  return $item;
}

sub my_activate {
  my ($menuview, $item, $model, $path, $iter) = @_;
  my $flag = $item->get_active;
  print "CheckMenuItem activate, set path=",$path->to_string," to '$flag'\n";
  $model->set ($iter, COLUMN_FLAG, $flag);
}

#------------------------------------------------------------------------------
# TreeView displaying the model data too

my $treeview = Gtk2::TreeView->new_with_model ($liststore);
$treeview->set (reorderable => 1);
$vbox->pack_start ($treeview, 1,1,0);

my $text_renderer = Gtk2::CellRendererText->new;
my $text_column = Gtk2::TreeViewColumn->new_with_attributes
  ('Text', $text_renderer, text => COLUMN_TEXT);
$text_column->set (resizable => 1);
$treeview->append_column ($text_column);

my $flag_renderer = Gtk2::CellRendererToggle->new;
$flag_renderer->signal_connect
  (toggled => sub {
     my ($flag_renderer, $path_str) = @_;
     my $flag = $flag_renderer->get ('active');
     $flag = ! $flag;
     my $path = Gtk2::TreePath->new_from_string ($path_str);
     my $iter = $liststore->get_iter ($path) || return; # if no such
     # print "CellRendererToggle set path=",$path->to_string," to '$flag'\n";
     $liststore->set ($iter, COLUMN_FLAG, $flag);
   });
$flag_renderer->set (activatable => 1);
my $flag_column = Gtk2::TreeViewColumn->new_with_attributes
  ('Flag', $flag_renderer, active => COLUMN_FLAG);
$flag_column->set (resizable => 0);
$treeview->append_column ($flag_column);

$toplevel->show_all;
Gtk2->main;
exit 0;
