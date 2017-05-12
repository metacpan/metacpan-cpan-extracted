#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Gtk2::Ex::TreeViewBits;

use Test::More tests => 10;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

{
  my $want_version = 48;
  is ($Gtk2::Ex::TreeViewBits::VERSION, $want_version, 'VERSION variable');
  is (Gtk2::Ex::TreeViewBits->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Gtk2::Ex::TreeViewBits->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::TreeViewBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
# remove_selected_rows()

require Gtk2;
my $model = Gtk2::ListStore->new ('Glib::String');
$model->set ($model->append, 0 => 'zero');
$model->set ($model->append, 0 => 'one');
$model->set ($model->append, 0 => 'two');
$model->set ($model->append, 0 => 'three');

my $treeview = Gtk2::TreeView->new ($model);
my $selection = $treeview->get_selection;

is (join(' ', map {$_->to_string} $selection->get_selected_rows),
    '', 'no selected paths before remove');
Gtk2::Ex::TreeViewBits::remove_selected_rows ($treeview);
require Gtk2::Ex::TreeModelBits;
is (join (' ', Gtk2::Ex::TreeModelBits::column_contents($model,0)),
    'zero one two three',
    'remove_selected_rows() not removing anything');
is (join(' ', map {$_->to_string} $selection->get_selected_rows),
    '', 'no selected paths after remove');

$selection->set_mode ('multiple');
$selection->select_path (Gtk2::TreePath->new("1"));
$selection->select_path (Gtk2::TreePath->new("3"));
is (join(' ', map {$_->to_string} $selection->get_selected_rows),
    '1 3', 'two selected paths before remove');

Gtk2::Ex::TreeViewBits::remove_selected_rows ($treeview);
require Gtk2::Ex::TreeModelBits;
is (join (' ', Gtk2::Ex::TreeModelBits::column_contents($model,0)),
    'zero two',
    'remove_selected_rows() removed two');
is (join(' ', map {$_->to_string} $selection->get_selected_rows),
    '', 'no selected paths after remove');

exit 0;
