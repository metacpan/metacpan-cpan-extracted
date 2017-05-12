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


package Gtk2::Ex::TreeModelFilter::Change;
use 5.008;
use strict;
use warnings;
use Gtk2 1.200; # for $iter->set()
use Carp;

our $VERSION = 48;

# uncomment this to run the ### lines
#use Smart::Comments;

# append empty row, return new iter
# prepend empty row, return new iter
#
sub append {
  my ($self) = @_;
  return $self->convert_child_iter_to_iter ($self->get_model->append);
}
sub prepend {
  my ($self) = @_;
  return $self->convert_child_iter_to_iter ($self->get_model->prepend);
}

sub clear {
  $_[0]->get_model->clear;
}

# gtk_list_store_insert
# gtk_tree_store_insert
#
# insert before $index, or append if $index past last existing row
#
# gtk_list_store_insert_with_values ($treestore, $pos, ...)
# gtk_tree_store_insert_with_values ($treestore, $parent_iter, $pos, ...)
#
# insert before $index, or append if $index past last existing row, and
# taking col=>value pairs
#
sub insert {
  my $self = shift;
  return $self->convert_child_iter_to_iter
    ($self->get_model->insert (@_));
}
sub insert_with_values {
  my $self = shift;
  return $self->convert_child_iter_to_iter
    ($self->get_model->insert_with_values (@_));
}

# gtk_list_store_insert_after ($liststore, $iter)
# gtk_tree_store_insert_after ($treestore, $parent_iter, $iter)
#
# insert empty row after $iter, return new iter
# insert at beginning of $parent_iter if $iter undef (yes, the beginning)
#
# gtk_list_store_insert_before ($liststore, $iter)
# gtk_tree_store_insert_before ($treestore, $parent_iter, $iter)
#
# insert empty row before $iter, return new iter
# insert at end of $parent_iter if undef (yes, the end)
#
sub insert_after {
  my $self = shift;
  foreach (@_) { $_ = $self->convert_iter_to_child_iter ($_); }
  return $self->convert_child_iter_to_iter
    ($self->get_model->insert_after (@_));
}
sub insert_before {
  my $self = shift;
  foreach (@_) { $_ = $self->convert_iter_to_child_iter ($_); }
  return $self->convert_child_iter_to_iter
    ($self->get_model->insert_before (@_));
}

# gtk_list_store_move_after
# gtk_tree_store_move_after
#
# $dst_iter undef means the start (yes, the start) of the list
#
# gtk_list_store_move_before
# gtk_tree_store_move_before
#
# $dst_iter undef means the end (yes, the end) of the list
#
sub move_after {
  my ($self, $src_iter, $dst_iter) = @_;
  $self->get_model->move_after
    ($self->convert_iter_to_child_iter ($src_iter),
     $dst_iter && $self->convert_iter_to_child_iter ($dst_iter));
}
sub move_before {
  my ($self, $src_iter, $dst_iter) = @_;
  $self->get_model->move_before
    ($self->convert_iter_to_child_iter ($src_iter),
     $dst_iter && $self->convert_iter_to_child_iter ($dst_iter));
}

# gtk_list_store_remove ($iter)
# gtk_tree_store_remove ($iter)
#
sub remove {
  my ($self, $iter) = @_;
  ### TreeModelFilter-Change remove()

  my $subiter = $self->convert_iter_to_child_iter ($iter);

  my $model = $self->get_model;
  if ($model->remove ($subiter)) {
    ### child remove() true
    ### subiter path: $model->get_path($subiter)->to_string
    # if the updated $subiter is filtered out then search forwards for the
    # next unfiltered
    do {
      if (my $new_iter = $self->convert_child_iter_to_iter ($subiter)) {
        $iter->set ($new_iter);
        return 1;
      }
    } while ($subiter = $model->iter_next ($subiter));
  }

  ### TreeModelFilter-Change remove() no further rows
  # no more rows in this node after the removed one, or no more which pass
  # the filter at least
  $iter->set ([0,0,undef,undef]);  # invalidate, new in Gtk 1.200
  return 0;
}

# gtk_list_store_reorder (store, order)
# gtk_tree_store_reorder (store, iter, order)
#
sub reorder {
  my $self = shift;

  my $path;
  my @subiter;
  if (ref $_[0]) {
    # tree model style, with iter arg
    my $iter = shift;
    @subiter = ( $self->convert_iter_to_child_iter($iter) );
    $path = $self->get_path ($iter);  # empty path if toplevel
  } else {
    $path = Gtk2::TreePath->new;
  }

  my $model = $self->get_model;
  my @suborder = (0 .. $model->iter_n_children($subiter[0]) - 1);

  # There's no checking here that each $subpath is within the same $subiter
  # node we're supposed to be operating on.  A TreeModelFilter doesn't
  # collapse down or spray out structure, so it should be ok.
  #
  foreach my $newpos (@_) {
    # convert $newpos to position within child
    $path->append_index ($newpos);
    my $subpath = $self->convert_path_to_child_path ($path);
    my $sub_newpos = ($subpath->get_indices)[-1]; # last index
    $path->up;

    # convert $oldpos to position within child
    my $oldpos = $_[$newpos];
    $path->append_index ($oldpos);
    $subpath = $self->convert_path_to_child_path ($path);
    my $sub_oldpos = ($subpath->get_indices)[-1]; # last index
    $path->up;

    $suborder[$sub_newpos] = $sub_oldpos;
  }

  $model->reorder (@subiter, @suborder);
}

sub swap {
  my ($self, $iter_a, $iter_b) = @_;
  my $subiter_a = $self->convert_iter_to_child_iter ($iter_a);
  my $subiter_b = $self->convert_iter_to_child_iter ($iter_b);
  $self->get_model->swap ($subiter_a, $subiter_b);
}

sub set {
  my $self = shift;
  my $iter = shift;
  $self->get_model->set ($self->convert_iter_to_child_iter($iter), @_);
}
sub set_value {
  my $self = shift;
  my $iter = shift;
  $self->get_model->set_value ($self->convert_iter_to_child_iter($iter), @_);
}

1;
__END__

=for stopwords TreeModelFilter multi-inheritance iter ListStore TreeStore arg ie Ryde Gtk2-Ex-WidgetBits Gtk

=head1 NAME

Gtk2::Ex::TreeModelFilter::Change -- change-rows mix-in for TreeModelFilter subclasses

=head1 SYNOPSIS

 package MyNewFilterModel;
 use Gtk2;
 use base 'Gtk2::Ex::TreeModelFilter::Change';

 use Glib::Object::Subclass
   'Gtk2::TreeModelFilter',
   properties => [   ];


=head1 DESCRIPTION

C<Gtk2::Ex::TreeModelFilter::Change> is designed as a multi-inheritance
mix-in for Perl sub-classes of C<Gtk2::TreeModelFilter>.  It provides the
following methods

    append
    clear
    insert
    insert_with_values
    insert_after
    insert_before
    move_after
    move_before
    prepend
    remove
    reorder
    swap
    set
    set_value

They work like the corresponding C<Gtk2::ListStore> and C<Gtk2::TreeStore>
methods and make changes by calling to the corresponding methods on the
filter's C<child-model>.

The child model doesn't have to be a C<Gtk2::ListStore> or
C<Gtk2::TreeStore>, it can be anything which implements the same methods.

=head1 NOTES

=over 4

=item Empty row -- C<append>, C<prepend>, C<insert>, C<insert_before>, C<insert_after>

These functions all insert an empty new row.  If your filter is setup to
exclude empty rows then the new row is created in the child, but then
doesn't appear in the filtered view!  You probably don't want to do that.

Currently the functions return C<undef> instead of an iter if the new row is
not visible.  C<insert_with_values()> can be used to do a combination insert
and set to avoid an empty row.

=item Gtk 2.6 -- C<insert_with_values>

C<insert_with_values()> on ListStore and TreeStore is new in Gtk 2.6.  The
mix-in method is always provided by TreeModelFilter::Change and always calls
to the child model but you might have to check what the child model has if
you're using an oldish Gtk.

=item Parent node arg -- C<insert_after>, C<insert_before>, C<insert_with_values>

These functions take either just a position number like ListStore, or a
parent node iter plus a position like TreeStore,

    $filter->insert_after ($pos)                # ListStore
    $filter->insert_after ($parent_iter, $pos)  # TreeStore

The same one or two arguments are then passed through to the child model.

=item Data access -- C<get>, C<set>

C<get()> and C<set()> fetch and store row data.  Make sure
C<Gtk2::Ex::TreeModelFilter::Change> is before C<Glib::Object> in your
C<@ISA> to have these versions instead of the object property C<get()> and
C<set()>.  A C<use base> before C<Glib::Object::Subclass> as shown in the
synopsis above will accomplish that,

    use base 'Gtk2::Ex::TreeModelFilter::Change';
    use Glib::Object::Subclass 'Gtk2::TreeModelFilter';

The object properties are always available under the names C<get_property()>
and C<set_property()>, the same as in C<Gtk2::ListStore> and
C<Gtk2::TreeStore>.

    $myfilter->set_property (propname => $propvalue);

=item Filtered out rows -- C<set>, C<set_value>

If a C<set()> or C<set_value()> of new data causes the child row to be
filtered out, ie. to not appear in C<$filter>, then the given C<$iter> no
longer refers to a valid row in the filtered model and cannot be used any
more.

Currently the iter is not zapped to zeros, perhaps in the future it will be
(it's extra work to check if still available, but would help keep you safe).

=item Data transforms -- C<set>, C<set_value>, C<insert_with_values>

No transformations are applied to stored data, so if you're using a "modify"
function to present different types or contents there's no way to
reverse-modify.  Hopefully this will be possible in the future.

Any columns which are unchanged by a modify function can be stored, and in
particular you can use a modify function just to add extra columns intended
to be read-only.

=back

=head1 SEE ALSO

L<Gtk2::TreeModelFilter>, L<Gtk2::TreeModel>

L<Gtk2::Ex::TreeModelFilter::DragDest> and
L<Gtk2::Ex::TreeModelFilter::Draggable>, which propagate drag-and-drop drops
to the child model

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-WidgetBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
