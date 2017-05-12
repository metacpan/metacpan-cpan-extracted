# new enough Gtk2 1.240 for list_properties


# Copyright 2009, 2010 Kevin Ryde

# This file is part of Glib-Ex-TiedListColumn.
#
# Glib-Ex-TiedListColumn is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Glib-Ex-TiedListColumn is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-TiedListColumn.  If not, see <http://www.gnu.org/licenses/>.


package Gtk2::Ex::TiedChildProperties;
use 5.008;
use strict;
use warnings;
use Carp;

our $VERSION = 9;

use constant DEBUG => 0;

sub new {
  tie my(%hash), shift, @_;
  return \%hash;
}
sub child {
  return $_[0]->[0];
}

# $self is an arrayref, created as one element just for _CHILD, with a second
# for _KEYS on-demand..
#
# $self->[_CHILD] is the target Gtk2::Container
#
# $self->[_KEYS] is an arrayref of keys (string property names) to return
# from FIRSTKEY/NEXTKEY, with NEXTKEY shifting off one per call.
#
use constant { _CHILD => 0,
               _KEYS => 1 };

# Think about:
#   error_on_fetch
#   error_on_store
#
sub TIEHASH {
  my ($class, $obj, %option) = @_;
  (ref $obj) || croak "$class needs a child widget to tie";
  my $self = bless [ $obj ], $class;
  if ($option{'weak'}) {
    require Scalar::Util;
    Scalar::Util::weaken ($self->[_CHILD]);
  }
  return $self;
}
sub FETCH  {
  my ($self, $key) = @_;
  if (my $child = $self->[_CHILD]) {    # when not weakened away
    if (my $parent = $child->parent) {  # when have a parent
      # check property exists to avoid g_warning() from child_get_property()
      if (my $pspec = $parent->find_child_property ($key)) {
        if ($pspec->{'flags'} >= 'readable') {
          return $parent->child_get_property($child, $key);
        }
      }
    }
  }
  return undef;
}
sub STORE  {
  my ($self, $key, $value) = @_;
  if (my $obj = $self->[_CHILD]) {      # when not weakened away
    $obj->set_child_property ($key, $value);
  }
}
sub EXISTS {
  my ($self, $key) = @_;
  if (my $child = $self->[_CHILD]) {    # when not weakened away
    if (my $parent = $child->parent) {  # when have a parent
      return defined ($parent->find_child_property($key));
    }
  }
  return 0;
}
sub DELETE { croak 'Cannot delete container properties' }
BEGIN {
  no warnings;
  *CLEAR = \&DELETE;
}

# FIXME: what should happen if the child is reparented while iterating the
# keys with each()?  Don't really want to list_child_properties() on every
# NEXTKEY.
#
sub FIRSTKEY {
  my ($self) = @_;
  my $obj = $self->[_CHILD] || return undef;  # if weakened away
  @{$self->[_KEYS]} = map {$_->{'name'}} $obj->list_child_properties;
  goto &NEXTKEY;
}
sub NEXTKEY {
  return shift @{$_[0]->[_KEYS]};
}

# true if at least one property, this new in 5.8.3
sub SCALAR {
  my ($self) = @_;
  if (my $child = $self->[_CHILD]) {    # when not weakened away
    if (my $parent = $child->parent) {  # when have a parent
      my @pspecs = $parent->list_child_properties;
      my $len = scalar(@pspecs);
      return "$len/$len";
    }
  }
  return 0;
}

1;
__END__

=head1 NAME

Gtk2::Ex::TiedChildProperties -- tied hash for container child properties

=for test_synopsis my ($container)

=head1 SYNOPSIS

 use Gtk2::Ex::TiedChildProperties;
 my %hash;
 tie %hash, 'Gtk2::Ex::TiedChildProperties', $child;

 # or an anonymous hashref
 my $href = Gtk2::Ex::TiedChildProperties->new ($child);

=head1 DESCRIPTION

C<Gtk2::Ex::TiedChildProperties> sets up a Perl tied hash to access the
"child properties" of a widget.  Those properties are defined by a
C<Gtk2::Container> and exist on the widget when it's added into a particular
container parent.  The keys are the child property names and fetching and
storing values operates on the widget's values.

The Gtk reference manual describes child properties as belonging to the
"relation" between parent and child.  They're conceived here as existing on
the child, with their types etc defined by the parent.  The child properties
are separate from the plain object properties of either the parent or child
(see L<Glib::Ex::TieProperties> for them).

If you're just getting and setting properties then the C<child_get_property>
and C<child_set_property> methods are enough, but one good use for a tie is
to apply C<local> settings within a block, to be undone by a
C<set_child_property> back to their previous values no matter how the block
is left (C<goto>, C<return>, C<die>, etc).

    {
      my %props;
      tie %props, 'Gtk2::Ex::TiedChildProperties', $child;
      local $props{'padding'} = 10;
      look_at_parent_size();
    }

The C<new> method can create a tied anonymous hashref so that a single long
C<local> expression is possible

    # usually allow-shrink is not a good idea, have it temporarily
    local Gtk2::Ex::TiedChildProperties->new($child)->{'homogeneous'} = 0;
    some_thing();

You can even be creative with hash slices for multiple settings in one
statement.

    # how big is $toplevel if $widget width is forced
    {
      tie my(%props), 'Gtk2::Ex::TiedChildProperties', $child;
      local @props{'left-attach','right-attach'} = (1, 3);
      my $req = $table->size_request;
    }

Like most C<tie> things, TiedChildProperties is better in concept than
actuality.  There's relatively few container properties needing block-scoped
changes, and things like getting all property names or values must generally
pay attention to whether properties are read-only, write-only, etc, so a
naive property values iteration is rarely much good.

=head2 Details

The property names for the keys are anything accepted by
C<child_get_property>, C<find_child_property>, etc.  This means underscores
"_" can be used in place of dashes "-".  For example C<pack_type> is an
alias for C<pack-type>.

The C<keys> and C<each> operations return just the dashed names.  Currently
they return properties in the same order as
C<< $parent->list_child_properties >> gives, but don't depend on that.

Getting a non-existent property name returns C<undef>, the same as a
non-existent entry in an ordinary Perl hash.  C<exists> tests a key with
C<< $parent->find_child_property >>.

If a property exists but is not readable then fetching returns C<undef>.  An
error in that case would also be possible, but that would make it impossible
to use C<each> to iterate through an container with any write-only properties.
Storing to a non-existent property throws an error, a bit like a restricted
hash (see L<Hash::Util>).  Storing to a read-only property likewise throws
an error.

For Perl 5.8.3 and up C<scalar()> is arranged to give a count like "17/17"
when not empty, like a real hash.  The counts pretend the hashing is
perfect, and might help code expecting a slashed style count, but don't
depend on the actual values.  (Use C<keys> for a count of how many
properties.)

C<Goo::Canvas::Item> has a child properties scheme for its drawing elements
but TiedChildProperties can't be used with that.  (It might be possible, but
perhaps a separate Tie class would be better.)  TiedChildProperties could be
used with widget children of a C<Goo::Canvas> though, since a C<Goo::Canvas>
is a subclass of C<Gtk2::Container>, except it doesn't have any child
properties.

=head1 FUNCTIONS

=over 4

=item C<< tie %h, 'Gtk2::Ex::TiedChildProperties', $child >>

=item C<< tie %h, 'Gtk2::Ex::TiedChildProperties', $child, key=>value,... >>

Tie a hash C<%h> to a widget C<$child> so that C<%h> accesses its container
child properties for whatever parent widget it's in.  The
keys of C<%h> are child property names, the values are the settings in
C<$child>.

C<%h> reflects whatever container parent the C<$child> widget is in at a
given time.  If C<$child> is not in any container then C<%h> is empty (no
properties).

Optional key/value pairs in the C<tie> set the following options

=over 4

=item weak (boolean, default false)

Hold only a weak reference to C<$child>.

    tie %h, 'Gtk2::Ex::TiedChildProperties', $child, weak=>1;

If C<$child> is garbage collected while the tied C<%h> still exists then
C<%h> gives C<undef> for all fetches, does nothing for all stores, C<exists>
is always false, and C<keys> and C<each> are empty.

Doing nothing for stores is designed to ignore C<local> or similar cleanups
which might still be pending.  If no-one else cared whether the container
lived or died then restoring settings can't be too important.

=back

=item C<< $hashref = Gtk2::Ex::TiedChildProperties->new ($child) >>

=item C<< $hashref = Gtk2::Ex::TiedChildProperties->new ($child, key=>value, ...) >>

Create and return a new anonymous hashref tied to the child properties of
C<$child>.  This is the same as

    tie my(%hash), 'Gtk2::Ex::TiedChildProperties', $child;
    $hashref = \%hash;

The difference between a hash and a hashref is normally just a matter of
which style you prefer.  Both can be created with one line of code (the
C<my> worked into the C<tie> call for the plain hash).

=back

=head1 TIED OBJECT FUNCTIONS

The tie object associated with the hash, as returned by the C<tie> or
obtained later with C<tied>, has the following methods.

=over 4

=item C<< $tobj->child >>

Return the underlying widget being accessed by C<$tobj>.

    my %hash
    my $tobj = tie %hash, 'Gtk2::Ex::TiedListColumn', $child;
    ...
    print $tobj->child;  # the original $child

Or getting the C<$tobj> later with C<tied>,

    my %hash
    tie %hash, 'Gtk2::Ex::TiedListColumn', $child;
    ...
    my $tobj = tied(%hash);
    my $child = $tobj->child;
    $child->show;

=back

=head1 SEE ALSO

L<Gtk2::Container>, L<Gtk2::Widget>, L<Glib::Ex::TieProperties>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-tiedlistcolumn/index.html>

=head1 LICENSE

Copyright 2009, 2010 Kevin Ryde

Glib-Ex-TiedListColumn is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Glib-Ex-TiedListColumn is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Glib-Ex-TiedListColumn.  If not, see L<http://www.gnu.org/licenses/>.

=cut
