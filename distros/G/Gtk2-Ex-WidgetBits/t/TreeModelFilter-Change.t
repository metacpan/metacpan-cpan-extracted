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

use Test::More tests => 19;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::TreeModelFilter::Change;

{
  my $want_version = 48;
  is ($Gtk2::Ex::TreeModelFilter::Change::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::TreeModelFilter::Change->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { Gtk2::Ex::TreeModelFilter::Change->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::TreeModelFilter::Change->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------

my $myliststore_set_func_called;
my $myliststore_remove_func_called;
{
  package MyListStore;
  use Gtk2;
  use Glib::Object::Subclass 'Gtk2::ListStore';

  sub set {
    my $self = shift;
    $myliststore_set_func_called++;
    $self->SUPER::set(@_);
  }

  sub remove {
    my $self = shift;
    $myliststore_remove_func_called++;
    $self->SUPER::remove(@_);
  }
}

{
  package MyFilter;
  use Gtk2;
  use base 'Gtk2::Ex::TreeModelFilter::Change';
  use Glib::Object::Subclass 'Gtk2::TreeModelFilter';
}

{
  my $child = MyListStore->new;
  $child->set_column_types ('Glib::String');

  my $filter = MyFilter->new (child_model => $child);
  my $iter = $filter->append(undef);
  isa_ok ($iter, 'Gtk2::TreeIter',
          'append() iter return');
  { my $path = $filter->get_path($iter);
    isa_ok ($path, 'Gtk2::TreePath',
            'append() iter return - to path');
    is_deeply ([$path->get_indices], [0],
               'append() iter return - path indices');
  }

  $filter->set ($iter, 0, 'foo');
  is ($myliststore_set_func_called, 1,
      'set() calls child model set()');

  ok (! $filter->remove($iter),
      'remove() last elem return false');
  is ($myliststore_remove_func_called, 1,
      'remove() calls child model remove()');
}

#-----------------------------------------------------------------------------

{
  package MyOneRemovesAll;
  use Gtk2;
  use Glib::Object::Subclass 'Gtk2::ListStore';

  sub remove {
    my ($self, $iter) = @_;
    Test::More::diag('MyOneRemovesAll remove() all');
    while (my $iter = $self->get_iter_first) {
      $self->SUPER::remove ($iter);
    }
    return 0;
  }
}
{
  my $child = MyOneRemovesAll->new;
  $child->set_column_types ('Glib::String');
  $child->append();
  $child->append();
  $child->append();

  my $filter = MyFilter->new (child_model => $child);

  my $iter = $filter->get_iter_first;
  isa_ok ($iter, 'Gtk2::TreeIter', 'filter MyOneRemovesAll first iter');
  ok (! $filter->remove($iter),
      'filter MyOneRemovesAll remove() one elem filters out others');
  ok (! $child->get_iter_first,
      'filter MyOneRemovesAll child now empty');
}


#-----------------------------------------------------------------------------

{
  package MyOneRemovesNext;
  use Gtk2;
  use Glib::Object::Subclass 'Gtk2::ListStore';

  sub remove {
    my ($self, $iter) = @_;
    return $self->SUPER::remove ($iter)
      && $self->SUPER::remove ($iter);
  }
}
{
  my $child = MyOneRemovesNext->new;
  $child->set_column_types ('Glib::String');
  $child->set ($child->append, 0 => 'zero');
  $child->set ($child->append, 0 => 'one');
  $child->set ($child->append, 0 => 'two');
  $child->set ($child->append, 0 => 'three');
  $child->set ($child->append, 0 => 'four');

  my $filter = MyFilter->new (child_model => $child);

  my $iter = $filter->get_iter_first;
  $iter = $filter->iter_next($iter);
  isa_ok ($iter, 'Gtk2::TreeIter', 'filter MyOneRemovesNext second iter');
  ok ($filter->remove($iter),
      'filter MyOneRemovesNext remove() - remove "one"');
  is ($filter->get($iter,0), 'three',
      'filter MyOneRemovesNext remove() - leaves at "three"');
}


#-----------------------------------------------------------------------------

{
  my $child = Gtk2::ListStore->new ('Glib::String', 'Glib::Boolean');
  $child->set ($child->append, 0 => 'zero',  1 => 1);
  $child->set ($child->append, 0 => 'one',   1 => 1);
  $child->set ($child->append, 0 => 'two',   1 => 0);
  $child->set ($child->append, 0 => 'three', 1 => 0);
  $child->set ($child->append, 0 => 'four',  1 => 1);

  my $filter = MyFilter->new (child_model => $child);
  $filter->set_visible_column (1);

  my $iter = $filter->get_iter_first;
  $iter = $filter->iter_next($iter);
  isa_ok ($iter, 'Gtk2::TreeIter', 'filter Skip second iter');
  ok ($filter->remove($iter),
      'filter Skip remove() - remove "one"');
  is ($filter->get($iter,0), 'four',
      'filter Skip remove() - leaves at "four"');
}


exit 0;
