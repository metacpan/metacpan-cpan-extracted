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

package Glib::Ex::ConnectProperties::Element::child;
use 5.008;
use strict;
use warnings;
use Carp;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 19;

# uncomment this to run the ### lines
#use Smart::Comments;

sub check_property {
  my ($self) = @_;
  ### Element-child check_property()

  # check find_child_property() method exists, to avoid a slew of errors
  # later when attempting to set
  Gtk2::Container->can('find_child_property') # wrapped in Perl-Gtk2 1.240
      || croak 'ConnectProperties: No Gtk2::Container find_child_property() in this Perl-Gtk';

  # and that the property exists initially
  $self->SUPER::check_property();
}

# Base is_readable() / is_writable() are true if no find_property() pspec.
# Always read/write in case no parent or no such property.  But for now
# demanding the widget be in a parent with the property initially.
#
# use constant is_readable => 1;
# use constant is_writable => 1;

sub find_property {
  my ($self) = @_;
  ### Element-child find_property()
  my $parent;
  return (($parent = $self->{'object'}->get_parent)
          && $parent->find_child_property ($self->{'pname'}));
}

sub read_signal {
  my ($self) = @_;
  return ('child-notify::' . $self->{'pname'});
}

sub get_value {
  my ($self) = @_;
  ### Element-child get_value(): $self->{'pname'}
  ### parent: $self->{'object'}->get_parent
  my $object = $self->{'object'};
  my $parent;
  return (($parent = $object->get_parent)
          && $parent->child_get_property ($object, $self->{'pname'}));
}
sub set_value {
  my ($self, $value) = @_;
  ### Element-child set_value(): $self->{'pname'}, $value
  ### parent: $self->{'object'}->get_parent
  my $object = $self->{'object'};
  if (my $parent = $object->get_parent) {
    $parent->child_set_property ($object, $self->{'pname'}, $value);
  }
}

1;
__END__

=for stopwords  Glib-Ex-ConnectProperties ConnectProperties subclasses Gtk Perl-Gtk2 unparented Unparenting reparented reparent Ryde

=head1 NAME

Glib::Ex::ConnectProperties::Element::child -- container child properties

=for test_synopsis my ($childwidget,$another);

=head1 SYNOPSIS

 Glib::Ex::ConnectProperties->new([$childwidget, 'child#propname'],
                                  [$another,     'something']);

=head1 DESCRIPTION

This element class implements ConnectProperties access to the "child
properties" provided by C<Gtk2::Container> subclasses on a widget stored in
a container.

These properties require Perl-Gtk2 1.240 and up for
C<find_child_property()>.  The properties are accessed on the child widget,
with names as specified by the container.

    child#propname

For example C<Gtk2::Table> has child properties for the child attach
positions.  These are separate from normal object properties.

    Glib::Ex::ConnectProperties->new
      ([$adj,         'value'],
       [$childwidget, 'child#bottom-attach']);

C<$childwidget> should be a widget which is in a container with the given
child property.  If C<$childwidget> is unparented later then nothing is read
or written by ConnectProperties.  Unparenting happens during destruction and
quietly doing nothing is usually best in that case.

It's unspecified yet what happens if C<$childwidget> is reparented.  Gtk
emits a C<child-notify> for each property so in the current
ConnectProperties code the initial value set by the container will propagate
out.  It might be better to apply the first readable ConnectProperties
element onto the child, like at ConnectProperties creation.  (But noticing a
reparent requires a C<parent-set> or C<notify::parent> signal, so perhaps a
C<watch_reparent> option should say when reparent handling might be needed,
so as not to listen for something which will never happen.)

For reference, L<Goo::Canvas> has a system of child properties too on its
canvas items.  They could be offered too when its Perl bindings have
C<find_child_property()>.  But the method names are slightly different so
probably a separate C<goo-child#propname>.

=head1 SEE ALSO

L<Glib::Ex::ConnectProperties>,
L<Gtk2::Container>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/glib-ex-connectproperties/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012 Kevin Ryde

Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Glib-Ex-ConnectProperties.  If not, see L<http://www.gnu.org/licenses/>.

=cut
