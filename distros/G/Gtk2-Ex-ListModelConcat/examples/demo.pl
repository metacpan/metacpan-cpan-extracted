#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-ListModelConcat.
#
# Gtk2-Ex-ListModelConcat is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ListModelConcat is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ListModelConcat.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Gtk2 '-init';

use Gtk2::Ex::ListModelConcat;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });
$toplevel->set_default_size (300, 200);


my $store1 = Gtk2::ListStore->new ('Glib::String');
foreach my $str ('one', 'two', 'three', 'four') {
  $store1->insert_with_values (99, 0 => $str);
}

my $store2 = Gtk2::ListStore->new ('Glib::String');
foreach my $str ('AAA', 'BBB', 'CCC', 'DDD') {
  $store2->insert_with_values (99, 0 => $str);
}

my $concat = Gtk2::Ex::ListModelConcat->new
  (models => [ $store1, $store2 ]);


my $vbox = Gtk2::VBox->new (0, 0);
$toplevel->add ($vbox);

my $hbox = Gtk2::HBox->new (0, 0);
$vbox->pack_start ($hbox, 1,1,0);

foreach my $elem (['Concat',$concat],
                  ['Store 1',$store1],
                  ['Store 2',$store2]) {
  my ($name, $model) = @$elem;

  my $treeview = Gtk2::TreeView->new_with_model ($model);
  $treeview->set (reorderable => 1);
  $hbox->pack_start ($treeview, 1,1,0);

  my $renderer = Gtk2::CellRendererText->new;
  my $column = Gtk2::TreeViewColumn->new_with_attributes
    ($name, $renderer, text => 0);
  $column->set (resizable => 1);
  $treeview->append_column ($column);
}

{
  my $label = Gtk2::Label->new (<<'HERE');
Drag items around in the separate stores or in the Concat.
But Gtk2::ListStore won't let you move items between the stores.
HERE
  $vbox->pack_start ($label, 0,0,0);
}

$toplevel->show_all;
Gtk2->main;
exit 0;
