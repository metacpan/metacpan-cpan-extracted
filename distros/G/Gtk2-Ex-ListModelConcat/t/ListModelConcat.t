#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2015 Kevin Ryde

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
use Gtk2::Ex::ListModelConcat;
use Test::More tests => 252;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;

use constant VERBOSE => 0;

{
  my $want_version = 11;
  is ($Gtk2::Ex::ListModelConcat::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::ListModelConcat->VERSION,  $want_version,
      'VERSION class method');
  Gtk2::Ex::ListModelConcat->VERSION ($want_version);

  my $concat = Gtk2::Ex::ListModelConcat->new;
  is ($concat->VERSION, $want_version, 'VERSION object method');
  $concat->VERSION ($want_version);
}

require Gtk2;
MyTestHelpers::glib_gtk_versions();


# return arrayref
sub model_column_types {
  my ($model) = @_;
  return [ map {$model->get_column_type($_)} 0 .. $model->get_n_columns - 1 ];
}

# return arrayref
sub listmodel_contents {
  my ($model) = @_;
  my @ret;
  for (my $iter = $model->get_iter_first;
       $iter;
       $iter = $model->iter_next($iter)) {
    push @ret, $model->get_value($iter,0);
  }
  return \@ret;
}

sub listen_changed {
  my ($model, $subr) = @_;
  my $ret = { count => 0 };
  my $id = $model->signal_connect
    (row_changed => sub {
       my ($model, $path, $iter) = @_;
       if (VERBOSE) { diag "listen_changed() signal received"; }
       $ret->{'count'}++;
       $ret->{'path'} = [ $path->get_indices ];
       $ret->{'iter'} = $iter && [ $model->get_path($iter)->get_indices ];
       $ret->{'value'} = $iter && $model->get_value($iter,0);
     });
  &$subr();
  $model->signal_handler_disconnect ($id);
  return $ret;
}

sub listen_inserted {
  my ($model, $subr) = @_;
  my $ret = { count => 0 };
  my $id = $model->signal_connect
    (row_inserted => sub {
       my ($model, $path, $iter) = @_;
       if (VERBOSE) { diag "listen_inserted() signal received"; }
       $ret->{'count'}++;
       $ret->{'path'} = [ $path->get_indices ];
       $ret->{'iter'} = $iter && [ $model->get_path($iter)->get_indices ];
       $ret->{'value'} = $iter && $model->get_value($iter,0);
     });
  &$subr();
  $model->signal_handler_disconnect ($id);
  return $ret;
}

sub listen_reorder {
  my ($model, $subr) = @_;
  my $ret = { count => 0 };
  my $id = $model->signal_connect
    (rows_reordered => sub {
       my ($model, $path, $iter, $aref) = @_;
       if (VERBOSE) { diag "listen_reorder() signal received"; }
       $ret->{'count'}++;

       # buggy in gtk2-perl 1.183
       $path = Gtk2::TreePath->new;

       $ret->{'path'} = [ $path->get_indices ];
       $ret->{'iter'} = $iter && [ $model->get_path($iter)->get_indices ];
       $ret->{'order'} = $aref;
       if (VERBOSE) { diag "  order ",join(' ',@$aref); }
     });
  &$subr();
  $model->signal_handler_disconnect ($id);
  return $ret;
}

#------------------------------------------------------------------------------
{ my $concat = Gtk2::Ex::ListModelConcat->new;

  is_deeply ([@{$concat->get_flags}], ['list-only']);
  is ($concat->get_n_columns, 0);
  is ($concat->iter_n_children(undef), 0);
  is ($concat->get_iter_first, undef);
  is ($concat->iter_children(undef), undef);
  is ($concat->get_iter(Gtk2::TreePath->new_from_indices(0)), undef);
  is ($concat->get_iter(Gtk2::TreePath->new_from_indices(1)), undef);
  is ($concat->get_iter(Gtk2::TreePath->new_from_indices(999)), undef);
  ok (! $concat->iter_nth_child(undef,0));
  ok (! $concat->iter_nth_child(undef,1));
  ok (! $concat->iter_nth_child(undef,999));

  require Scalar::Util;
  Scalar::Util::weaken ($concat);
  is ($concat, undef, 'empty garbage collected when weakened');
}

{ my $store = Gtk2::ListStore->new ('Glib::String');
  my $concat = Gtk2::Ex::ListModelConcat->new;
  $concat->set_property (models => [ $store ]);

  is ($concat->get_n_columns, 1);
  is ($concat->iter_n_children(undef), 0);
  is ($concat->iter_children(undef), undef);
  is ($concat->get_iter_first, undef);

  Scalar::Util::weaken ($concat);
  is ($concat, undef, 'garbage collected when weakened');
}

{ my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is ($concat->get_n_columns, 1);
  is ($concat->iter_n_children(undef), 0);
  is ($concat->iter_children(undef), undef);
  is ($concat->get_iter_first, undef);

  Scalar::Util::weaken ($concat);
  is ($concat, undef, 'garbage collected when weakened');
}

{ my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set_value ($store->insert(0), 0=>'zero');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $store ]);

  is ($concat->iter_n_children(undef), 1);
  ok ($concat->iter_children(undef));
  ok ($concat->get_iter(Gtk2::TreePath->new_from_indices(0)));
  is ($concat->get_iter(Gtk2::TreePath->new_from_indices(1)), undef);
  is ($concat->get_iter(Gtk2::TreePath->new_from_indices(999)), undef);
  ok ($concat->iter_nth_child(undef,0));
  ok (! $concat->iter_nth_child(undef,1));
  ok (! $concat->iter_nth_child(undef,999));

  my $iter = $concat->get_iter_first;
  ok ($iter);
  is ($concat->get_path($iter)->to_string, '0');
  is ($concat->get_value($iter,0), 'zero');
  is ($concat->iter_children($iter), undef);
  is ($concat->iter_parent($iter), undef);
  $iter = $concat->iter_next ($iter);
  is ($iter, undef);
}

{ my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set_value ($store->insert(0), 0=>'zero');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $store, $store ]);

  is ($concat->iter_n_children(undef), 2);

  my $iter = $concat->get_iter_first;
  ok ($iter);
  is ($concat->get_path($iter)->to_string, '0');
  is ($concat->get_value($iter,0), 'zero');
  is ($concat->iter_children($iter), undef);
  ok (! $concat->iter_has_child($iter));
  is ($concat->iter_parent($iter), undef);
  $iter = $concat->iter_next ($iter);
  ok ($iter);
  is ($concat->get_path($iter)->to_string, '1');
  is ($concat->get_value($iter,0), 'zero');
  is ($concat->iter_children($iter), undef);
  is ($concat->iter_parent($iter), undef);
  ok (! $concat->iter_has_child($iter));
  $iter = $concat->iter_next ($iter);
  is ($iter, undef);

  $store->set_value ($store->insert(0), 0=>'one');
}

{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is ($concat->iter_n_children(undef), 2);
  { my $iter = $concat->iter_nth_child(undef,0);
    ok ($iter);
    is ($concat->get_value ($iter, 0), 'zero');
  }
  { my $iter = $concat->iter_nth_child(undef,1);
    ok ($iter);
    is ($concat->get_value ($iter, 0), 'one');
  }
  ok (! $concat->iter_nth_child(undef,999));

  my $iter = $concat->get_iter_first;
  ok ($iter);
  is ($concat->get_value($iter,0), 'zero');
  $iter = $concat->iter_next ($iter);
  ok ($iter);
  is ($concat->get_value($iter,0), 'one');
  $iter = $concat->iter_next ($iter);
  is ($iter, undef);

  $iter = $concat->iter_nth_child(undef, 0);
  ok ($iter);
  is ($concat->get_value($iter,0), 'zero');
  $iter = $concat->iter_nth_child(undef, 1);
  ok ($iter);
  is ($concat->get_value($iter,0), 'one');
  $iter = $concat->iter_nth_child(undef, 2);
  is ($iter, undef);

}

#------------------------------------------------------------------------------
# child_iter_to_iter

sub path_indices {
  my ($path) = @_;
  if ($path->isa('Gtk2::TreePath')) {
    return [$path->get_indices];
  } else {
    return $path;
  }
}
sub iter_indices {
  my ($model, $iter) = @_;
  if ($iter->isa('Gtk2::TreeIter')) {
    return path_indices ($model->get_path ($iter));
  } else {
    return $iter;
  }
}

{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2, $s2 ]);

  my $subiter = $s2->iter_nth_child (undef, 1);
  my $iter = $concat->convert_child_iter_to_iter ($s2, $subiter);
  isa_ok ($iter, 'Gtk2::TreeIter');
  is_deeply (iter_indices($concat,$iter), [2],
             'convert_child_iter_to_iter');

  $iter = $concat->convert_childnum_iter_to_iter (1, $subiter);
  isa_ok ($iter, 'Gtk2::TreeIter');
  is_deeply (iter_indices($concat,$iter), [2],
             'convert_childnum_iter_to_iter');

  $iter = $concat->iter_nth_child (undef, 4);
  (my $model, $subiter) = $concat->convert_iter_to_child_iter ($iter);
  is ($model, $s2,
      'convert_iter_to_child_iter - model');
  isa_ok ($subiter, 'Gtk2::TreeIter');
  is_deeply (iter_indices($s2,$subiter), [1],
             'convert_iter_to_child_iter - path');

  my ($childmodel, $childnum);
  ($childmodel, $subiter, $childnum)
    = $concat->convert_iter_to_child_iter ($iter);
  is ($childmodel, $model);
  is ($childnum, 2,
      'convert_iter_to_child_iter - model');
  isa_ok ($subiter, 'Gtk2::TreeIter');
  is_deeply (iter_indices($s2,$subiter), [1],
             'convert_iter_to_childnum_iter - path');

}


#------------------------------------------------------------------------------
# append

diag "append";
{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_inserted ($concat, sub {
                                my $iter = $concat->append;
                                my $path = $concat->get_path ($iter);
                                is_deeply ([2],[$path->get_indices]);
                              }),
             { count => 1,
               path  => [2],
               iter  => [2],
               value => undef });
  is ($concat->iter_n_children(undef), 3);

  is_deeply (listmodel_contents($concat),
             [ 'zero', 'one', undef ]);
}

#------------------------------------------------------------------------------
# prepend

{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_inserted ($concat, sub {
                                my $iter = $concat->prepend;
                                my $path = $concat->get_path ($iter);
                                is_deeply ([0],[$path->get_indices]);
                              }),
             { count => 1,
               path  => [0],
               iter  => [0],
               value => undef });
  is ($concat->iter_n_children(undef), 3);

  is_deeply (listmodel_contents($concat),
             [ undef, 'zero', 'one' ]);
}


#------------------------------------------------------------------------------
# clear

{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  $concat->clear;
  is ($concat->iter_n_children(undef), 0);

  is_deeply (listmodel_contents($concat),
             [ ]);
}


#------------------------------------------------------------------------------
# set_column_types

{
  my $s1 = Gtk2::ListStore->new ('Glib::Float');
  my $s2 = Gtk2::ListStore->new ('Glib::Float');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  $concat->set_column_types ('Glib::String', 'Glib::Double');
  is_deeply (model_column_types($s1),
             [ 'Glib::String', 'Glib::Double' ]);
  is_deeply (model_column_types($s2),
             [ 'Glib::String', 'Glib::Double' ]);
}


#------------------------------------------------------------------------------
# insert_with_values

SKIP: {
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');

  $s1->can('insert_with_values')
    or skip 'no insert_with_values()', 12;

  $s1->insert_with_values (0, 0=>'zero');
  $s2->insert_with_values (0, 0=>'one');
  $s2->insert_with_values (1, 0=>'two');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_inserted
             ($concat,
              sub {
                my $iter = $concat->insert_with_values (2, 0=>'one and a bit');
                my $path = $concat->get_path ($iter);
                is_deeply ([2],[$path->get_indices]);
              }),
             { count => 1,
               path  => [2],
               iter  => [2],
               value => 'one and a bit' });
  is ($concat->iter_n_children(undef), 4);
  is_deeply (listmodel_contents($concat),
             [ 'zero', 'one', 'one and a bit', 'two' ]);

  is_deeply (listen_inserted
             ($concat,
              sub {
                my $iter = $concat->insert_with_values (4, 0=>'end');
                my $path = $concat->get_path ($iter);
                is_deeply ([4],[$path->get_indices]);
              }),
             { count => 1,
               path  => [4],
               iter  => [4],
               value => 'end' });
  is ($concat->iter_n_children(undef), 5);
  is_deeply (listmodel_contents($concat),
             [ 'zero', 'one', 'one and a bit', 'two', 'end' ]);

  is_deeply (listen_inserted
             ($concat,
              sub {
                my $iter = $concat->insert_with_values (999, 0=>'wild');
                my $path = $concat->get_path ($iter);
                is_deeply ([5],[$path->get_indices]);
              }),
             { count => 1,
               path  => [5],
               iter  => [5],
               value => 'wild' });
  is ($concat->iter_n_children(undef), 6);
  is_deeply (listmodel_contents($concat),
             [ 'zero', 'one', 'one and a bit', 'two', 'end', 'wild' ]);
}

#------------------------------------------------------------------------------
# insert_after

{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_inserted
             ($concat, sub { my $iter = $concat->iter_nth_child(undef,1);
                             $iter = $concat->insert_after ($iter);
                             my $path = $concat->get_path ($iter);
                             is_deeply ([2],[$path->get_indices]);
                           }),
             { count => 1,
               path  => [2],
               iter  => [2],
               value => undef });
  is ($concat->iter_n_children(undef), 4);
  is_deeply (listmodel_contents($concat),
             [ 'zero', 'one', undef, 'two' ]);

  is_deeply (listen_inserted
             ($concat, sub {
                my $iter = $concat->insert_after (undef);
                my $path = $concat->get_path ($iter);
                is_deeply ([0],[$path->get_indices]);
              }),
             { count => 1,
               path  => [0],
               iter  => [0],
               value => undef });
  is ($concat->iter_n_children(undef), 5);
  is_deeply (listmodel_contents($concat),
             [ undef, 'zero', 'one', undef, 'two' ]);
}

#------------------------------------------------------------------------------
# insert_before

{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_inserted
             ($concat, sub { my $iter = $concat->iter_nth_child(undef,1);
                             $iter = $concat->insert_before ($iter);
                             my $path = $concat->get_path ($iter);
                             is_deeply ([1],[$path->get_indices]);
                           }),
             { count => 1,
               path  => [1],
               iter  => [1],
               value => undef });
  is ($concat->iter_n_children(undef), 4);
  is_deeply (listmodel_contents($concat),
             [ 'zero', undef, 'one', 'two' ]);

  is_deeply (listen_inserted
             ($concat, sub {
                my $iter = $concat->insert_before (undef);
                my $path = $concat->get_path ($iter);
                is_deeply ([4],[$path->get_indices]);
              }),
             { count => 1,
               path  => [4],
               iter  => [4],
               value => undef });
  is ($concat->iter_n_children(undef), 5);
  is_deeply (listmodel_contents($concat),
             [ 'zero', undef, 'one', 'two', undef ]);
}

#------------------------------------------------------------------------------
# iter_is_valid

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set_value ($store->insert(0), 0=>'zero');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $store ]);
  my $c2 = Gtk2::Ex::ListModelConcat->new (models => [ $store ]);

  { my $iter = $concat->get_iter_first;
    ok ($concat->iter_is_valid($iter),
        'iter_is_valid() own iter good');
    ok (! $c2->iter_is_valid($iter),
        'iter_is_valid() iter from other concat bad');
  }
  { my $iter = Gtk2::TreeIter->new_from_arrayref([0,0,0,0]);
    ok (! $concat->iter_is_valid($iter),
        'iter_is_valid() all zeros no good');
  }
  { my $iter = $store->get_iter_first;
    ok ($store->iter_is_valid($iter),
        'iter_is_valid() iter from child ok on itself');
    ok (! $concat->iter_is_valid($iter),
        'iter_is_valid() iter from child no good on concat');
  }
  { my $iter = $concat->get_iter_first;
    $store->remove ($store->get_iter_first);
    ok (! $concat->iter_is_valid($iter),
        'iter_is_valid() iter no good after child row removal');
  }
}


#------------------------------------------------------------------------------
# move_after

diag "move_after() no change";
{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  $s2->set_value ($s2->insert(2), 0=>'three');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  # as of gtk 2.12 Gtk2::ListStore emits a reordered signal for this
  # no-change move, but let's not depend on that
  { my $from = $concat->iter_nth_child(undef,2);
    my $to = $concat->iter_nth_child(undef,2);
    $concat->move_after ($from, $to);
  }
  is_deeply (listmodel_contents($concat),
             [ 'zero', 'one', 'two', 'three' ],
             'concat contents');
  is_deeply (listmodel_contents($s1),
             [ 'zero' ],
             's1 contents');
  is_deeply (listmodel_contents($s2),
             [ 'one', 'two', 'three' ],
             's2 contents');
}

diag "move_after() within submodel, upwards";
{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  $s2->set_value ($s2->insert(2), 0=>'three');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_reorder
             ($concat, sub { my $from = $concat->iter_nth_child(undef,1);
                             my $to = $concat->iter_nth_child(undef,3);
                             $concat->move_after ($from, $to) }),
             { count => 1,
               path  => [],
               iter  => undef,
               order => [0, 2, 3, 1] },
             'reorder signal');
  is_deeply (listmodel_contents($concat),
             [ 'zero', 'two', 'three', 'one' ],
             'concat contents');
  is_deeply (listmodel_contents($s1),
             [ 'zero' ],
             's1 contents');
  is_deeply (listmodel_contents($s2),
             [ 'two', 'three', 'one' ],
             's2 contents');
}

diag "move_after() within submodel, downwards";
{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  $s2->set_value ($s2->insert(2), 0=>'three');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_reorder
             ($concat, sub { my $from = $concat->iter_nth_child(undef,3);
                             my $to = $concat->iter_nth_child(undef,1);
                             $concat->move_after ($from, $to) }),
             { count => 1,
               path  => [],
               iter  => undef,
               order => [0, 1, 3, 2] },
             'reorder signal');
  is_deeply (listmodel_contents($concat),
             [ 'zero', 'one', 'three', 'two' ],
             'concat contents');
  is_deeply (listmodel_contents($s1),
             [ 'zero' ],
             's1 contents');
  is_deeply (listmodel_contents($s2),
             [ 'one', 'three', 'two' ],
             's2 contents');
}

diag "move_after() across submodel, downwards";
SKIP: {
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');

  $s1->can('insert_with_values')
    or skip 'no insert_with_values() for move_after()', 4;

  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_reorder
             ($concat, sub { my $from = $concat->iter_nth_child(undef,2);
                             my $to = $concat->iter_nth_child(undef,0);
                             $concat->move_after ($from, $to) }),
             { count => 1,
               path  => [],
               iter  => undef,
               order => [0, 2, 1] });
  is_deeply (listmodel_contents($concat),
             [ 'zero', 'two', 'one' ]);
  is_deeply (listmodel_contents($s1),
             [ 'zero', 'two' ]);
  is_deeply (listmodel_contents($s2),
             [ 'one' ]);
}

diag "move_after() across submodel, upwards";
SKIP: {
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');

  $s1->can('insert_with_values')
    or skip 'no insert_with_values() for move_after()', 4;

  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  $s2->set_value ($s2->insert(2), 0=>'three');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_reorder
             ($concat, sub { my $from = $concat->iter_nth_child(undef,0);
                             my $to = $concat->iter_nth_child(undef,2);
                             $concat->move_after ($from, $to) }),
             { count => 1,
               path  => [],
               iter  => undef,
               order => [1, 2, 0, 3] },
             'move_after() across submodel, upwards');
  is_deeply (listmodel_contents($concat),
             [ 'one', 'two', 'zero', 'three' ]);
  is_deeply (listmodel_contents($s1),
             [ ]);
  is_deeply (listmodel_contents($s2),
             [ 'one', 'two', 'zero', 'three' ]);
}

diag "move_after() across submodel, upwards to end";
SKIP: {
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');

  $s1->can('insert_with_values')
    or skip 'no insert_with_values() for move_after()', 4;

  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_reorder
             ($concat, sub { my $from = $concat->iter_nth_child(undef,0);
                             my $to = $concat->iter_nth_child(undef,2);
                             $concat->move_after ($from, $to) }),
             { count => 1,
               path  => [],
               iter  => undef,
               order => [1, 2, 0] },
             'move_after() across submodel, upwards to end');
  is_deeply (listmodel_contents($concat),
             [ 'one', 'two', 'zero' ]);
  is_deeply (listmodel_contents($s1),
             [ ]);
  is_deeply (listmodel_contents($s2),
             [ 'one', 'two', 'zero' ]);
}

diag "move_after() across submodel, down to start";
SKIP: {
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');

  $s1->can('insert_with_values')
    or skip 'no insert_with_values() for move_after()', 4;

  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_reorder
             ($concat, sub { my $from = $concat->iter_nth_child(undef,2);
                             my $to = undef;
                             $concat->move_after ($from, $to) }),
             { count => 1,
               path  => [],
               iter  => undef,
               order => [2, 0, 1] });
  is_deeply (listmodel_contents($concat),
             [ 'two', 'zero', 'one' ]);
  is_deeply (listmodel_contents($s1),
             [ 'two', 'zero' ]);
  is_deeply (listmodel_contents($s2),
             [ 'one' ]);
}

#------------------------------------------------------------------------------
# move_before

diag "move_before() no change";
{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  $s2->set_value ($s2->insert(2), 0=>'three');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  # as of gtk 2.12 Gtk2::ListStore emits a reordered signal for this
  # no-change move, but let's not depend on that
  { my $from = $concat->iter_nth_child(undef,2);
    my $to = $concat->iter_nth_child(undef,2);
    $concat->move_before ($from, $to);
  }
  is_deeply (listmodel_contents($concat),
             [ 'zero', 'one', 'two', 'three' ],
             'concat contents');
  is_deeply (listmodel_contents($s1),
             [ 'zero' ],
             's1 contents');
  is_deeply (listmodel_contents($s2),
             [ 'one', 'two', 'three' ],
             's2 contents');
}

diag "move_before() within submodel, upwards";
{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  $s2->set_value ($s2->insert(2), 0=>'three');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_reorder
             ($concat, sub { my $from = $concat->iter_nth_child(undef,1);
                             my $to = $concat->iter_nth_child(undef,3);
                             $concat->move_before ($from, $to) }),
             { count => 1,
               path  => [],
               iter  => undef,
               order => [0, 2, 1, 3] },
             'reorder signal');
  is_deeply (listmodel_contents($concat),
             [ 'zero', 'two', 'one', 'three' ],
             'concat contents');
  is_deeply (listmodel_contents($s1),
             [ 'zero' ],
             's1 contents');
  is_deeply (listmodel_contents($s2),
             [ 'two', 'one', 'three' ],
             's2 contents');
}

diag "move_before() within submodel, downwards";
{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  $s2->set_value ($s2->insert(2), 0=>'three');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_reorder
             ($concat, sub { my $from = $concat->iter_nth_child(undef,3);
                             my $to = $concat->iter_nth_child(undef,1);
                             $concat->move_before ($from, $to) }),
             { count => 1,
               path  => [],
               iter  => undef,
               order => [0, 3, 1, 2] },
             'reorder signal');
  is_deeply (listmodel_contents($concat),
             [ 'zero', 'three', 'one', 'two' ],
             'concat contents');
  is_deeply (listmodel_contents($s1),
             [ 'zero' ],
             's1 contents');
  is_deeply (listmodel_contents($s2),
             [ 'three', 'one', 'two' ],
             's2 contents');
}

diag "move_before() across submodel, downwards";
SKIP: {
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');

  $s1->can('insert_with_values')
    or skip 'no insert_with_values() for move_before()', 4;

  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s1->set_value ($s1->insert(1), 0=>'one');
  $s2->set_value ($s2->insert(0), 0=>'two');
  $s2->set_value ($s2->insert(1), 0=>'three');
  $s2->set_value ($s2->insert(2), 0=>'four');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_reorder
             ($concat, sub { my $from = $concat->iter_nth_child(undef,3);
                             my $to = $concat->iter_nth_child(undef,1);
                             $concat->move_before ($from, $to) }),
             { count => 1,
               path  => [],
               iter  => undef,
               order => [0, 3, 1, 2, 4] },
             'move_before() across submodel, downwards');
  is_deeply (listmodel_contents($concat),
             [ 'zero', 'three', 'one', 'two', 'four' ]);
  is_deeply (listmodel_contents($s1),
             [ 'zero', 'three', 'one' ]);
  is_deeply (listmodel_contents($s2),
             [ 'two', 'four' ]);
}

diag "move_before() across submodel, downwards to start";
SKIP: {
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');

  $s1->can('insert_with_values')
    or skip 'no insert_with_values() for move_before()', 4;

  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_reorder
             ($concat, sub { my $from = $concat->iter_nth_child(undef,2);
                             my $to = $concat->iter_nth_child(undef,0);
                             $concat->move_before ($from, $to) }),
             { count => 1,
               path  => [],
               iter  => undef,
               order => [2, 0, 1] },
             'move_before() across submodel, downwards to start');
  is_deeply (listmodel_contents($concat),
             [ 'two', 'zero', 'one' ]);
  is_deeply (listmodel_contents($s1),
             [ 'two', 'zero' ]);
  is_deeply (listmodel_contents($s2),
             [ 'one' ]);
}

diag "move_before() across submodel, upwards";
SKIP: {
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');

  $s1->can('insert_with_values')
    or skip 'no insert_with_values() for move_before()', 4;

  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_reorder
             ($concat, sub { my $from = $concat->iter_nth_child(undef,0);
                             my $to = $concat->iter_nth_child(undef,2);
                             $concat->move_before ($from, $to) }),
             { count => 1,
               path  => [],
               iter  => undef,
               order => [1, 0, 2] });
  is_deeply (listmodel_contents($concat),
             [ 'one', 'zero', 'two' ]);
  is_deeply (listmodel_contents($s1),
             [ ]);
  is_deeply (listmodel_contents($s2),
             [ 'one', 'zero', 'two' ]);
}

diag "move_before() across submodel, up to end";
SKIP: {
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');

  $s1->can('insert_with_values')
    or skip 'no insert_with_values() for move_before()', 4;

  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_reorder
             ($concat, sub { my $from = $concat->iter_nth_child(undef,0);
                             my $to = undef;
                             $concat->move_before ($from, $to) }),
             { count => 1,
               path  => [],
               iter  => undef,
               order => [1, 2, 0] });
  is_deeply (listmodel_contents($concat),
             [ 'one', 'two', 'zero' ]);
  is_deeply (listmodel_contents($s1),
             [ ]);
  is_deeply (listmodel_contents($s2),
             [ 'one', 'two', 'zero' ]);
}


#------------------------------------------------------------------------------
# remove

diag 'remove';
{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  my $iter = $concat->get_iter_first;
  ok ($concat->remove ($iter));
  ok ($concat->iter_is_valid ($iter));
  is_deeply ([ $concat->get_path($iter)->get_indices ],
             [ 0 ]);
  is_deeply (listmodel_contents($concat),
             [ 'one' ]);
  is_deeply (listmodel_contents($s1),
             [ ]);
  is_deeply (listmodel_contents($s2),
             [ 'one' ]);

  ok (! $concat->remove ($iter));
  ok (! $concat->iter_is_valid ($iter));
  is_deeply ($iter->to_arrayref(0), [0,0,undef,undef]);
  is_deeply (listmodel_contents($concat),
             [ ]);
  is_deeply (listmodel_contents($s1),
             [ ]);
  is_deeply (listmodel_contents($s2),
             [ ]);
}

{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  my $iter = $concat->iter_nth_child (undef, 1);
  ok (! $concat->remove ($iter));
  ok (! $concat->iter_is_valid ($iter));
  is_deeply (listmodel_contents($concat),
             [ 'zero' ]);
  is_deeply (listmodel_contents($s1),
             [ 'zero' ]);
  is_deeply (listmodel_contents($s2),
             [ ]);
}

# three copies of one model
{
  my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set_value ($store->insert(0), 0=>'zero');
  $store->set_value ($store->insert(1), 0=>'one');
  my $concat = Gtk2::Ex::ListModelConcat->new
    (models => [ $store, $store, $store ]);

  my $iter = $concat->iter_nth_child (undef, 4); # second last
  ok ($concat->remove ($iter));
  ok ($concat->iter_is_valid ($iter));
  is_deeply ([$concat->get_path($iter)->get_indices], [ 2 ]);
  is_deeply (listmodel_contents($store),
             [ 'one' ]);
  is_deeply (listmodel_contents($concat),
             [ 'one', 'one', 'one' ]);

  ok (! $concat->remove ($iter),
      'remove() last elem of three copies - return no further elements');
  ok (! $concat->iter_is_valid ($iter),
      'remove() last elem of three copies - iter invalidated');
  is_deeply (listmodel_contents($store), [ ],
             'remove() last elem of three copies - submodel empty');
  is_deeply (listmodel_contents($concat), [ ],
             'remove() last elem of three copies - concat empty');
}

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set_value ($store->insert(0), 0=>'zero');
  $store->set_value ($store->insert(1), 0=>'one');
  my $concat = Gtk2::Ex::ListModelConcat->new
    (models => [ $store, $store, $store ]);

  my $iter = $concat->iter_nth_child (undef, 0);
  ok ($concat->remove ($iter));
  ok ($concat->iter_is_valid ($iter));
  is_deeply ([$concat->get_path($iter)->get_indices], [ 0 ]);
  is_deeply (listmodel_contents($store),
             [ 'one' ]);
  is_deeply (listmodel_contents($concat),
             [ 'one', 'one', 'one' ]);

  ok (! $concat->remove ($iter));
  ok (! $concat->iter_is_valid ($iter));
  is_deeply (listmodel_contents($store), [ ]);
  is_deeply (listmodel_contents($concat), [ ]);
}

#------------------------------------------------------------------------------
# reorder

diag ('reorder');
{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s1->set_value ($s1->insert(1), 0=>'one');
  $s2->set_value ($s2->insert(0), 0=>'two');
  $s2->set_value ($s2->insert(1), 0=>'three');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  $concat->reorder (0, 2, 1, 3);
  is_deeply (listmodel_contents($concat),
             [ 'zero', 'two', 'one', 'three' ]);
  is_deeply (listmodel_contents($s1),
             [ 'zero', 'two' ]);
  is_deeply (listmodel_contents($s2),
             [ 'one', 'three' ]);
}

{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s1->set_value ($s1->insert(1), 0=>'one');
  $s2->set_value ($s2->insert(0), 0=>'two');
  $s2->set_value ($s2->insert(1), 0=>'three');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  $concat->reorder (1, 2, 3, 0);
  is_deeply (listmodel_contents($concat),
             [ 'one', 'two', 'three', 'zero' ]);
  is_deeply (listmodel_contents($s1),
             [ 'one', 'two' ]);
  is_deeply (listmodel_contents($s2),
             [ 'three', 'zero' ]);
}

#------------------------------------------------------------------------------
# set

{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  # change in submodel seen in concat
  is_deeply (listen_changed ($concat,
                             sub { my $iter = $s1->get_iter_first;
                                   $s1->set ($iter, 0 => 'ZERO') }),
             { count => 1,
               path  => [0],
               iter  => [0],
               value => 'ZERO' });
  is ($concat->iter_n_children(undef), 2);

  # change in concat seen in submodel
  is_deeply (listen_changed ($s2,
                             sub { my $iter = $concat->iter_nth_child(undef,1);
                                   $concat->set ($iter, 0 => 'ONE') }),
             { count => 1,
               path  => [0],
               iter  => [0],
               value => 'ONE' });
  is ($concat->iter_n_children(undef), 2);

  # change in concat seen in concat
  is_deeply (listen_changed ($concat,
                             sub { my $iter = $concat->iter_nth_child(undef,1);
                                   $concat->set ($iter, 0 => 'TWO') }),
             { count => 1,
               path  => [1],
               iter  => [1],
               value => 'TWO' });
  is ($concat->iter_n_children(undef), 2);
}

#------------------------------------------------------------------------------
# set_value

{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  # change in submodel seen in concat
  is_deeply (listen_changed ($concat,
                             sub { my $iter = $s1->get_iter_first;
                                   $s1->set_value ($iter, 0 => 'ZERO') }),
             { count => 1,
               path  => [0],
               iter  => [0],
               value => 'ZERO' });
  is ($concat->iter_n_children(undef), 2);

  # change in concat seen in submodel
  is_deeply (listen_changed ($s2,
                             sub { my $iter = $concat->iter_nth_child(undef,1);
                                   $concat->set_value ($iter, 0 => 'ONE') }),
             { count => 1,
               path  => [0],
               iter  => [0],
               value => 'ONE' });
  is ($concat->iter_n_children(undef), 2);

  # change in concat seen in concat
  is_deeply (listen_changed ($concat,
                             sub { my $iter = $concat->iter_nth_child(undef,1);
                                   $concat->set_value ($iter, 0 => 'TWO') }),
             { count => 1,
               path  => [1],
               iter  => [1],
               value => 'TWO' });
  is ($concat->iter_n_children(undef), 2);
}

#------------------------------------------------------------------------------
# swap

# within submodel
{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_reorder
             ($concat,
              sub { my $iter_a = $concat->iter_nth_child(undef,1);
                    my $iter_b = $concat->iter_nth_child(undef,2);
                    $concat->swap ($iter_a, $iter_b);
                  }),
             { count => 1,
               path  => [],
               iter  => undef,
               order => [ 0, 2, 1 ] });
  is_deeply (listmodel_contents($concat),
             [ 'zero', 'two', 'one' ]);
  is_deeply (listmodel_contents($s1),
             [ 'zero' ]);
  is_deeply (listmodel_contents($s2),
             [ 'two', 'one' ]);
}

# across submodels
{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_reorder
             ($concat,
              sub { my $iter_a = $concat->iter_nth_child(undef,0);
                    my $iter_b = $concat->iter_nth_child(undef,1);
                    $concat->swap ($iter_a, $iter_b);
                  }),
             { count => 1,
               path  => [],
               iter  => undef,
               order => [ 1, 0, 2 ] });
  is_deeply (listmodel_contents($concat),
             [ 'one', 'zero', 'two' ]);
  is_deeply (listmodel_contents($s1),
             [ 'one' ]);
  is_deeply (listmodel_contents($s2),
             [ 'zero', 'two' ]);
}

# swap of submodel
{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s1, $s2 ]);

  is_deeply (listen_reorder ($concat,
                             sub { my $iter_a = $s2->iter_nth_child(undef,0);
                                   my $iter_b = $s2->iter_nth_child(undef,1);
                                   $s2->swap ($iter_a, $iter_b);
                                 }),
             { count => 1,
               path  => [],
               iter  => undef,
               order => [ 0, 2, 1 ] });
}

# swap of submodel appearing multiple times
{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  $s1->set_value ($s1->insert(0), 0=>'zero');
  $s2->set_value ($s2->insert(0), 0=>'one');
  $s2->set_value ($s2->insert(1), 0=>'two');
  my $concat = Gtk2::Ex::ListModelConcat->new (models => [ $s2, $s1, $s2 ]);

  is_deeply (listen_reorder ($concat,
                             sub { my $iter_a = $s2->iter_nth_child(undef,0);
                                   my $iter_b = $s2->iter_nth_child(undef,1);
                                   $s2->swap ($iter_a, $iter_b);
                                 }),
             { count => 1,
               path  => [],
               iter  => undef,
               order => [ 1, 0, 2, 4, 3 ] });
}

#------------------------------------------------------------------------------
# concat inside concat

{
  my $store = Gtk2::ListStore->new ('Glib::String');
  $store->set_value ($store->insert(0), 0=>'zero');
  $store->set_value ($store->insert(1), 0=>'one');
  my $concat_inner = Gtk2::Ex::ListModelConcat->new (models=>[$store]);
  my $concat_outer = Gtk2::Ex::ListModelConcat->new (models=>[$concat_inner]);

  is ($concat_outer->iter_n_children(undef), 2,
      'outer n_children');
  is_deeply (listmodel_contents($concat_outer),
             [ 'zero', 'one' ],
             'outer contents');

  is_deeply (listen_changed ($concat_outer,
                             sub { my $iter = $store->get_iter_first;
                                   $store->set ($iter, 0 => 'ZERO') }),
             { count => 1,
               path  => [0],
               iter  => [0],
               value => 'ZERO' });

  is_deeply (listen_inserted ($concat_outer,
                              sub { $store->insert(1) }),
             { count => 1,
               path  => [1],
               iter  => [1],
               value => undef });
  is_deeply (listmodel_contents($concat_outer),
             [ 'ZERO', undef, 'one' ],
             'outer contents after insert');

}

#------------------------------------------------------------------------------
# append_model() method and property

{
  my $s1 = Gtk2::ListStore->new ('Glib::String');
  my $s2 = Gtk2::ListStore->new ('Glib::String');
  my $concat = Gtk2::Ex::ListModelConcat->new;
  my $saw_notify_models = 0;
  $concat->signal_connect ('notify::models' => sub {
                             ### append_model notify
                             $saw_notify_models++;
                           });

  $saw_notify_models = 0;
  $concat->append_model ($s1);
  is ($saw_notify_models, 1, 'append_model() method - notify');
  ### $concat
  is_deeply ($concat->get_property('models'), [$s1],
             'append_model() method - models set');

  $saw_notify_models = 0;
  $concat->set_property (append_model => $s2);
  is ($saw_notify_models, 1, 'append-model property - notify');
  is_deeply ($concat->get_property('models'), [$s1,$s2],
             'append-model property - models set');
}

exit 0;
