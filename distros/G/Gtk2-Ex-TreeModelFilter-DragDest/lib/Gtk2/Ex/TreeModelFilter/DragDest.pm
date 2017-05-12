# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TreeModelFilter-DragDest.
#
# Gtk2-Ex-TreeModelFilter-DragDest is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3, or (at your
# option) any later version.
#
# Gtk2-Ex-TreeModelFilter-DragDest is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TreeModelFilter-DragDest.  If not, see
# <http://www.gnu.org/licenses/>.


package Gtk2::Ex::TreeModelFilter::DragDest;
use 5.008;
use strict;
use warnings;
use Carp;

our $VERSION = 3;

use constant DEBUG => 0;


# gtk_tree_drag_dest_row_drop_possible
# gtk_tree_drag_dest_drag_data_received
#
# The two funcs are delegated to the child model the same way, just the
# method used when found differs.
#
sub ROW_DROP_POSSIBLE {
  push @_, 'row_drop_possible';
  goto &_drop;
}
sub DRAG_DATA_RECEIVED {
  push @_, 'drag_data_received';
  goto &_drop;
}
sub _drop {
  my ($self, $path, $sel, $method) = @_;

  if (DEBUG) { print "Filter::DragDest ",uc($method)," to path=",
                 $path->to_string," type=",$sel->type->name,"\n";
               if ($sel->type->name eq 'GTK_TREE_MODEL_ROW') {
                 my ($src_model, $src_path) = $sel->get_row_drag_data;
                 print "  src_model=$src_model src_path=",
                   $src_path->to_string,", has DragDest=",
                     $src_model->isa('Gtk2::TreeDragDest')?"yes":"no", "\n";
               }}

  # See if there's a TreeDragDest capable child.  Do this before building a
  # child path, since path conversions can be expensive.
  #
  my $submodel = $self;
  for (;;) {
    $submodel = $submodel->get_model || do {
      if (DEBUG) { print "  no TreeDragDest child\n"; }
      return;
    };
    if ($submodel->isa('Gtk2::TreeDragDest')) {
      last;
    }
    if (! $submodel->isa('Gtk2::TreeModelFilter')) {
      if (DEBUG) { print "  not a sub-filter\n"; }
      return;
    }
  }

  # Same again, building $subpath.
  #
  $submodel = $self;
  my $subpath = $path;
  for (;;) {
    $subpath = _path_to_child_path_or_end ($submodel, $subpath)
      || do { if (DEBUG) { print "  no subpath\n"; }
              return 0;
            };
    $submodel = $submodel->get_model
      or return;  # oops, wasn't this ok in the loop above!

    if ($submodel->isa('Gtk2::TreeDragDest')) {
      last;
    }
    if (! $submodel->isa('Gtk2::TreeModelFilter')) {
      return;  # oops, wasn't this ok in the loop above!
    }
  }

  if (DEBUG) { print "  drop on $submodel, path=",$subpath->to_string,"\n"; }
  my $ret = $submodel->$method ($subpath, $sel);
  if (DEBUG) { print "    ", $ret?"yes":"no","\n"; }
  return $ret;
}

sub _path_to_child_path_or_end {
  my ($self, $path) = @_;
  my $subpath = $self->convert_path_to_child_path ($path);
  if (! $subpath) {
    $path = $path->copy;
    if ($path->up) {
      $subpath = $self->convert_path_to_child_path ($path);
      if ($subpath) {
        my $model = $self->get_model;
        my $subiter = ($subpath->get_depth == 0 ? undef
                       : $model->get_iter ($subpath));
        my $n = $model->iter_n_children ($subiter);
        if (DEBUG) { print "  follow to end of subpath=",
                       $subpath->to_string||'none'," n=$n\n"; }
        $subpath->append_index ($n);
      }
    }
  }
  return $subpath;
}

1;
__END__

=for stopwords TreeModelFilter draggability TreeDragDest Gtk Ryde DragDest

=head1 NAME

Gtk2::Ex::TreeModelFilter::DragDest -- drag destination mix-in for TreeModelFilter subclasses

=head1 SYNOPSIS

 package MyNewFilterModel;
 use Gtk2;
 use base 'Gtk2::Ex::TreeModelFilter::DragDest';

 use Glib::Object::Subclass
   Gtk2::TreeModelFilter::,
   interfaces => [ 'Gtk2::TreeDragDest' ];

=head1 DESCRIPTION

C<Gtk2::Ex::TreeModelFilter::DragDest> provides the following two functions
to implement the C<Gtk2::TreeDragDest> interface in a sub-class of
C<Gtk2::TreeModelFilter>.

    ROW_DROP_POSSIBLE
    DRAG_DATA_RECEIVED

They're designed as a multiple-inheritance mix-in, so you put
C<Gtk2::Ex::TreeModelFilter::DragDest> in your C<@ISA>, then add
C<Gtk2::TreeDragDest> to the C<interfaces> in your C<use
Glib::Object::Subclass> (or C<register_object>).

For simple filter draggability you'll probably find
C<Gtk2::Ex::TreeModelFilter::Draggable> enough, but C<DragDest> lets you add
draggability to sub-sub-classes of TreeModelFilter.

=head2 Drop

The drop strategy is simply to delegate to the filter's C<child-model>.  If
it's not a TreeDragDest, but is another C<Gtk2::TreeModelFilter>, then its
C<child-model> is tried, and so downwards to the first TreeDragDest capable
child.  The destination path position is converted as necessary.

If the drag source is the filter itself (which is usual for say dragging in
a C<Gtk2::TreeView>) then the source row ends up being from the first
non-filter child model.  The above drop strategy ends up on that same child,
which is important for instance for a C<Gtk2::ListStore> since it only
allows drags within itself.

=head1 OTHER NOTES

There's probably no reason C<GtkTreeModelFilter> itself couldn't do this
sort of drop, but as of Gtk 2.12 it doesn't.  Perhaps by the time you read
this it will, and you won't need this code.

If your filter's "visible" function decides a newly dropped row shouldn't
appear then the drop still works, but it'll look to the user like the source
just disappeared.  That might be confusing; or if the destination is some
designated "hidden track" then it be what you want.

=head1 SEE ALSO

L<Gtk2::TreeModelFilter>, L<Gtk2::TreeModel>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-treemodelfilter-dragdest/>

=head1 COPYRIGHT

Copyright 2008, 2009, 2010 Kevin Ryde

Gtk2-Ex-TreeModelFilter-DragDest is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 3, or (at your
option) any later version.

Gtk2-Ex-TreeModelFilter-DragDest is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-TreeModelFilter-DragDest.  If not, see
L<http://www.gnu.org/licenses/>.

=cut
