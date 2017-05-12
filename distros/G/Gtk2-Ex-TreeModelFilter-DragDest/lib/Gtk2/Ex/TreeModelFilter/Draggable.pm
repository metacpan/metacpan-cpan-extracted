# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TreeModelFilter-DragDest.
#
# Gtk2-Ex-TreeModelFilter-DragDest is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3, or (at your
# option) any later version.
#
# Gtk2-Ex-TreeModelFilter-DragDest is distributed in the hope that it will
# be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TreeModelFilter-DragDest.  If not, see
# <http://www.gnu.org/licenses/>.


package Gtk2::Ex::TreeModelFilter::Draggable;
use 5.008;
use strict;
use warnings;
use Gtk2;
use Carp;

our $VERSION = 3;
our @ISA;

BEGIN {
  # The only extra thing "use Glib::Object::Subclass" does is unshift itself
  # onto @ISA to give precedence a Glib::Object::new() over the specific
  # superclass new(), but that's not needed since have new() below.
  #
  my @args;
  if (! Gtk2::TreeModelFilter->can('Gtk2::TreeDragDest')) {
    require Gtk2::Ex::TreeModelFilter::DragDest;
    push @ISA, 'Gtk2::Ex::TreeModelFilter::DragDest';
    @args = (interfaces => [ 'Gtk2::TreeDragDest' ]);
  }
  Glib::Type->register_object ('Gtk2::TreeModelFilter', __PACKAGE__, @args);

}

sub new {
  my ($class, $child_model, $virtual_root) = @_;
  (@_ >= 2 && @_ <= 3)
    or croak "Usage: $class->new(\$child_model [, \$virtual_root])";

  return $class->Glib::Object::new (child_model  => $child_model,
                                    virtual_root => $virtual_root);
}

1;
__END__

=for stopwords draggable TreeModelFilter DragDest subtree unfiddle Gtk TreeDragSource TreeDragDest Ryde

=head1 NAME

Gtk2::Ex::TreeModelFilter::Draggable -- draggable subclass of TreeModelFilter

=for test_synopsis my ($child_model)

=head1 SYNOPSIS

 use Gtk2::Ex::TreeModelFilter::Draggable;
 my $filter = Gtk2::Ex::TreeModelFilter::Draggable->new ($child_model);

=head1 OBJECT HIERARCHY

C<Gtk2::Ex::TreeModelFilter::Draggable> is a subclass of
C<Gtk2::TreeModelFilter>

    Glib::Object
      Gtk2::TreeModelFilter
        Gtk2::Ex::TreeModelFilter::Draggable

and adds the interface

    Gtk2::TreeDragDest

=head1 DESCRIPTION

C<Gtk2::Ex::TreeModelFilter::Draggable> subclasses C<Gtk2::TreeModelFilter>
to add a C<Gtk2::TreeDragDest> interface, making rows draggable when
displayed for instance in a C<Gtk2::TreeView>.  Everything else in
TreeModelFilter is unchanged.  Basically to get a draggable filtered model
use

    Gtk2::Ex::TreeModelFilter::Draggable->new

wherever you would have had C<< Gtk2::TreeModelFilter->new >>.  See
L<Gtk2::Ex::TreeModelFilter::DragDest> for the drop details, and for getting
DragDest on some other subclass or sub-sub-class of TreeModelFilter.

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::TreeModelFilter::Draggable->new ($child_model) >>

=item C<< Gtk2::Ex::TreeModelFilter::Draggable->new ($child_model, $virtual_root) >>

Create and return a new TreeModelFilter::Draggable.  The parameters are like
the core C<< Gtk2::TreeModelFilter->new >>.  C<$child_model> is the
underlying model to present (any object implementing C<Gtk2:TreeModel>), and
the optional C<$virtual_root> is a C<Gtk2::TreePath> which is a subtree of
C<$child_model> to present.

=back

If you subclass further from TreeModelFilter::Draggable using
C<Glib::Object::Subclass> then note that module will fiddle with your
C<@ISA> to have C<Glib::Object::new()> ahead of the C<new> above.  Often
this is a good thing if you've got additional properties in your subclass
you want to set from C<new>; but you can unfiddle or elevate
TreeModelFilter::Draggable if you want the C<new> above (it knows to use the
C<$class> argument when run from a subclass, unlike the various C code
class-specific C<new> functions).

=head1 OTHER NOTES

As of Gtk 2.12 the core C<Gtk2::TreeModelFilter> is a TreeDragSource, but
not a TreeDragDest.  Perhaps by the time you read this that will have
changed.  TreeModelFilter::Draggable is setup to watch out for that and omit
its own DragDest, on the assumption the core will be equal or better.  You
can decide whether this is prudently forward-looking, or naively optimistic.

=head1 SEE ALSO

L<Gtk2::TreeModelFilter>, L<Gtk2::Ex::TreeModelFilter::DragDest>,
L<Gtk2::TreeModel>

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
