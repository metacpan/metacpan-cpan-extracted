#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2013 Kevin Ryde

# This file is part of Gtk2-Ex-DateSpinner.
#
# Gtk2-Ex-DateSpinner is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-DateSpinner is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-DateSpinner.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl cellrenderer.pl
#
# This example uses Gtk2::Ex::DateSpinner::CellRenderer to display and edit
# a date column in a TreeModel.
#
# As usual the model/view/renderer stuff is diabolically complicated, but
# assuming you've managed to display stuff, the editing is then a matter of
# enabling 'editable' in the renderer and hooking onto its 'edited' signal.
# Writing the new data back to the model, or to disk or wherever, is the
# responsibility of that handler.
#
# The code here is basically the same as you'd do for a plain
# Gtk2::CellRendererText.  But DateSpinner::CellRenderer edits with a
# DateSpinner popup.  The $newstr string passed to the 'edited' signal is
# the new ISO YYYY-MM-DD date.
#
# You can set the 'editable' on the renderer by all the usual model+viewer
# tricks, like getting it from a column or setting it with a data func
# according to the phase of the moon.  That way you can have some cells
# editable and some not.
#
# The text column added here is just for decoration, but you could make it
# editable too.  You can even have multiple renderers in the one column,
# each editable.  The choice between one column with two renderers and two
# columns with a renderer each is only really a matter of how you want stuff
# to line up, and column headings, resizing, reordering etc.
#

use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::DateSpinner::CellRenderer;

my $liststore = Gtk2::ListStore->new ('Glib::String', 'Glib::String');
use constant { COL_DATE => 0,
               COL_TEXT => 1 };
$liststore->set ($liststore->append,
                 COL_DATE, '2005-06-04',
                 COL_TEXT, 'Some date');
$liststore->set ($liststore->append,
                 COL_DATE, '2007-10-31',
                 COL_TEXT, 'Another date');
$liststore->set ($liststore->append,
                 COL_DATE, '2009-05-01',
                 COL_TEXT, 'And yet a third date');

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $treeview = Gtk2::TreeView->new;
$treeview->set (model => $liststore,
                reorderable => 1);
$toplevel->add ($treeview);

my $datecolumn = Gtk2::TreeViewColumn->new;
$treeview->append_column ($datecolumn);

my $daterenderer = Gtk2::Ex::DateSpinner::CellRenderer->new (editable => 1);
$datecolumn->pack_start ($daterenderer, 0);
$datecolumn->add_attribute ($daterenderer, text => COL_DATE);

$daterenderer->signal_connect
  (edited => sub {
     my ($daterenderer, $pathstr, $newtext) = @_;
     my $path = Gtk2::TreePath->new_from_string ($pathstr);
     my $iter = $liststore->get_iter ($path);
     # print "set date at path $pathstr to $newtext\n";
     $liststore->set_value ($iter, 0, $newtext);
   });

my $textcolumn = Gtk2::TreeViewColumn->new;
$treeview->append_column ($textcolumn);

my $textrenderer = Gtk2::CellRendererText->new;
$textcolumn->pack_start ($textrenderer, 0);
$textcolumn->add_attribute ($textrenderer, text => COL_TEXT);

$toplevel->show_all;
Gtk2->main;
exit 0;
