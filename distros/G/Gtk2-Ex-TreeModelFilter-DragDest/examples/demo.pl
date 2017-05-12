#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TreeModelFilter-DragDest.
#
# Gtk2-Ex-TreeModelFilter-DragDest is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3, or (at your
# option) any later version.
#
# Gtk2-Ex-TreeModelFilter-DragDest is distributed in the hope that it will
# be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TreeModelFilter-DragDest.  If not, see
# <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Gtk2 '-init';

use Gtk2::Ex::TreeModelFilter::Draggable;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });
$toplevel->set_default_size (300, 200);


my $store = Gtk2::ListStore->new ('Glib::String', 'Glib::Boolean');
$store->insert_with_values (0, 0 => 'zero', 1 => 0);
$store->insert_with_values (1, 0 => 'one only', 1 => 1);
$store->insert_with_values (2, 0 => 'two 222', 1 => 1);
$store->insert_with_values (3, 0 => 'three', 1 => 0);
$store->insert_with_values (4, 0 => 'four OR MORE', 1 => 1);

my $filter = Gtk2::TreeModelFilter->new ($store);
$filter->set_visible_column (1);

my $draggable = Gtk2::Ex::TreeModelFilter::Draggable->new ($store);
$draggable->set_visible_column (1);

my $table = Gtk2::Table->new (3, 3, 0);
$toplevel->add ($table);

my $renderer = Gtk2::CellRendererText->new;

{ my $label = Gtk2::Label->new ('TreeModelFilter::Draggable');
  $table->attach ($label, 0,1,0,1, ['expand','shrink','fill'],[],10,5);

  my $treeview = Gtk2::TreeView->new_with_model ($draggable);
  $treeview->set (reorderable => 1);
  $table->attach ($treeview, 0,1,1,2,
                  ['expand','shrink','fill'],['expand','shrink','fill'],10,5);

  my $renderer = Gtk2::CellRendererText->new;
  my $column = Gtk2::TreeViewColumn->new_with_attributes
    ('Data (filtered)', $renderer, text => 0);
  $treeview->append_column ($column);
}

{ my $label = Gtk2::Label->new ('Gtk2::TreeModelFilter');
  $table->attach ($label, 1,2,0,1, ['expand','shrink','fill'],[],10,5);

  my $treeview = Gtk2::TreeView->new_with_model ($filter);
  $treeview->set (reorderable => 1);
  $table->attach ($treeview, 1,2,1,2,
                  ['expand','shrink','fill'],['expand','shrink','fill'],10,5);

  my $renderer = Gtk2::CellRendererText->new;
  my $column = Gtk2::TreeViewColumn->new_with_attributes
    ('Data (filtered)', $renderer, text => 0);
  $treeview->append_column ($column);
}

{ my $label = Gtk2::Label->new ('plain ListStore');
  $table->attach ($label, 2,3,0,1, ['expand','shrink','fill'],[],10,5);

  my $treeview = Gtk2::TreeView->new_with_model ($store);
  $treeview->set (reorderable => 1);
  $table->attach ($treeview, 2,3,1,2,
                  ['expand','shrink','fill'],['expand','shrink','fill'],10,5);

  {
    my $column = Gtk2::TreeViewColumn->new_with_attributes
      ('Data', $renderer, text => 0);
    $treeview->append_column ($column);
  }
  {
    my $renderer = Gtk2::CellRendererText->new;
    my $column = Gtk2::TreeViewColumn->new_with_attributes
      ('Visible', $renderer, text => 1);
    $treeview->append_column ($column);
  }
}

{
  my $label = Gtk2::Label->new
('Notice you can drag in the TreeModelFilter::Draggable view,
and in the underlying ListStore view, but not in the Gtk2::TreeModelFilter one.');
  $table->attach ($label, 0,3,2,3, [],[],10,5);
}

$toplevel->show_all;
Gtk2->main;
exit 0;
