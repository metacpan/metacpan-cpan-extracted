# Copyright 2010, 2011, 2012 Kevin Ryde

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

package Glib::Ex::ConnectProperties::Element::goo_child;
use 5.008;
use strict;
use warnings;
use Carp;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 19;

# uncomment this to run the ### lines
use Smart::Comments;

# no check
sub check_property {
  my ($self) = @_;
  ### Element-child check_property()
  Goo::Canvas::Item->can('find_child_property')
      || croak 'ConnectProperties: No Gtk2::Canvas::Item->find_child_property in this Goo-Canvas';
}

# always read/write in case not a child yet
use constant is_readable => 1;
use constant is_writable => 1;

sub find_property {
  my ($self) = @_;
  ### Element-child find_property()
  my $parent;
  return (($parent = $self->{'object'}->get_parent)
          && $parent->find_child_property ($self->{'pname'}));
}

sub read_signals {
  my ($self) = @_;
  return ('child-notify::' . $self->{'pname'});

  # 'notify::parent'
}

# Goo::Canvas::Item has get_child_properties() / set_child_properties(), and
# in Goo::Canvas 0.06 only the plurals wrapped, not the singular names
# get_child_property() / set_child_property()
#
sub get_value {
  my ($self) = @_;
  ### Element-child get_value(): $self->{'pname'}
  ### parent: $self->{'object'}->get_parent
  my $object = $self->{'object'};
  my $parent;
  return (($parent = $object->get_parent)
          $parent->get_child_properties ($object, $self->{'pname'}));
}
sub set_value {
  my ($self, $value) = @_;
  ### Element-child set_value(): $self->{'pname'}, $value
  ### parent: $self->{'object'}->get_parent
  my $object = $self->{'object'};
  if (my $parent = $object->get_parent) {
    $parent->set_child_properties ($object, $self->{'pname'}, $value);
  }
}

1;
__END__





# =head2 C<Goo::Canvas> Child Properties
# 
# C<Goo::Canvas::Item> defines "child properties" which exist on an item
# when it's the child of a particular item grouping class.  For example
# C<Goo::Canvas::Table> has attachment points and options for each child.
# These are separate from an item's normal object properties.
#
# Child properties can be accessed from ConnectProperties in Goo-Canvas
# 0.???  under a property name like "goo-child#top-attach" on a child item.
# 
#     Glib::Ex::ConnectProperties->new
#       ([$childitem, 'goo-child#left-padding'],
#        [$adj,       'value']);
#
# Currently the C<$childitem> must have a parent, which must have the given
# child property, and the parent cannot be changed.  In the future this will
# probably be relaxed, for flexibility, but it's not quite clear yet exactly
# what should happen when there's no parent, or when a new parent is gained,
# or if the parent at a particular time doesn't have the given property.
#
# Goo::Canvas::Item

# The case where a widget has a parent and doesn't change is clear, it's
# just a property with C<child_set_property> etc for getting and setting.
# But it's not yet settled what should happen if a child widget changes
# parent, or doesn't yet have a parent, or gets a parent without the
# property name in question.
#
# Currently when a widget has no parent it's considered not readable and not
# writable so is ignored until it gets a parent.  Getting a new parent is
# treated like the ConnectProperties C<new>, meaning the first readable is
# propagated to the child setting, or if the child setting is first then
# from it to the other elements.  Don't rely on this.  It will probably
# change.  Perhaps C<undef> on no parent would be better.
