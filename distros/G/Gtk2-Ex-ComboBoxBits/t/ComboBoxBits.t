#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ComboBoxBits.  If not, see <http://www.gnu.org/licenses/>.


# Tests of Gtk2::Ex::ComboBoxBits requiring a DISPLAY.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::ComboBoxBits;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';

plan tests => 16;

MyTestHelpers::glib_gtk_versions();

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 32;
  is ($Gtk2::Ex::ComboBoxBits::VERSION,
      $want_version,
      'VERSION variable');
  is (Gtk2::Ex::ComboBoxBits->VERSION,
      $want_version,
      'VERSION class method');

  ok (eval { Gtk2::Ex::ComboBoxBits->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::ComboBoxBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# find_text_iter()

{
  my $combobox = Gtk2::ComboBox->new;
  is (Gtk2::Ex::ComboBoxBits::find_text_iter ($combobox, 'nosuchentry'),
      undef);
}
#------------------------------------------------------------------------------
# set_active_text()

{
  my $combobox = Gtk2::ComboBox->new;
  Gtk2::Ex::ComboBoxBits::set_active_text ($combobox, undef);
  is ($combobox->get_active, -1);
}

#------------------------------------------------------------------------------
# set_active_path()

{
  my $combobox = Gtk2::ComboBox->new;

  Gtk2::Ex::ComboBoxBits::set_active_path ($combobox, undef);
  is ($combobox->get_active, -1, 'set_active_path() no model');

  my $model = Gtk2::TreeStore->new ('Glib::String');
  $model->insert (undef, 0);
  $model->insert (undef, 1);
  $model->insert (undef, 2);
  $model->insert ($model->iter_nth_child(undef,2), 0);
  $model->insert ($model->iter_nth_child(undef,2), 1);
  $combobox->set_model ($model);

  Gtk2::Ex::ComboBoxBits::set_active_path
      ($combobox, Gtk2::TreePath->new_from_indices(1));
  is ($combobox->get_active, 1);

  Gtk2::Ex::ComboBoxBits::set_active_path
      ($combobox, Gtk2::TreePath->new_from_indices(2,1));
  { my $iter = $combobox->get_active_iter;
    my $path = $iter && $model->get_path($iter);
    my $str = $path && $path->to_string;
    is ($str, '2:1');
  }
}

#------------------------------------------------------------------------------
# get_active_path()

{
  my $combobox = Gtk2::ComboBox->new;
  is (Gtk2::Ex::ComboBoxBits::get_active_path($combobox),
      undef);

  Gtk2::Ex::ComboBoxBits::set_active_path ($combobox, undef);
  is (Gtk2::Ex::ComboBoxBits::get_active_path($combobox), undef);
  is ($combobox->get_active, -1);

  my $model = Gtk2::TreeStore->new ('Glib::String');
  $model->insert (undef, 0);
  $model->insert (undef, 1);
  $model->insert (undef, 2);
  $model->insert ($model->iter_nth_child(undef,2), 0);
  $model->insert ($model->iter_nth_child(undef,2), 1);
  $combobox->set_model ($model);

  $combobox->set_active(-1);
  is (Gtk2::Ex::ComboBoxBits::get_active_path($combobox),
      undef);

  $combobox->set_active(0);
  { my $got = Gtk2::Ex::ComboBoxBits::get_active_path($combobox);
    is ($got && $got->to_string, '0');
  }

  $combobox->set_active(2);
  { my $got = Gtk2::Ex::ComboBoxBits::get_active_path($combobox);
    is ($got && $got->to_string, '2');
  }

  $combobox->set_active_iter($model->get_iter(Gtk2::TreePath->new_from_indices
                                              (2,1)));
  { my $got = Gtk2::Ex::ComboBoxBits::get_active_path($combobox);
    is ($got && $got->to_string, '2:1');
  }
}

exit 0;
