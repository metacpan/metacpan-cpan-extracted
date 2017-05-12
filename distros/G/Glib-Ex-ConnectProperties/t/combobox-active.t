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
use Glib::Ex::ConnectProperties;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;

eval { require Gtk2 }
  or plan skip_all => "due to Gtk2 module not available -- $@";
eval { require Gtk2::Ex::ComboBoxBits;
       Gtk2::Ex::ComboBoxBits->VERSION(32) }
  or plan skip_all => "due to Gtk2::Ex::ComboBoxBits version 32 not available -- $@";
MyTestHelpers::glib_gtk_versions();

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => "due to no DISPLAY";

plan tests => 34;


{
  package Foo;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      properties => [Glib::ParamSpec->boolean
                     ('mybool',
                      'mybool',
                      'Blurb.',
                      '', # default
                      Glib::G_PARAM_READWRITE),

                      Glib::ParamSpec->string
                      ('mystring',
                       'mystring',
                       'Blurb.',
                       '', # default
                       Glib::G_PARAM_READWRITE),
                    ];
}

#------------------------------------------------------------------------------
# combobox-active#exists

{
  my $model = Gtk2::TreeStore->new ('Glib::String');
  $model->insert (undef, 0);
  $model->insert (undef, 1);
  $model->insert (undef, 2);
  $model->insert ($model->iter_nth_child(undef,2), 0);
  $model->insert ($model->iter_nth_child(undef,2), 1);

  my $foo = Foo->new (mybool => 1);
  my $combobox = Gtk2::ComboBox->new;

  Glib::Ex::ConnectProperties->new
      ([$combobox, 'combobox-active#exists'],
       [$foo, 'mybool']);
  is ($foo->get('mybool'),0);

  $combobox->set_model ($model);
  $combobox->set_active (0);
  is ($foo->get('mybool'),1);

  $combobox->set_active (-1);
  is ($foo->get('mybool'),0);

  $combobox->set_active_iter ($model->get_iter
                              (Gtk2::TreePath->new_from_indices(2,1)));
  is ($foo->get('mybool'),1);
}

#------------------------------------------------------------------------------
# combobox-active#path

sub _active_path_str {
  my ($combobox) = @_;
  my ($model, $iter, $path);
  return (($model = $combobox->get_model)
          && ($iter = $combobox->get_active_iter)
          && ($path = $model->get_path($iter))
          && $path->to_string);
}

{
  my $model = Gtk2::TreeStore->new ('Glib::String');
  $model->insert (undef, 0);
  $model->insert (undef, 1);
  $model->insert (undef, 2);
  $model->insert ($model->iter_nth_child(undef,2), 0);
  $model->insert ($model->iter_nth_child(undef,2), 1);

  my $c1 = Gtk2::ComboBox->new;
  my $c2 = Gtk2::ComboBox->new;

  Glib::Ex::ConnectProperties->new
      ([$c1, 'combobox-active#path'],
       [$c2, 'combobox-active#path']);
  is ($c1->get_active_iter, undef);
  is ($c2->get_active_iter, undef);
  is (_active_path_str($c1), undef);
  is (_active_path_str($c2), undef);

  $c1->set_model ($model);
  $c2->set_model ($model);
  is (_active_path_str($c1), undef);
  is (_active_path_str($c2), undef);

  $c1->set_active (0);
  is (_active_path_str($c1), '0');
  is (_active_path_str($c2), '0');

  $c2->set_active (-1);
  is (_active_path_str($c1), undef);
  is (_active_path_str($c2), undef);

  $c1->set_active_iter ($model->get_iter
                        (Gtk2::TreePath->new_from_indices(2,1)));
  is (_active_path_str($c1), '2:1');
  is (_active_path_str($c2), '2:1');
}


#------------------------------------------------------------------------------
# combobox-active#iter

{
  my $model = Gtk2::TreeStore->new ('Glib::String');
  $model->insert (undef, 0);
  $model->insert (undef, 1);
  $model->insert (undef, 2);
  $model->insert ($model->iter_nth_child(undef,2), 0);
  $model->insert ($model->iter_nth_child(undef,2), 1);

  my $c1 = Gtk2::ComboBox->new;
  my $c2 = Gtk2::ComboBox->new;

  Glib::Ex::ConnectProperties->new
      ([$c1, 'combobox-active#iter'],
       [$c2, 'combobox-active#iter']);
  is ($c1->get_active_iter, undef);
  is ($c2->get_active_iter, undef);
  is (_active_path_str($c1), undef);
  is (_active_path_str($c2), undef);

  $c1->set_model ($model);
  $c2->set_model ($model);
  is (_active_path_str($c1), undef);
  is (_active_path_str($c2), undef);

  $c1->set_active (0);
  is (_active_path_str($c1), '0');
  is (_active_path_str($c2), '0');

  $c2->set_active (-1);
  is (_active_path_str($c1), undef);
  is (_active_path_str($c2), undef);

  $c1->set_active_iter ($model->get_iter
                        (Gtk2::TreePath->new_from_indices(2,1)));
  is (_active_path_str($c1), '2:1');
  is (_active_path_str($c2), '2:1');
}


#------------------------------------------------------------------------------
# combobox-active#text

{
  my $foo = Foo->new (mystring => 'blah');
  my $combobox = Gtk2::ComboBox->new_text;
  $combobox->append_text ('foo');
  $combobox->append_text ('bar');
  $combobox->append_text ('quux');
  $combobox->append_text ('blah');

  Glib::Ex::ConnectProperties->new
      ([$foo, 'mystring'],
       [$combobox, 'combobox-active#text']);
  is ($foo->get('mystring'),'blah');
  is ($combobox->get_active, 3);

  $combobox->set_active(1);
  is ($combobox->get_active, 1);
  is ($foo->get('mystring'),'bar');

  $foo->set (mystring => 'quux');
  is ($foo->get('mystring'),'quux');
  is ($combobox->get_active, 2);
}




exit 0;
