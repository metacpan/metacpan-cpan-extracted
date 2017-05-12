#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;

require Glib::Ex::ConnectProperties;

eval { require Gtk2 }
  or plan skip_all => "due to Gtk2 module not available -- $@";
Gtk2->init_check
  or plan skip_all => "due to no DISPLAY";
MyTestHelpers::glib_gtk_versions();

plan tests => 22;


{
  package MyClass;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      properties => [ Glib::ParamSpec->boolean
                      ('mybool',
                       'mybool',
                       'Blurb.',
                       0, # default
                       Glib::G_PARAM_READWRITE),

                      Glib::ParamSpec->int
                      ('myint',
                       'myint',
                       'Blurb.',
                       0, 9999,  # min, max
                       0,        # default
                       Glib::G_PARAM_READWRITE),
                    ];
}

#------------------------------------------------------------------------------
# empty / not-empty / count

{
  my $foo = MyClass->new;
  my $bar = MyClass->new;

  my $model = Gtk2::ListStore->new ('Glib::String');
  $model->insert (0); # row 0
  $model->insert (1); # row 1

  my $iconview = Gtk2::IconView->new_with_model ($model);
  $iconview->set_selection_mode ('multiple');

  Glib::Ex::ConnectProperties->new
      ([$iconview, 'iconview-selection#empty'],
       [$foo, 'mybool']);
  Glib::Ex::ConnectProperties->new
      ([$iconview, 'iconview-selection#count'],
       [$foo, 'myint']);
  Glib::Ex::ConnectProperties->new
      ([$iconview, 'iconview-selection#not-empty'],
       [$bar, 'mybool']);

  ok (  $foo->get('mybool'), 'empty - initial');
  ok (! $bar->get('mybool'), 'not-empty - initial');
  ok (! $bar->get('mybool'), 'not-empty - initial');
  is ($foo->get('myint'), 0, 'count - initial');

  my $row1_path = Gtk2::TreePath->new_from_indices(1);

  # it it supposed to work as subrow 0:0 ?
  my $row2_path = Gtk2::TreePath->new_from_indices(0);
  ### row2 iter: $model->get_iter($row2_path)

  $iconview->select_path ($row1_path);
  ok (! $foo->get('mybool'), 'empty - one');
  ok (  $bar->get('mybool'), 'not-empty - one');
  is ($foo->get('myint'), 1, 'count - one');

  $iconview->select_path ($row2_path);
  ok (! $foo->get('mybool'), 'empty - two');
  ok (  $bar->get('mybool'), 'not-empty - two');
  is ($foo->get('myint'), 2, 'count - two');
  ### paths: $iconview->get_selected_items

  $iconview->unselect_path ($row1_path);
  ok (! $foo->get('mybool'), 'empty - removed two');
  ok (  $bar->get('mybool'), 'not-empty - removed two');
  is ($foo->get('myint'), 1, 'count - removed two');

  $iconview->unselect_path ($row2_path);
  ok (  $foo->get('mybool'), 'empty - removed one');
  ok (! $bar->get('mybool'), 'not-empty - removed one');
  is ($foo->get('myint'), 0, 'count - removed one');
}



#------------------------------------------------------------------------------
# selected-path

sub selstrings {
  my ($iconview) = @_;
  return join(',',map {$_->to_string} $iconview->get_selected_items);
}

{
  my $model = Gtk2::ListStore->new ('Glib::String');
  $model->insert (0); # row 0
  $model->insert (1); # row 1
  $model->insert (2); # row 1
  $model->insert (3); # row 1
  $model->insert (4); # row 1

  my $iconview1 = Gtk2::IconView->new_with_model ($model);
  my $iconview2 = Gtk2::IconView->new_with_model ($model);
  $iconview1->set_selection_mode ('single');
  $iconview2->set_selection_mode ('single');
  ### sigid: $iconview2->signal_connect (selection_changed => sub { print "iconview1 selection-changed signal\n" })
  ### sigid: $iconview2->signal_connect (selection_changed => sub { print "iconview2 selection-changed signal\n" })

  Glib::Ex::ConnectProperties->new
      ([$iconview1, 'iconview-selection#selected-path'],
       [$iconview2, 'iconview-selection#selected-path']);

  $iconview1->select_path (Gtk2::TreePath->new_from_indices(3));
  is (selstrings($iconview1), '3');
  is (selstrings($iconview2), '3');

  $iconview2->select_path (Gtk2::TreePath->new_from_indices(0));
  is (selstrings($iconview1), '0');
  is (selstrings($iconview2), '0');

  $iconview2->unselect_path (Gtk2::TreePath->new_from_indices(0));
  is (selstrings($iconview1), '');
  is (selstrings($iconview2), '');
}

exit 0;
