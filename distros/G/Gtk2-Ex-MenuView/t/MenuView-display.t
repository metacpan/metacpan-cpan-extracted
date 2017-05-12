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


# Tests requiring a DISPLAY.

use 5.008;
use strict;
use warnings;
use Test::More;

BEGIN {
  require Gtk2;
  Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
  Gtk2->init_check
    or plan skip_all => "due to no DISPLAY";

  plan tests => 114;
}

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::MenuView;

#-----------------------------------------------------------------------------
# instance VERSION

{
  my $want_version = 4;
  my $menuview = Gtk2::Ex::MenuView->new;
  is ($menuview->VERSION,  $want_version, 'VERSION instance method');
  ok (eval { $menuview->VERSION($want_version); 1 },
      "VERSION instance check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $menuview->VERSION($check_version); 1 },
      "VERSION instance check $check_version");
}

#------------------------------------------------------------------------------
# item_get_mmpi

{
  my $store = Gtk2::TreeStore->new ('Glib::String');
  $store->set ($store->append(undef), 0 => 'foo');
  $store->set ($store->append(undef), 0 => 'bar');
  $store->set ($store->append(undef), 0 => 'quux');
  $store->set ($store->append($store->iter_nth_child(undef,1)), 0 => 'sub1');
  $store->set ($store->append($store->iter_nth_child(undef,1)), 0 => 'sub2');

  my $menuview = Gtk2::Ex::MenuView->new (model => $store);
  $menuview->signal_connect
    (item_create_or_update => sub {
       my ($menuview, $item, $model, $path, $iter) = @_;
       return Gtk2::MenuItem->new_with_label ('foo');
     });

  foreach my $pathstr ('0', '1', '2', '1:0', '1:1') {
    foreach my $class_or_menu ($menuview, 'Gtk2::Ex::MenuView') {
      my $path = Gtk2::TreePath->new_from_string ($pathstr);
      my $item = $menuview->item_at_path ($path);
      ok ($item, "item at pathstr=$pathstr path=".$path->to_string);
      my @ret = $item && $class_or_menu->item_get_mmpi($item);
      is (scalar(@ret), 4);
      my ($ret_menuview, $ret_model, $ret_path, $ret_iter) = @ret;
      is ($ret_menuview, $menuview);
      is ($ret_model, $store);
      isa_ok ($ret_path, 'Gtk2::TreePath');
      is ($ret_path && $ret_path->can('to_string') && $ret_path->to_string,
          $path->to_string);
      isa_ok ($ret_iter, 'Gtk2::TreeIter');
      is (($ret_iter
           && $ret_iter->isa('Gtk2::TreeIter')
           && $store->get_path($ret_iter)
           && $store->get_path($ret_iter)->to_string),
          $path->to_string);
    }
  }
}

#-----------------------------------------------------------------------------
# want-visible

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->append, 0 => 'foo');

  my $menuview = Gtk2::Ex::MenuView->new (model => $store);
  is ($menuview->get('want-visible'), 'show_all',
      'default want-visible');

  $menuview->signal_connect
    (item_create_or_update => sub {
       my ($menuview, $item, $model, $path, $iter) = @_;
       $item = Gtk2::MenuItem->new;
       my $label = Gtk2::Label->new ('foo');
       $item->add ($label);
       return $item;
     });
  my $item = $menuview->item_at_indices (0);
  my $label = $item->get_child;
  ok ($item->get('visible'),
      'want-visible "show_all" makes item visible');
  ok ($label->get('visible'),
      'want-visible "show_all" makes item child visible');
}

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->append, 0 => 'foo');

  my $menuview = Gtk2::Ex::MenuView->new (model => $store,
                                          want_visible => 'show');
  is ($menuview->get('want-visible'), 'show',
      'want-visible set to "show"');

  $menuview->signal_connect
    (item_create_or_update => sub {
       my ($menuview, $item, $model, $path, $iter) = @_;
       $item = Gtk2::MenuItem->new;
       my $label = Gtk2::Label->new ('foo');
       $item->add ($label);
       return $item;
     });
  my $item = $menuview->item_at_indices (0);
  my $label = $item->get_child;
  ok ($item->get('visible'),
      'want-visible "show" makes item visible');
  ok (! $label->get('visible'),
      'want-visible "show" leaves item child not visible');
}

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->append, 0 => 'foo');

  my $menuview = Gtk2::Ex::MenuView->new (model => $store,
                                          want_visible => 'no');
  is ($menuview->get('want-visible'), 'no',
      'want-visible set to "no"');

  $menuview->signal_connect
    (item_create_or_update => sub {
       my ($menuview, $item, $model, $path, $iter) = @_;
       $item = Gtk2::MenuItem->new;
       my $label = Gtk2::Label->new ('foo');
       $item->add ($label);
       return $item;
     });
  my $item = $menuview->item_at_indices (0);
  my $label = $item->get_child;
  ok (! $item->get('visible'),
      'want-visible "no" leave item not visible');
  ok (! $label->get('visible'),
      'want-visible "no" leaves item child not visible');
}

#------------------------------------------------------------------------------
# size_request

{
  # TODO:
  # local $TODO = 'size_request chaining in newer Glib';

  my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->append, 0 => 'foo');
  my %created;
  my $menuview = Gtk2::Ex::MenuView->new (model => $store);
  $menuview->signal_connect
    (item_create_or_update => sub {
       my ($menuview, $item, $model, $path, $iter) = @_;
       diag "size_request create ",$path->to_string;
       $created{$path->to_string} = 'done';
       $item = Gtk2::MenuItem->new;
       my $drawing = Gtk2::DrawingArea->new;
       $drawing->set_size_request (200, 200);
       $item->add ($drawing);
       return $item;
     });
  my $req = $menuview->size_request;

  my $item_count = scalar @{[$menuview->get_children]};
  is ($item_count, 1, 'size_request - item count');
  is_deeply (\%created, {0=>'done'}, 'size_request - created paths');
  cmp_ok ($req->width, '>=', 150, 'size_request - width');
  cmp_ok ($req->height, '>=', 150, 'size_request - height');
}

#------------------------------------------------------------------------------
# popup creates items

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set ($store->append, 0 => 'foo');
  $store->set ($store->append, 0 => 'bar');
  my %created;
  my $menuview = Gtk2::Ex::MenuView->new (model => $store);
  $menuview->signal_connect
    (item_create_or_update => sub {
       my ($menuview, $item, $model, $path, $iter) = @_;
       diag "create ",$path->to_string;
       $created{$path->to_string} = 'done';
       $item = Gtk2::MenuItem->new_with_label ($model->get($iter,0));
       return $item;
     });
  $menuview->popup (undef, undef, undef, undef, 1, 0);
  MyTestHelpers::wait_for_event ($menuview, 'map-event');
  my $child_count = scalar @{[$menuview->get_children]};
  is ($child_count, 2, 'popup create children - count');
  is_deeply (\%created, {0=>'done',1=>'done'},
             'popup create children - paths');
}

#------------------------------------------------------------------------------
# no signals left on model

{
  my $model = Gtk2::ListStore->new ('Glib::String');
  my $menuview = Gtk2::Ex::MenuView->new (model => $model);
  ok (MyTestHelpers::any_signal_connections($model));

  $menuview->set (model => undef);
  ok (! MyTestHelpers::any_signal_connections($model));
}

{
  my $model = Gtk2::ListStore->new ('Glib::String');
  my $menuview = Gtk2::Ex::MenuView->new (model => $model);
  ok (MyTestHelpers::any_signal_connections($model));

  my $model2 = Gtk2::ListStore->new ('Glib::String');
  $menuview->set (model => $model2);
  ok (! MyTestHelpers::any_signal_connections($model));

  ok (MyTestHelpers::any_signal_connections($model2));
}

#------------------------------------------------------------------------------
# recursive item-create-or-update

{
  my $model = Gtk2::ListStore->new ('Glib::String');
  $model->append;
  $model->append;
  my $menuview = Gtk2::Ex::MenuView->new (model => $model);
  my $item0;
  $menuview->signal_connect
    (item_create_or_update => sub {
       my ($menuview, $item, $model, $path, $iter) = @_;
       diag "item create ",$path->to_string;
       if (($path->get_indices)[0] == 1) {
         diag "recurse for item0";
         $item0 = $menuview->item_at_indices (0);
       }
       return ($item || Gtk2::MenuItem->new_with_label ($path->to_string));
     });

  isa_ok ($menuview->item_at_indices(1), 'Gtk2::MenuItem',
          'recurse - item_at_indices(1)');
  ok ($item0, 'recurse - item0 set');
  isa_ok ($item0, 'Gtk2::MenuItem', 'recurse - item0 type');
  is ($item0, $menuview->item_at_indices(0),
      'recurse - item0 same as item_at_indices(0)');
}

#------------------------------------------------------------------------------
# bad recursive item-create-or-update

{
  my $model = Gtk2::ListStore->new ('Glib::String');
  $model->append;
  my $menuview = Gtk2::Ex::MenuView->new (model => $model);
  my $recursing;
  my $err;
  $menuview->signal_connect
    (item_create_or_update => sub {
       my ($menuview, $item, $model, $path, $iter) = @_;
       diag "item_create_or_update of ",$path->to_string;
       if ($recursing++ > 5) {
         return undef;
       }
       if (! eval { $menuview->item_at_indices(0); 1 }) {
         $err = "$@";
       }
       return ($item || Gtk2::MenuItem->new_with_label ($path->to_string));
     });

  my $item = $menuview->item_at_indices(0);
  isa_ok ($item, 'Gtk2::MenuItem');
  isnt ($err, undef, 'bad recurse - expect error');
  like ($err, qr/Recursive item create or update/,
        'bad recurse - error message');
}

#------------------------------------------------------------------------------

# destroyed when weakened on unrealized
{
  my $menuview = Gtk2::Ex::MenuView->new;
  my $weak_menuview = $menuview;
  require Scalar::Util;
  Scalar::Util::weaken ($weak_menuview);
  $menuview = undef;
  MyTestHelpers::main_iterations();
  ok (! defined $weak_menuview);
}

# destroyed when weakened with model
{
  my $liststore = Gtk2::ListStore->new ('Glib::String');
  $liststore->insert_with_values (0, 0=>'foo');

  my $menuview = Gtk2::Ex::MenuView->new (model => $liststore);
  ok (MyTestHelpers::any_signal_connections($liststore));
  my $weak_menuview = $menuview;
  require Scalar::Util;
  Scalar::Util::weaken ($weak_menuview);
  $menuview = undef;
  MyTestHelpers::main_iterations();

  ok (! defined $weak_menuview);
  ok (! MyTestHelpers::any_signal_connections($liststore),
      'no leftover model signal connections');
}



exit 0;
