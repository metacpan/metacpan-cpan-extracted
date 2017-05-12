#!/usr/bin/perl -w

# Copyright 2007, 2008, 2010 Kevin Ryde

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


use strict;
use warnings;
use Gtk2 '-init';

use Gtk2::Ex::ListModelConcat;

sub exception_handler {
  my ($msg) = @_;
  print __FILE__,": ", $msg;
  if (eval { require Devel::StackTrace; }) {
    my $trace = Devel::StackTrace->new;
    print $trace->as_string;
  } else {
    print "\n";
  }
  return 1; # stay installed
}
Glib->install_exception_handler (\&exception_handler);


my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (500, -1);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $hbox = Gtk2::HBox->new (0, 0);
$toplevel->add ($hbox);

my $vbox1 = Gtk2::VBox->new (0, 0);
$hbox->pack_start ($vbox1, 0,0,0);

my $vbox2 = Gtk2::VBox->new (0, 0);
$hbox->pack_start ($vbox2, 1,1,0);

my $vbox3 = Gtk2::VBox->new (0, 0);
$hbox->pack_start ($vbox3, 1,1,0);


my $store = Gtk2::ListStore->new ('Glib::String');
foreach my $str ('yy', 'zz-bb', '<b>xx</b>', 'fjdks', '32492', "abc\ndef") {
  $store->set_value ($store->append, 0, $str);
}

my $store2 = Gtk2::ListStore->new ('Glib::String');
foreach my $str ('2aaa', '2bbb', '2ccc') {
  $store2->set_value ($store2->append, 0, $str);
}

my $concat = Gtk2::Ex::ListModelConcat->new
  (models => [ $store, $store, $store2 ]);

$concat->signal_connect
  (row_changed => sub {
     my ($concat, $path, $iter) = @_;
     print __FILE__,": row changed path=",$path->to_string,
       " '",$concat->get_value($iter,0),"'\n";
   });
$concat->signal_connect
  (row_inserted => sub {
     my ($concat, $path, $iter) = @_;
     print __FILE__,": row inserted path=",$path->to_string;
     my $data = $concat->get_value($iter,0);
     print " data='",defined $data ? $data : 'undef', "'\n";
   });
$concat->signal_connect
  (row_deleted => sub {
     my ($concat, $path, $iter) = @_;
     print __FILE__,": row deleted path=",$path->to_string,"\n";
   });
$concat->signal_connect
  (rows_reordered => sub {
     my ($concat, $path, $iter, $aref) = @_;
     print __FILE__,": reordered ", join(' ',@$aref),"\n";
   });

# {
#   my $button = Gtk2::CheckButton->new_with_label ('Model');
#   $button->set_active ($ticker->get('model'));
#   $button->signal_connect (toggled => sub {
#                              $ticker->set (model => ($button->get_active
#                                                      ? $model : undef));
#                            });
#   $vbox1->pack_start ($button, 0, 0, 0);
# }
{
  my $button = Gtk2::Button->new_with_label ('Redraw');
  $button->signal_connect (clicked => sub { $toplevel->queue_draw; });
  $vbox1->pack_start ($button, 0, 0, 0);
}
# {
#   my $button = Gtk2::Button->new_with_label ('Destroy');
#   $button->signal_connect (clicked => sub { $ticker->destroy; });
#   $vbox1->pack_start ($button, 0, 0, 0);
# }
{
  my $button = Gtk2::Button->new_with_label ('Reorder Reverse');
  $button->signal_connect (clicked => sub {
                             my $rows = $concat->iter_n_children (undef);
                             $concat->reorder (reverse 0 .. $rows-1);
                           });
  $vbox1->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Delete First');
  $button->signal_connect (clicked => sub {
                             $concat->remove ($concat->get_iter_first);
                           });
  $vbox1->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Delete Last');
  $button->signal_connect (clicked => sub {
                             my $rows = $concat->iter_n_children (undef);
                             $concat->remove ($concat->get_iter_from_string
                                             ($rows-1));
                           });
  $vbox1->pack_start ($button, 0, 0, 0);
}
my $insert_count = 1;
{
  my $button = Gtk2::Button->new_with_label ('Insert First');
  $button->signal_connect (clicked => sub {
                             $concat->insert_with_values (0, 0,
                                                         "x$insert_count");
                             $insert_count++;
                           });
  $vbox1->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Insert Last');
  $button->signal_connect (clicked => sub {
                             my $rows = $concat->iter_n_children (undef);
                             $concat->insert_with_values ($rows, 0,
                                                          "x$insert_count");
                             $insert_count++;
                           });
  $vbox1->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Clear');
  $button->signal_connect (clicked => sub {
                             $concat->clear;
                           });
  $vbox1->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Quit');
  $button->signal_connect (clicked => sub { $toplevel->destroy; });
  $vbox1->pack_start ($button, 0, 0, 0);
}



{
  my $treeview = Gtk2::TreeView->new_with_model ($concat);
  $treeview->set (reorderable => 1);
  $vbox2->pack_start ($treeview, 1,1,0);

  my $renderer = Gtk2::CellRendererText->new;
  my $column = Gtk2::TreeViewColumn->new_with_attributes
    ("Item", $renderer, text => 0);
  $column->set (resizable => 1);
  $treeview->append_column ($column);
}
{
  my $treeview = Gtk2::TreeView->new_with_model ($store);
  $treeview->set (reorderable => 1);
  $vbox3->pack_start ($treeview, 1,1,0);

  my $renderer = Gtk2::CellRendererText->new;
  my $column = Gtk2::TreeViewColumn->new_with_attributes
    ("Item", $renderer, text => 0);
  $column->set (resizable => 1);
  $treeview->append_column ($column);
}
{
  my $treeview = Gtk2::TreeView->new_with_model ($store2);
  $treeview->set (reorderable => 1);
  $vbox3->pack_start ($treeview, 1,1,0);

  my $renderer = Gtk2::CellRendererText->new;
  my $column = Gtk2::TreeViewColumn->new_with_attributes
    ("Item", $renderer, text => 0);
  $column->set (resizable => 1);
  $treeview->append_column ($column);
}

{
  my $label = Gtk2::Label->new ('TextView');
  $vbox3->pack_start ($label, 0,0,0);
}
{
  my $textbuf = Gtk2::TextBuffer->new;
  $textbuf->set_text ('blah blah');
  my $textview = Gtk2::TextView->new_with_buffer ($textbuf);
  $vbox3->pack_start ($textview, 1,1,0);
}

$toplevel->show_all;
Gtk2->main;
exit 0;
