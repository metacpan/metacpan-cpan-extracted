# Copyright 2008, 2009, 2010, 2015, 2016 Kevin Ryde

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


package Gtk2::Ex::ListModelConcat;
use 5.008;
use strict;
use warnings;
# 1.201 for drag_data_get() stack fix, and multi-column $model->get() fix
use Gtk2 1.201;
use Carp;
use List::Util qw(min max);
use Scalar::Util 1.18; # 1.18 for pure-perl refaddr() fix
use Gtk2::Ex::TreeModel::ImplBits;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 11;

use Glib::Object::Subclass
  'Glib::Object',
  interfaces => [ 'Gtk2::TreeModel',
                  'Gtk2::TreeDragSource',
                  'Gtk2::TreeDragDest',
                  # Gtk2::Buildable new in Gtk 2.12, omit if not available
                  Gtk2::Widget->isa('Gtk2::Buildable')
                  ? ('Gtk2::Buildable') : ()
                ],
  properties => [ Glib::ParamSpec->scalar
                  ('models',
                   'Models',
                   'Arrayref of list model objects to concatenate.',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('append-model',
                   'Append model',
                   'Append a model to the concatenation.',
                   'Gtk2::TreeModel',
                   ['writable']),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  ### ListModelConcat INIT_INSTANCE()
  Gtk2::Ex::TreeModel::ImplBits::random_stamp ($self);
  $self->{'models'} = [];
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  ### ListModelConcat SET_PROPERTY(): $pspec->get_name
  ### $newval
  my $pname = $pspec->get_name;

  if ($pname eq 'append_model') {
    $self->append_model ($newval);
    return;
  }
  if ($pname eq 'models') {
    foreach my $model (@$newval) {
      (Scalar::Util::blessed($model) && $model->isa('Gtk2::TreeModel'))
        or croak 'ListModelConcat: sub-model is not a Gtk2::TreeModel';
    }
    my $models = $self->{'models'};
    @$models = @$newval;  # copy input

    require Glib::Ex::SignalIds;
    my @signals;
    $self->{'signals'} = \@signals;
    my %done_reordered;

    foreach my $i (0 .. $#$models) {
      my $model = $models->[$i];
      my $userdata = [ $self, $i ];
      # weaken to avoid a circular reference which would prevent a Concat
      # containing models from being garbage collected
      Scalar::Util::weaken ($userdata->[0]);

      # the reordered signal is only connected once if the model appears
      # multiple times
      my @reordered;
      $done_reordered{Scalar::Util::refaddr($model)} ||= do {
        push @reordered, $model->signal_connect
          (rows_reordered => \&_do_rows_reordered, $userdata);
        1;
      };
      push @signals, Glib::Ex::SignalIds->new
        ($model,
         $model->signal_connect (row_changed => \&_do_row_changed, $userdata),
         $model->signal_connect (row_deleted => \&_do_row_deleted, $userdata),
         $model->signal_connect (row_inserted=> \&_do_row_inserted,$userdata),
         @reordered);
    }
    ### models now: $self->{'models'}

  } else {
    $self->{$pname} = $newval;  # per default GET_PROPERTY
  }
}

sub append_model {
  my $self = shift;
  ### ListModelConcat append_model(): @_
  $self->set_property (models => [ @{$self->{'models'}}, @_ ]);
}


#------------------------------------------------------------------------------
# TreeModel interface

# gtk_tree_model_get_flags
#
use constant GET_FLAGS => [ 'list-only' ];

# gtk_tree_model_get_n_columns
#
sub GET_N_COLUMNS {
  my ($self) = @_;
  ### ListModelConcat GET_N_COLUMNS()
  my $model = $self->{'models'}->[0]
    || return 0; # when no models
  return $model->get_n_columns;
}

# gtk_tree_model_get_column_type
#
sub GET_COLUMN_TYPE {
  my ($self, $col) = @_;
  #### ListModelConcat GET_COLUMN_TYPE()
  my $model = $self->{'models'}->[0] or _no_submodels('get_column_type');
  return $model->get_column_type ($col);
}

# gtk_tree_model_get_iter
#
sub GET_ITER {
  my ($self, $path) = @_;
  #### ListModelConcat GET_ITER(), path: $path->to_string
  if ($path->get_depth != 1) { return undef; }
  my ($index) = $path->get_indices;
  if ($index >= _total_length($self)) { return undef; }
  return _index_to_iter ($self, $index);
}

# gtk_tree_model_get_path
#
sub GET_PATH {
  my ($self, $iter) = @_;
  #### ListModelConcat get_path
  return Gtk2::TreePath->new_from_indices (_iter_to_index ($self, $iter));
}

# gtk_tree_model_get_value
#
sub GET_VALUE {
  my ($self, $iter, $col) = @_;
  #### ListModelConcat get_value iter: $iter->[0],$iter->[1]
  #### col: $col
  my $index = _iter_to_index ($self, $iter);
  my ($model, $subiter) = _index_to_subiter ($self, $index);
  return $model->get_value ($subiter, $col);
}

# gtk_tree_model_iter_next
#
sub ITER_NEXT {
  my ($self, $iter) = @_;
  #### ListModelConcat iter_next
  my $index = _iter_to_index ($self, $iter);
  $index++;
  if ($index < _total_length($self)) {
    return _index_to_iter ($self, $index);
  } else {
    return undef;
  }
}

# gtk_tree_model_iter_has_child
# my ($self, $iter) = @_;
# $iter never undef here, so always asking about an ordinary row, and
# there's nothing under the rows
#
use constant ITER_HAS_CHILD => 0;

# gtk_tree_model_iter_n_children
#
sub ITER_N_CHILDREN {
  my ($self, $iter) = @_;
  ### ListModelConcat iter_n_children
  if (defined $iter) {
    return 0;  # nothing under rows
  } else {
    return _total_length($self);
  }
}

# gtk_tree_model_iter_children
#
sub ITER_CHILDREN {
  # my ($self, $iter) = @_;
  ### ListModelConcat iter_children
  push @_, 0;
  goto &ITER_NTH_CHILD;
}

# gtk_tree_model_iter_nth_child
#
sub ITER_NTH_CHILD {
  my ($self, $iter, $n) = @_;
  ### ListModelConcat iter_nth_child: $n
  if (defined $iter) {
    return undef;
  }
  if ($n < _total_length($self)) {
    return _index_to_iter ($self, $n);
  } else {
    return undef;
  }
}

# gtk_tree_model_iter_parent
# my ($self, $iter) = @_;
# no parent rows in a list-only
#
use constant ITER_PARENT => undef;


#------------------------------------------------------------------------------
# iter conversions

# return ($model, $subiter, $mnum)
sub convert_iter_to_child_iter {
  my ($self, $iterobj) = @_;
  return _index_to_subiter ($self, _iterobj_to_index($self,$iterobj));
}

sub convert_child_iter_to_iter {
  my ($self, $model, $subiter) = @_;
  my $models = $self->{'models'};
  for (my $mnum = 0; $mnum < @$models; $mnum++) {
    if ($models->[$mnum] == $model) {
      return $self->convert_childnum_iter_to_iter ($mnum, $subiter);
    }
  }
  croak "ListModelConcat does not contain '$model'";
}
sub convert_childnum_iter_to_iter {
  my ($self, $mnum, $subiter) = @_;
  my $models = $self->{'models'};
  my $model = $models->[$mnum] || croak "No model number $mnum";
  my $subpath = $model->get_path ($subiter);
  my ($subindex) = $subpath->get_indices;
  my $positions = _model_positions($self);
  return _index_to_iterobj ($self, $positions->[$mnum] + $subindex);
}


#------------------------------------------------------------------------------
# our iters

sub _index_to_iter {
  my ($self, $index) = @_;
  return [ $self->{'stamp'}, $index, undef, undef ];
}
sub _iter_to_index {
  my ($self, $iter) = @_;
  if (! defined $iter) { return undef; }
  if ($iter->[0] != $self->{'stamp'}) {
    croak "iter is not for this ", ref($self),
      " (stamp ", $iter->[0], " want ", $self->{'stamp'}, ")";
  }
  return $iter->[1];
}

sub _iterobj_to_index {
  my ($self, $iterobj) = @_;
  if (! defined $iterobj) { croak 'ListModelConcat: iter cannot be undef'; }
  return _iter_to_index ($self, $iterobj->to_arrayref ($self->{'stamp'}));
}
sub _index_to_iterobj {
  my ($self, $index) = @_;
  return Gtk2::TreeIter->new_from_arrayref (_index_to_iter ($self, $index));
}


#------------------------------------------------------------------------------
# sub-model lookups

sub _model_positions {
  my ($self) = @_;
  return ($self->{'positions'} ||= do {
    my $models = $self->{'models'};
    my $pos = 0;
    return ($self->{'positions'}
            = [ 0, map { $pos += $_->iter_n_children(undef) } @$models ]);
  });
}
sub _model_offset {
  my ($self, $mnum) = @_;
  my $positions = _model_positions ($self);
  return $positions->[$mnum];
}
sub _total_length {
  my ($self) = @_;
  return _model_positions($self)->[-1];
}

# return ($model, $subiter, $mnum)
sub _index_to_subiter {
  my ($self, $index) = @_;
  my ($model, $subindex, $mnum) = _index_to_subindex ($self, $index);
  return ($model, $model->iter_nth_child(undef,$subindex), $mnum);
}

# return ($model, $subindex, $mnum)
sub _index_to_subindex {
  my ($self, $index) = @_;
  if ($index < 0) {
    croak 'ListModelConcat: invalid iter (negative index)';
  }
  my $models = $self->{'models'};
  my $positions = _model_positions ($self);
  if ($index >= $positions->[-1]) {
    croak 'ListModelConcat: invalid iter (index too big)';
  }
  for (my $i = $#$positions - 1; $i >= 0; $i--) {
    if ($positions->[$i] <= $index) {
      return ($models->[$i], $index - $positions->[$i], $i);
    }
  }
  croak 'ListModelConcat: invalid iter (no sub-models at all now)';
}

# sub _bsearch {
#   my ($aref, $target) = @_;
#   my $lo = 0;
#   my $hi = @$aref;
#   for (;;) {
#     my $mid = int (($lo + $hi) / 2);
#     if ($mid == $lo) { return $mid; }
# 
#     my $elem = $aref->[$mid];
#     if ($elem > $target) {
#       $hi = $mid;
#     } elsif ($elem < $target) {
#       $lo = $mid+1;
#     } else {
#       return $mid;
#     }
#   }
# }

sub _no_submodels {
  my ($operation) = @_;
  croak "ListModelConcat: no sub-models to $operation";
}


#------------------------------------------------------------------------------
# sub-model signals

# 'row-changed' on the submodels
# called multiple times if a model is present multiple times
#
sub _do_row_changed {
  my ($model, $subpath, $subiter, $userdata) = @_;
  ### ListModelConcat row_changed handler
  my ($self, $mnum)= @$userdata;
  if (! $self) { return; }
  if ($self->{'suppress_signals'}) { return; }
  if ($subpath->get_depth != 1) { return; }  # ignore non-toplevel

  my ($subindex) = $subpath->get_indices;
  my $index = $subindex + _model_offset($self,$mnum);
  my $path = Gtk2::TreePath->new_from_indices ($index);
  my $iterobj = _index_to_iterobj ($self, $index);
  $self->row_changed ($path, $iterobj);
}

# 'row-inserted' on the submodels
# called multiple times if a model is present multiple times, going from
# first to last, which should present the positions correctly to the
# listeners, even if the data has all the inserts already done
#
sub _do_row_inserted {
  my ($model, $subpath, $subiter, $userdata) = @_;
  ### ListModelConcat row_inserted handler
  my ($self, $mnum) = @$userdata;
  if (! $self) { return; }
  if ($self->{'suppress_signals'}) { return; }
  if ($subpath->get_depth != 1) { return; }  # ignore non-toplevel

  if (my $positions = $self->{'positions'}) {
    foreach my $i ($mnum+1 .. $#$positions) {
      $positions->[$i] ++;
    }
  }

  my ($subindex) = $subpath->get_indices;
  my $index = $subindex + _model_offset($self,$mnum);
  my $path = Gtk2::TreePath->new_from_indices ($index);
  my $iterobj = _index_to_iterobj ($self, $index);
  $self->row_inserted ($path, $iterobj);
}

# 'row-deleted' on the submodels
# called multiple times if a model is present multiple times, going from
# first to last, which should present the positions correctly to the
# listeners, even if the data has all the inserts already done
#
sub _do_row_deleted {
  my ($model, $subpath, $userdata) = @_;
  my ($self, $mnum) = @$userdata;
  ### ListModelConcat row_deleted handler
  if (! $self) { return; }
  if ($self->{'suppress_signals'}) { return; }
  if ($subpath->get_depth != 1) { return; }  # ignore non-toplevel

  if (my $positions = $self->{'positions'}) {
    foreach my $i ($mnum+1 .. $#$positions) {
      $positions->[$i] --;
    }
  }

  my ($subindex) = $subpath->get_indices;
  my $index = $subindex + _model_offset($self,$mnum);
  my $path = Gtk2::TreePath->new_from_indices ($index);
  $self->row_deleted ($path);
}

# 'rows-reordered' on the submodels
# called just once if a model is present multiple times, and a single
# rows-reordered with all changes generated here for listeners
#
sub _do_rows_reordered {
  my ($model, $path, $iter, $subaref, $userdata) = @_;
  my ($self, $mnum) = @$userdata;
  if (! $self) { return; }
  ### ListModelConcat rows_reordered handler
  if ($self->{'suppress_signals'}) { return; }
  if ($path->get_depth != 0) { return; } # ignore non-toplevel

  # array[newpos] = oldpos, ie. the array elem says where the row used to be
  # before the reordering.  $subaref says that of its sub-model portion of
  # @array.
  #
  my @array = (0 .. _total_length($self) - 1);
  my $models = $self->{'models'};
  my $positions = _model_positions($self);
  foreach my $i (0 .. $#$models) {
    if ($models->[$i] == $model) {
      my $offset = $positions->[$i];
      foreach my $i (0 .. $#$subaref) {
        $array[$offset + $i] = $subaref->[$i] + $offset;
      }
    }
  }
  $self->rows_reordered ($path, undef, @array);
}


#------------------------------------------------------------------------------
# Gtk2::ListStore compatible methods


# gtk_list_store_append
# new row at end, return iter pointing to it
sub append {
  my ($self) = @_;
  my $model = $self->{'models'}->[-1] or _no_submodels('append');
  return $model->append
    && _index_to_iterobj ($self, _total_length($self) - 1);
}

# gtk_list_store_prepend
# new row at start, return iter pointing to it
sub prepend {
  my ($self) = @_;
  my $model = $self->{'models'}->[0] or _no_submodels('prepend');
  return $model->prepend
    && _index_to_iterobj ($self, 0);
}

# The sub-models should generate row-deleted signals like Gtk2::ListModel
# does.  Normally it's just repeated delete of item 0, though if a model
# appears more than once in the Concat the copies further on are reported
# too, which leads to a strange, though correct, sequence.
sub clear {
  my ($self) = @_;
  foreach my $model (@{$self->{'models'}}) {
    $model->clear;
  }
  # new stamp to invalidate all existing iters like GtkListStore does
  Gtk2::Ex::TreeModel::ImplBits::random_stamp ($self);
}

sub set_column_types {
  my ($self, @types) = @_;
  foreach my $model (@{$self->{'models'}}) {
    $model->set_column_types (@types);
  }
}

sub set {
  my $self = shift;
  my $iterobj = shift;
  my ($model, $subiter) = $self->convert_iter_to_child_iter ($iterobj);
  $model->set ($subiter, @_);
}
sub set_value {
  my $self = shift;
  my $iterobj = shift;
  my ($model, $subiter) = $self->convert_iter_to_child_iter ($iterobj);
  $model->set_value ($subiter, @_);
}


# insert before $index, or append if $index past last existing row
# insert_with_values the same, taking col=>value pairs
sub insert {
  unshift @_, 'insert';
  goto &_insert;
}
sub insert_with_values {
  unshift @_, 'insert_with_values';
  goto &_insert;
}
sub _insert {
  my ($method, $self, $index, @args) = @_;
  my ($model, $subindex, $mnum);
  my $total_length = _total_length ($self);
  if ($index >= $total_length) {
    $index = $total_length; # in case wildly past end
    my $models = $self->{'models'};
    $model = $self->{'models'}->[-1]
      or _no_submodels($method);
    $mnum = $#$models;
    $subindex = $index; # past end
  } else {
    ($model, $subindex, $mnum) = _index_to_subindex ($self, $index);
  }
  my $subiter = $model->$method ($subindex, @args);
  return _subiter_to_iterobj ($self, $model, $subiter, $mnum);
}

# insert after $iterobj, or at beginning if $iterobj undef (yes, the beginning)
sub insert_after {
  unshift @_, 'insert_after', 0;
  goto &_insert_beforeafter;
}
sub insert_before {
  unshift @_, 'insert_before', -1;
  goto &_insert_beforeafter;
}
sub _insert_beforeafter {
  my ($method, $mnum, $self, $iterobj) = @_;
  my ($model, $subiter);
  if ($iterobj) {
    ($model, $subiter, $mnum) = $self->convert_iter_to_child_iter ($iterobj);
  } else {
    my $models = $self->{'models'};
    $model = $models->[$mnum] or _no_submodels($method);
    if ($mnum) { $mnum = $#$models; }
    $subiter = undef;
  }
  $subiter = $model->$method ($subiter);
  return _subiter_to_iterobj ($self, $model, $subiter, $mnum);
}

sub _subiter_to_iterobj {
  my ($self, $model, $subiter, $mnum) = @_;
  my $positions = _model_positions ($self);
  my ($subindex) = $model->get_path($subiter)->get_indices;
  my $index = $positions->[$mnum] + $subindex;
  return _index_to_iterobj ($self, $index);
}

sub iter_is_valid {
  my ($self, $iter) = @_;
  my $a = eval { $iter->to_arrayref($self->{'stamp'}) };
  return ($a && $a->[1] < _total_length($self));
}

# gtk_list_store_move_after
# $dst_iterobj undef means the start (yes, the start) of the list
sub move_after {
  my ($self, $src_iterobj, $dst_iterobj) = @_;
  my $src_index = _iterobj_to_index ($self, $src_iterobj);
  my ($src_model, $src_subiter) = _index_to_subiter ($self, $src_index);

  my ($dst_index, $dst_model, $dst_subindex);
  if (defined $dst_iterobj) {
    $dst_index = _iterobj_to_index ($self, $dst_iterobj);
    ($dst_model, $dst_subindex) = _index_to_subindex ($self, $dst_index);
  } else {
    $dst_index = -1;
    $dst_model = $self->{'models'}->[0] or _no_submodels('insert_after');
    $dst_subindex = 0;
  }

  if ($src_model == $dst_model) {
    my $dst_subiter
      = $dst_iterobj && $dst_model->iter_nth_child (undef, $dst_subindex);
    $src_model->move_after ($src_subiter, $dst_subiter);

  } else {
    my $rem = _need_method ($src_model, 'remove');
    my $ins = _need_method ($dst_model, 'insert_with_values');
    my @row = _treemodel_extract_row ($src_model, $src_subiter);
    my $dst_ins_subindex = ($dst_iterobj ? $dst_subindex + 1 : 0);

    { local $self->{'suppress_signals'} = 1;
      $ins->($dst_model, $dst_ins_subindex, @row);
      $rem->($src_model, $src_subiter);
    }
    delete $self->{'positions'};  # recalculate

    _move_after_reorder ($self, $src_index, $dst_index);
  }
}

# Emit a 'rows-reordered' signal for a move of row $src_index to after
# $dst_index.  $dst_index can be -1 for the very start.
sub _move_after_reorder {
  my ($self, $src_index, $dst_index) = @_;
  my $path = Gtk2::TreePath->new;
  my $last_index = _total_length($self) - 1;

  if ($dst_index >= $src_index) {
    # upwards move eg. 0 to after 4 becomes 1,2,3,4,0
    $self->rows_reordered
      ($path, undef,
       0 .. $src_index-1,            # before, unchanged
       $src_index+1 .. $dst_index,   # shifted
       $src_index,                   # moved row
       $dst_index+1 .. $last_index); # after, unchanged

  } else {
    # downwards move eg. 4 to after 0 becomes 0,4,1,2,3
    $self->rows_reordered
      ($path, undef,
       0 .. $dst_index,              # before, unchanged
       $src_index,                   # moved row
       $dst_index+1 .. $src_index-1, # shifted
       $src_index+1 .. $last_index); # after, unchanged
  }
}

# gtk_list_store_move_before
# $dst_iterobj undef means the end (yes, the end) of the list
sub move_before {
  my ($self, $src_iterobj, $dst_iterobj) = @_;
  my $src_index = _iterobj_to_index ($self, $src_iterobj);
  my ($src_model, $src_subiter) = _index_to_subiter ($self, $src_index);

  my ($dst_index, $dst_model, $dst_subindex);
  if ($dst_iterobj) {
    $dst_index = _iterobj_to_index ($self, $dst_iterobj);
    ($dst_model, $dst_subindex) = _index_to_subindex ($self, $dst_index);
  } else {
    $dst_index = _total_length($self);
    $dst_model = $self->{'models'}->[-1] or _no_submodels('insert_after');
    $dst_subindex = $dst_index;
  }

  if ($src_model == $dst_model) {
    my $dst_subiter
      = $dst_iterobj && $dst_model->iter_nth_child (undef, $dst_subindex);
    $src_model->move_before ($src_subiter, $dst_subiter);

  } else {
    my $rem = _need_method ($src_model, 'remove');
    my $ins = _need_method ($dst_model, 'insert_with_values');
    my @row = _treemodel_extract_row ($src_model, $src_subiter);

    { local $self->{'suppress_signals'} = 1;
      $ins->($dst_model, $dst_subindex, @row);
      $rem->($src_model, $src_subiter);
    }
    delete $self->{'positions'};  # recalculate

    _move_after_reorder ($self, $src_index, $dst_index-1);
  }
}

sub _need_method {
  my ($model, $name) = @_;
  return ($model->can($name)
          || croak "ListModelConcat: submodel doesn't support '$name'");
}

# gtk_list_store_remove
#
# Usually deleting a row just means our $index in $iterobj should stay the
# same, only with a check it wasn't the very last row deleted.  But if the
# target $model appears more than once then deleting in its second or
# subsequent appearance will delete a row before and $index in $iterobj must
# be moved down.  For that reason get a fresh @$positions after
# $model->remove.
#
sub remove {
  my ($self, $iterobj) = @_;
  if (! defined $iterobj) { croak 'Cannot remove iter "undef"'; }
  my $index = _iterobj_to_index ($self, $iterobj);
  my ($model, $subiter, $mnum) = _index_to_subiter ($self, $index);

  my $submore = $model->remove ($subiter);
  my $positions = _model_positions($self);

  if ($submore) {
    # $subiter has been updated to the next row, make an iter from it
    my $subpath = $model->get_path ($subiter);
    my ($subindex) = $subpath->get_indices;
    $index = $positions->[$mnum] + $subindex;

  } else {
    # nothing more in this $model, so we're at the start of the following
    # model, unless it and all following are empty
    if (defined ($index = $positions->[$mnum+1])) {
      if ($index >= _total_length($self)) {
        $index = undef;
      }
    }
  }

  if (defined $index) {
    $iterobj->set ([ $self->{'stamp'}, $index, undef, undef ]);
    return 1; # more rows
  } else {
    # zap iter so it's not accidentally re-used (same as GtkListStore does)
    $iterobj->set ([ 0, 0, undef, undef ]);
    return 0; # no more rows
  }
}

# gtk_list_store_reorder
#
sub reorder {
  my ($self, @neworder) = @_;

  my $len = _total_length($self);
  if (@neworder != $len) {
    croak 'ListModelConcat: new order array wrong length';
  }

  my @row;
  foreach my $newpos (0 .. $#neworder) {
    my $oldpos = $neworder[$newpos];
    if ($oldpos < 0 || $oldpos >= $len) {
      croak "ListModelConcat: invalid old position in order array: $oldpos";
    }
    if ($oldpos != $newpos) {
      my ($model, $subiter) = _index_to_subiter ($self, $oldpos);
      $row[$oldpos] = [ _treemodel_extract_row ($model, $subiter) ];
    }
  }
  { local $self->{'suppress_signals'} = 1;
    foreach my $newpos (0 .. $#neworder) {
      my $oldpos = $neworder[$newpos];
      if ($oldpos != $newpos) {
        my ($model, $subiter) = _index_to_subiter ($self, $newpos);
        $model->set ($subiter, @{$row[$oldpos]});
      }
    }
  }
  $self->rows_reordered (Gtk2::TreePath->new, undef, @neworder);
}

sub swap {
  my ($self, $iterobj_a, $iterobj_b) = @_;
  my $index_a = _iterobj_to_index ($self, $iterobj_a);
  my $index_b = _iterobj_to_index ($self, $iterobj_b);

  my ($model_a, $subiter_a) = _index_to_subiter ($self, $index_a);
  my ($model_b, $subiter_b) = _index_to_subiter ($self, $index_b);
  if ($model_a == $model_b) {
    $model_a->swap ($subiter_a, $subiter_b);

  } else {
    my @row_a = _treemodel_extract_row ($model_a, $subiter_a);
    my @row_b = _treemodel_extract_row ($model_b, $subiter_b);
    { local $self->{'suppress_signals'} = 1;
      $model_a->set ($subiter_a, @row_b);
      $model_b->set ($subiter_b, @row_a); }

    my @array = (0 .. _total_length($self) - 1);
    $array[$index_a] = $index_b;   # $array[newpos] == oldpos
    $array[$index_b] = $index_a;
    $self->rows_reordered (Gtk2::TreePath->new, undef, @array);
  }
}

# return a list of values (0, 'col0', 1, 'col1', ...) which is the column
# number and its contents
sub _treemodel_extract_row {
  my ($model, $iter) = @_;
  my @row = $model->get($iter);
  return map {; ($_,$row[$_]) } 0 .. $#row;
}

#------------------------------------------------------------------------------
# Gtk2::TreeDragSource interface, drag source 

# gtk_tree_drag_source_row_draggable ($self, $path)
#
sub ROW_DRAGGABLE {
  # my ($self, $path) = @_;
  unshift @_, 'row_draggable';
  goto &_drag_source;
}

# gtk_tree_drag_source_drag_data_delete ($self, $path)
#
sub DRAG_DATA_DELETE {
  # my ($self, $path) = @_;
  unshift @_, 'drag_data_delete';
  goto &_drag_source;
}

# gtk_tree_drag_source_drag_data_get ($self, $path, $sel)
#
sub DRAG_DATA_GET {
  # my ($self, $path, $sel) = @_;
  unshift @_, 'drag_data_get';
  goto &_drag_source;
}

sub _drag_source {
  my ($method, $self, $path, @sel_arg) = @_;
  ### ListModelConcat: "\U$method\E path=".$path->to_string

  if ($path->get_depth != 1) {
    ### no, not a toplevel row
    return 0;
  }
  my ($index) = $path->get_indices;
  my ($model, $subindex) = _index_to_subindex ($self, $index);

  if (! $model->isa('Gtk2::TreeDragSource')) {
    ### no, submodel not a TreeDragSource
    return 0;
  }
  my $subpath = Gtk2::TreePath->new_from_indices ($subindex);
  ### submodel row_draggable subpath: $subpath->to_string
  my $ret = $model->$method ($subpath, @sel_arg);
  ### submodel result: $ret
  return $ret;
}

#------------------------------------------------------------------------------
# Gtk2::TreeDragDest interface, drag destination

# gtk_tree_drag_dest_row_drop_possible
# gtk_tree_drag_dest_drag_data_received
#
sub ROW_DROP_POSSIBLE {
  push @_, 'row_drop_possible';
  goto &_drag_dest;
}
sub DRAG_DATA_RECEIVED {
  push @_, 'drag_data_received';
  goto &_drag_dest;
}
sub _drag_dest {
  my ($self, $dst_path, $sel, $method) = @_;
  ### ListModelConcat: "\U$method\E, to path=".$dst_path->to_string
  ### type: $sel->type->name
  ### sel row: $sel->type->name eq 'GTK_TREE_MODEL_ROW' && do { my ($src_model, $src_path) = $sel->get_row_drag_data; "  src_model=$src_model src_path=".$src_path->to_string }

  if ($dst_path->get_depth != 1) {
    ### no, not a toplevel row
    return 0;
  }
  my ($dst_index) = $dst_path->get_indices;
  my ($dst_submodel, $dst_subindex)
    = _index_to_subindex_post ($self, $dst_index);

  if (! $dst_submodel->isa('Gtk2::TreeDragDest')) {
    ### no, submodel not a TreeDragDest
    return 0;
  }
  my $dst_subpath = Gtk2::TreePath->new_from_indices ($dst_subindex);
  if (! $dst_submodel->$method ($dst_subpath, $sel)) {
    ### no, submodel $method() false
    return 0;
  }
  ### yes from submodel
  return 1;
}

# return ($model, $subindex), and allowing a $index which is past the end of
# $self to likewise give a subindex beyond the end of the last submodel
#
sub _index_to_subindex_post {
  my ($self, $index) = @_;
  my $positions = _model_positions ($self);
  if ($index < $positions->[-1]) {
    return _index_to_subindex ($self, $index);
  }
  my $model = $self->{'models'}->[-1]
    or return (undef, undef);  # no models at all
  return ($model, $index - $positions->[-2]);
}

#------------------------------------------------------------------------------
# Gtk2::Buildable interface

sub ADD_CHILD {
  my ($self, $builder, $child, $type) = @_;
  ### ListModelConcat ADD_CHILD(): @_
  $self->append_model ($child);
}

1;
__END__

=for stopwords TreeModels Concat eg ListStores ListModelConcat Gtk2-Ex-ListModelConcat TreeDragSource TreeDragDest submodels submodel ie Arrayref Eg ListStore Iter iters versa TreeModelFilter iter arrayref func TreeModel TreeModelFilters Ryde Gtk2-Perl

=head1 NAME

Gtk2::Ex::ListModelConcat -- concatenated list models

=for test_synopsis my ($m1, $m2);

=head1 SYNOPSIS

 use Gtk2::Ex::ListModelConcat;
 my $model = Gtk2::Ex::ListModelConcat->new (models => [$m1,$m2]);

=head1 OBJECT HIERARCHY

C<Gtk2::Ex::ListModelConcat> is a subclass of C<Glib::Object>.

    Glib::Object
      Gtk2::Ex::ListModelConcat

and implements the interfaces

    Gtk2::TreeModel
    Gtk2::TreeDragSource
    Gtk2::TreeDragDest

=head1 DESCRIPTION

C<Gtk2::Ex::ListModelConcat> presents list type TreeModels concatenated
together as a single long list.  A Concat doesn't hold any data itself, it
just presents the sub-models' content.  C<Gtk2::ListStore> objects are
suitable as the sub-models but any similar list-type model can be used.

                    +--------+
            / row 0 | apple  | row 0 \
           /        +--------+        \
           |  row 1 | orange | row 1  | first child
           |        +--------+        /
           |  row 2 | lemon  | row 2 /
           |        +--------+
    Concat |  row 3 | potato | row 0 \
           |        +--------+        \
           |  row 4 | carrot | row 1  |
           |        +--------+        | second child
           |  row 5 | squash | row 2  |
           \        +--------+        /
            \ row 6 | onion  | row 3 /
                    +--------+


Changes in the sub-models are reported up through the Concat with the usual
C<row-changed> etc signals.  Conversely change methods are implemented by
the Concat in the style of C<Gtk2::ListStore> and if the sub-models have
those functions too (eg. if they're ListStores) then changes on the Concat
are applied down to the sub-models.

The sub-models should have the same number of columns and the same column
types (or compatible types), though currently ListModelConcat doesn't try to
enforce that.  One Concat can be inside another, but a Concat must not be
inside itself (directly or indirectly).

=head1 DRAG AND DROP

ListModelConcat implements C<Gtk2::TreeDragSource> and C<Gtk2::TreeDragDest>
interfaces, allowing rows to be moved by dragging in C<Gtk2::TreeView> or
similar.  The actual operations are delegated to the submodels, so a row can
be dragged if the originating submodel is a TreeDragSource and a location is
a drop if its submodel is a TreeDragDest.

The standard C<Gtk2::ListStore> models only accept drops of their own rows,
ie. a re-ordering, not movement of rows between different models.  This is
reasonable since different models might have different natures, but you
might want to subclass C<ListStore> or use a wrapper for a more liberal
policy among compatible models.

See F<examples/demo.pl> in the ListModelConcat sources for a complete sample
program with drag and drop by usual C<Gtk2::TreeView>.

=head1 PROPERTIES

=over 4

=item C<models> (array reference, default empty C<[]>)

Arrayref of sub-models to present.  The sub-models can be any object
implementing the C<Gtk2::TreeModel> interface.  They should be C<list-only>
type, but currently ListModelConcat doesn't enforce that.

Currently when the C<models> property is changed there's no C<row-inserted>
/ C<row-deleted> etc signals emitted by the Concat to announce the new or
altered data presented.  Perhaps this will change.  The disadvantage would
be that adding or removing a big model could generate thousands of fairly
pointless signals.  The suggestion is to treat C<models> as if it were
"construct-only" and make a new Concat for a new set of models.

=item C<append-model> (C<Gtk2::TreeModel>, write-only)

A write-only pseudo-property which appends a model to the Concat, per the
C<append_model> method below.  This can be used to add models from a
C<Gtk2::Builder> (see L</BUILDABLE> below).

=back

=head1 FUNCTIONS

=head2 Creation

=over 4

=item C<< $concat = Gtk2::Ex::ListModelConcat->new (key=>value,...) >>

Create and return a new Concat object.  Optional key/value pairs set initial
properties per C<< Glib::Object->new >>.  Eg.

 my $concat = Gtk2::Ex::ListModelConcat->new (models => [$m1,$m2]);

=item C<< $concat->append_model ($model, ...) >>

Append each given C<$model> to those already in C<$concat>.  See
L</PROPERTIES> above for an equivalent C<append-model> property and notes on
signal emission.

=back

=head2 ListStore Methods

The following functions follow the style of C<Gtk2::ListStore> and they call
down to corresponding functions in the sub-models.  Those sub-models don't
have to be C<Gtk2::ListStore> objects, they can be some other class
implementing the same methods.

=over 4

=item C<< $concat->clear >>

=item C<< $concat->set_column_types >>

These are applied to all sub-models, so C<clear> clears all the models or
C<set_column_types> sets the types in all the models.

In the current implementation Concat doesn't keep track of column types
itself, but asks the sub-models when required (using the first sub-model,
currently).

=item C<< $iter = $concat->append >>

=item C<< $iter = $concat->insert ($pos) >>

=item C<< $iter = $concat->insert_with_values ($pos, $col,$val, ...) >>

=item C<< $iter = $concat->insert_after ($iter) >>

=item C<< $iter = $concat->insert_before ($iter) >>

=item C<< bool = $concat->iter_is_valid ($iter) >>

=item C<< $concat->move_after ($iter, $iter_from, $iter_to) >>

=item C<< $concat->move_before ($iter, $iter_from, $iter_to) >>

=item C<< $iter = $concat->prepend >>

=item C<< bool = $concat->remove ($iter) >>

=item C<< $concat->reorder (@neworder) >>

=item C<< $concat->swap ($iter_a, $iter_b) >>

=item C<< $concat->set ($iter, $col,$val, ...) >>

=item C<< $concat->set_value ($iter, $col, $val) >>

These are per the C<Gtk2::ListStore> methods.

Note C<set> overrides the C<set> from C<Glib::Object> which normally sets
object properties.  You can use its C<set_property> name instead.

    $model->set_property ('propname' => $value);

As of Gtk2-Perl 1.200 C<set_value> in C<Gtk2::ListStore> is actually an
alias for C<set> and so accepts multiple C<$col,$val> pairs.
ListModelConcat passes all C<set_value> arguments through to the sub-model
C<set_value> (after converting the C<$iter>), so it's up to it what should
work.

=back

=head2 Iter Conversions

The following functions convert Concat iters to iters on the child model, or
vice versa.  They're similar to what TreeModelFilter offers (see
L<Gtk2::TreeModelFilter>), except that a particular child model is returned
and must be specified since a Concat can have multiple children.

=over 4

=item C<< ($childmodel, $childiter, $childnum) = $concat->convert_iter_to_child_iter ($iter) >>

Convert a ListModelConcat iter to an iter on the child model corresponding
to that row.

The return includes the C<$childnum> which is an index into the C<models>
property arrayref.  If a child model appears more than once in the models
then this identifies which occurrence the C<$iter> refers to.  Often this is
of no interest and can be ignored.

    my ($childmodel, $childiter)
      = $concat->convert_iter_to_child_iter ($iter);
    $childmodel->something($childiter) ...

=item C<< $iter = $concat->convert_child_iter_to_iter ($childmodel, $childiter) >>

=item C<< $iter = $concat->convert_childnum_iter_to_iter ($childnum, $childiter) >>

Convert an iter on one of the child models to an iter on the
ListModelConcat.

The C<childnum> func takes an index into the C<models> list, counting from 0
for the first model.  If you've got a child model appearing more than once
then this lets you identify which one you mean.  The plain C<$childmodel>
func gives the first occurrence of that model.

=back

=head1 SIGNALS

The TreeModel interface implemented by ListModelConcat provides the
following usual signals

    row-changed    ($concat, $path, $iter, $userdata)
    row-inserted   ($concat, $path, $iter, $userdata)
    row-deleted    ($concat, $path, $userdata)
    rows-reordered ($concat, $path, $iter, $arrayref, $userdata)

Because ListModelConcat is C<list-only>, the path to C<row-changed>,
C<row-inserted> and C<row-deleted> is always depth 1, and the path to
C<rows-reordered> is always depth 0 and the iter there always C<undef>.

When a change occurs in a sub-model the corresponding signal is reported up
through Concat.  The path and iter are of course reported up in the
"concatenated" coordinates and iters, not the sub-model's.

=head1 BUILDABLE

ListModelConcat implements the C<Gtk2::Buildable> interface of Gtk 2.12 and
up, allowing C<Gtk2::Builder> to construct a Concat with child sub-model
objects.  Sub-models can be added either through the C<append-model>
pseudo-property for separately created model objects,

    <object class="Gtk2__Ex__ListModelConcat" id="mylmc">
      <property name="append-model">mysubmodel-one</property>
      <property name="append-model">mysubmodel-two</property>
    </object>

Or with C<< <child> >> elements constructing sub-model objects at that
point,

    <object class="Gtk2__Ex__ListModelConcat" id="mylmc">
      <child>
        <object class="GtkListStore" id="list1">
          <columns><column type="gint"/></columns>
          <data><row><col id="0">123</col></row></data>
        </object>
      </child>
    </object>

The two styles are just a matter of whether you prefer to create the
sub-models at the top-level and add to a Concat by name, or make them in the
concat and refer to them elsewhere by name.

It's not a good idea to mix C<< <child> >> and C<append-model> since the
order among the different settings may not be preserved.  As of Gtk 2.20 the
builder works by adding all C<< <child> >> objects and then setting
properties a bit later, or something like that, so C<< <child> >> objects
end up before C<append-model> even if written the other way around.

See F<examples/builder-append.pl> and F<examples/builder-children.pl> in the
ListModelConcat sources for complete sample programs.

=head1 BUGS

C<ref_node> and C<unref_node> are no-ops.  The intention would be to apply
them down on the sub-models, but hopefully without needing lots of
bookkeeping in the Concat as to what's currently reffed.

It mostly works to have a sub-model appear more than once in a Concat.  The
only real problem is with the C<row-deleted> and C<row-inserted> signals.
They're emitted on the Concat the right number of times, but the multiple
inserts/deletes are all present in the data as of the first emit, which
could confuse handler code.  Perhaps some sort of temporary index mapping
could make the changes seem one-at-a-time, except the deleted row contents
have already gone.

What does work fine though is to have multiple TreeModelFilters (or similar)
selecting different parts of a single underlying model.  As long as a given
row only appears once it doesn't matter where its ultimate storage is.

=head1 SEE ALSO

L<Gtk2::TreeModel>, L<Gtk2::TreeDragSource>, L<Gtk2::TreeDragDest>,
L<Gtk2::ListStore>, L<Glib::Object>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-listmodelconcat/>

=head1 COPYRIGHT

Copyright 2008, 2009, 2010, 2015, 2016 Kevin Ryde

Gtk2-Ex-ListModelConcat is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Gtk2-Ex-ListModelConcat is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-ListModelConcat.  If not, see L<http://www.gnu.org/licenses/>.

=cut
