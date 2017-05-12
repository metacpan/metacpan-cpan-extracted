#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Glib 1.220;
use Gtk2 '-init';
use Gtk2::Ex::MenuView;
use Data::Dumper;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $hbox = Gtk2::HBox->new (0, 0);
$toplevel->add ($hbox);

my $left_vbox = Gtk2::VBox->new (0, 0);
$hbox->pack_start ($left_vbox, 0,0,0);

my $right_vbox = Gtk2::VBox->new (0, 0);
$hbox->pack_start ($right_vbox, 1,1,0);

my $treestore = Gtk2::TreeStore->new ('Glib::String');
foreach my $str ('Item one',
                 'Item two',
                 'Item three',
                 'Item four',
                 'Item five') {
  $treestore->set ($treestore->append(undef), 0 => $str);
}

my $menuview = Gtk2::Ex::MenuView->new (model => $treestore);

{
  my $tearoff = Gtk2::TearoffMenuItem->new;
  $tearoff->show;
  $menuview->prepend ($tearoff);
}

$menuview->signal_connect (item_create_or_update => \&do_item_create_or_update);
sub do_item_create_or_update {
  my ($menuview, $item, $model, $path, $iter) = @_;
  print "$progname: create/update\n";
  if (! $item) {
    $item = Gtk2::MenuItem->new_with_label ('');
  }
  my $label = $item->get_child;
  my $str = $model->get_value ($iter, 0);
  print "$progname: data $item path ",$path->to_string,
    " str \"", defined $str ? $str : 'undef', "\"\n";
  $label->set_text ($str);
  print "  return $item\n";
  return $item;
}

$menuview->signal_connect (activate => sub {
                             my ($menuview, $item, $model, $path, $iter) = @_;
                             print "$progname: activate ",Dumper(\@_);
                             print "  path ",$path->to_string,"\n";
                           });
my $treeview = Gtk2::TreeView->new_with_model ($treestore);
$treeview->set (reorderable => 1);
$right_vbox->pack_start ($treeview, 1,1,0);
{
  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (editable => 1);
  $renderer->signal_connect
    (edited => sub {
       print Dumper(\@_);
       my ($renderer, $pathstr, $newstr) = @_;
       my $path = Gtk2::TreePath->new_from_string ($pathstr);
       my $iter = $treestore->get_iter ($path);
       $treestore->set_value ($iter, 0 => $newstr);
     });

  my $column = Gtk2::TreeViewColumn->new_with_attributes
    ("TreeView:", $renderer, text => 0);
  $column->set (resizable => 1);
  $treeview->append_column ($column);
}

{
  my $menubar = Gtk2::MenuBar->new;
  $left_vbox->pack_start ($menubar, 0,0,0);
  my $item = Gtk2::MenuItem->new_with_label ('Menu');
  $item->set_submenu ($menuview);
  $menubar->add ($item);
}
{
  my $label = Gtk2::Label->new (' ');
  $left_vbox->add ($label);
}
{
  my $button = Gtk2::Button->new_with_label ('Append');
  $button->signal_connect
    (clicked => sub {
       $treestore->set ($treestore->append(undef), 0 =>  rand());
     });
  $left_vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('Insert Second');
  $button->signal_connect
    (clicked => sub {
       $treestore->insert_with_values (undef, 1, 0 => rand());
     });
  $left_vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('Insert Subrow');
  $button->signal_connect
    (clicked => sub {
       my $parent = $treestore->iter_nth_child (undef, 1);
       $treestore->insert_with_values ($parent, 0, 0 => rand());
     });
  $left_vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('Delete');
  $button->signal_connect
    (clicked => sub {
       my $iter = $treestore->get_iter (Gtk2::TreePath->new(2));
       if ($iter) { $treestore->remove ($iter); }
     });
  $left_vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('Reorder Up');
  $button->signal_connect
    (clicked => sub {
       my $len = $treestore->iter_n_children (undef);
       my $end = $len - 1;
       $treestore->reorder (1 .. $end, 0);
     });
  $left_vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('Reorder Down');
  $button->signal_connect
    (clicked => sub {
       my $len = $treestore->iter_n_children (undef);
       my $end = $len - 1;
       $treestore->reorder ($end, 0 .. $end-1);
     });
  $left_vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('New Model');
  $button->signal_connect
    (clicked => sub {
       print "$progname: new model in 3 seconds\n";
       Glib::Timeout->add
           (3_000, # 3 seconds
            sub {
              print "$progname: new model now\n";
              $treestore = treestore_copy_model($treestore);
              $menuview->set (model => $treestore);
              $treeview->set (model => $treestore);
              return Glib::SOURCE_REMOVE;
            });
     });
  $left_vbox->pack_start ($button, 0,0,0);
}
{
  my $combobox = Gtk2::ComboBox->new_with_model ($treestore);
  $combobox->set (add_tearoffs => 1);
  $left_vbox->pack_start ($combobox, 0,0,0);
  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (xalign => 1); # right align
  $combobox->pack_start ($renderer, 1);
  $combobox->add_attribute ($renderer, text => 0);
}

$menuview->popup (undef, undef, undef, undef, 0, 0);
print "$progname: children ",$menuview->get_children,"\n";

$toplevel->show_all;
Gtk2->main;
exit 0;


#------------------------------------------------------------------------------

# return a new Gtk2::TreeStore which is a copy of the $model contents
sub treestore_copy_model {
  my ($model) = @_;
  require Gtk2::Ex::TreeModelBits;
  my $treestore = Gtk2::TreeStore->new
    (Gtk2::Ex::TreeModelBits::all_column_types ($model));
  my @columns = (0 .. $model->get_n_columns - 1);
  $model->foreach
    (sub {
       my ($model, $path, $iter) = @_;
       my $treepath = $path->copy;
       $treepath->up;
       my $treeiter;
       if ($treepath->get_depth) {
         $treeiter = $treestore->get_iter($treepath);
       }
       print "$progname: copy ",$path->to_string," to append ",$treepath->to_string//'top',"\n";
       $treestore->insert_with_values ($treeiter, -1,
                                       map { ($_, $model->get($iter,$_)) }
                                       @columns);
       return 0; # keep traversing
     });
  return $treestore;
}
