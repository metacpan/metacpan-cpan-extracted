#!/usr/bin/perl -w

# Copyright 2010, 2015 Kevin Ryde

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


sub reorder_by_copy {
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

}



  # If there's cycles wholly within a single sub-model then they can be
  # applied with the submodel's reorder method, if it's got one.  The
  # advantage would be that small swaps or shuffles can be delegated,
  # instead of a lot of data copying.
  #
  # The order swaps are applied matters if a model appears twice.
  #
  #   my @seen;
  #     my $models = $self->{'models'};
  #   my $positions = _model_positions ($self);
  #   foreach my $mnum (0 .. $#$models) {
  #     my $model = $models->[$mnum];
  #     my $reorder = $model->can('reorder') or next;
  #     my $lo = $positions->[$mnum];
  #     my $hi = $positions->[$mnum+1] - 1;
  #     my @subarray = (0 .. $hi-$lo);
  #     my $diff = 0;
  #     foreach my $index ($lo .. $hi) {
  #
  #     }
  #     $diff or next;
  #     { local $self->{'suppress_signals'} = 1;
  #       $reorder->(@subarray);
  #     }
  #   }
