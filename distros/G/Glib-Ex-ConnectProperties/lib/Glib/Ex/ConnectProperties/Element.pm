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



# $elem->do_read_handler()
# Glib::Ex::ConnectProperties::do_read_handler(..., $elem)
# \&Glib::Ex::ConnectProperties::read_handler
#
# connect_signals()
# disconnect()


package Glib::Ex::ConnectProperties::Element;
use 5.008;
use strict;
use warnings;

use Carp;
our @CARP_NOT = ('Glib::Ex::ConnectProperties');

our $VERSION = 19;

# uncomment this to run the ### lines
#use Smart::Comments;


sub new {
  my $class = shift;
  return bless { @_ }, $class;
}

# default no properties
use constant pspec_hash => {};

sub find_property {
  my ($self) = @_;
  return $self->pspec_hash->{$self->{'pname'}};
}
sub check_property {
  my ($self) = @_;
  ### Element check_property() ...
  if (! defined $self->find_property) {
    croak("ConnectProperties: ", $self->{'object'},
          " has no property ", $self->{'pname'});
  }
}

# not documented yet
sub is_readable {
  my ($self) = @_;
  ### Element is_readable() ...
  my $pspec;
  return (! ($pspec = $self->find_property)
          || ($pspec->get_flags & 'readable'));
}

# not documented yet
sub is_writable {
  my ($self) = @_;
  ### Element is_writable() ...
  my $pspec;
  return (! ($pspec = $self->find_property)
          || ($pspec->get_flags & 'writable'));
}

# $self in signal data is a circular reference, but ConnectProperties
# disconnect() calls the disconnect() here to undo
#
# not documented yet
sub connect_signals {
  my ($self) = @_;
  ### Element connect_signals() ...
  my $object = $self->{'object'};
  my $ids = $self->{'ids'} = Glib::Ex::SignalIds->new ($object);
  foreach my $signame (delete $self->{'read_signal'} || $self->read_signal) {
    ### $signame
    $ids->add ($object->signal_connect
               ($signame,
                \&Glib::Ex::ConnectProperties::_do_read_handler,
                $self));
  }
}

# not documented yet
sub disconnect {
  my ($self) = @_;
  delete $self->{'ids'};
}

sub get_value {
  my ($self) = @_;
  croak ("ConnectProperties: cannot get value from ", $self->{'object'},
         " property '", $self->{'pname'}, "'");
}
sub set_value {
  my ($self) = @_;
  croak ("ConnectProperties: cannot set value on ", $self->{'object'},
         " property '", $self->{'pname'}, "'");
}

1;
__END__

# sub value_validate {
#   my ($self, $value) = @_;
#   if (my $pspec = $self->find_property) {
#     # value_validate() is wrapped in Glib 1.220, remove the check when ready
#     # to demand that version
#     if (my $coderef = $pspec->can('value_validate')) {
#       (undef, $value) = $pspec->$coderef($value);
#     }
#   }
#   return $value;
# }
#
# sub value_equal {
#   my ($self, $v1, $v2) = @_;
#   if (my $pspec = $self->find_property) {
#     return _pspec_equal ($pspec, $v1, $v2);
#   }
#   return $v1 eq $v2;
# }

=for stopwords Glib-Ex-ConnectProperties hashref pspecs boolean ParamSpec runtime Gtk2 lookup subclasses Subclasses ConnectProperties Ryde

=head1 NAME

Glib::Ex::ConnectProperties::Element -- special property handling

=head1 SYNOPSIS

 package Glib::Ex::ConnectProperties::Element::some_thing;
 use base 'Glib::Ex::ConnectProperties::Element';

=head1 DESCRIPTION

This is the base class for special properties in
L<Glib::Ex::ConnectProperties>.  A subclass for a property such as

    some-thing#foo

should be a class

    package Glib::Ex::ConnectProperties::Element::some_thing;
    use base 'Glib::Ex::ConnectProperties::Element';

An Element object is a hashref created from
C<Glib::Ex::ConnectProperties-E<gt>new()> etc with property name and
options.

    { object  => $obj,       # Glib::Object
      pname   => $string,    # property name "foo"
      ids     => $signalids, # signal connections
      ... further options
    }

A subclass should as a minimum implement the following methods, described
below.

    find_property() or pspec_hash()
    read_signal()
    get_value()            # if readable
    set_value()            # if writable

As an example, the simplest subclass is
C<Glib::Ex::ConnectProperties::Element::object> which is the code for plain
object C<get_property()> etc.  It can be seen how C<find_property()> looks
at the object property pspecs and C<read_signal()> is the notify, then
simply C<get_property()> or C<set_property()> to manipulate the value.

C<Glib::Ex::ConnectProperties::Element::textbuffer> is an example of
read-only access to non-property characteristics of a text buffer.  It has a
fixed set of property names in C<pspec_hash()>, and in fact shares the
boolean for "empty" and "not-empty" because the ParamSpec name field doesn't
matter, only the type etc.

C<Glib::Ex::ConnectProperties::Element::screen_size> is another read-only,
with some runtime adaption to notice when Gtk2 is new enough to have the
C<monitors-changed> signal for screen size in millimetres changing.

=head1 METHODS

=head2 Mandatory Methods

=over

=item C<$pspec = $elem-E<gt>find_property()>

=item C<$hashref = $elem-E<gt>pspec_hash()>

C<find_property()> should return a C<Glib::ParamSpec> object for the
property name C<$elem-E<gt>{'pname'}>, or return C<undef> if no such
property.

The default C<find_property()> implementation calls C<pspec_hash()>.  That
method should return a hashref name to ParamSpec

   { pname => $pspec,
     ...
   }

in which to lookup C<$elem-E<gt>{'pname'}>.  C<pspec_hash()> suits
subclasses with a fixed set of property names.  Subclasses where it varies
should implement some sort of C<find_property()>.

In each ParamSpec the following fields should be set

    flags       "readable" and/or "writable"
    type        for object, boxed, enum, flags

and for writable properties

    min,max     on int, float

The type of the ParamSpec, such as C<Glib::Param::Int> etc, is used to
know what sort of value comparison and validation should be done in the
ConnectProperties propagation.  For example C<Glib::Param::Int> properties
are compared using C<==> whereas strings are compared with C<eq>.

=item C<@signal_names = $elem-E<gt>read_signal()>

Return the name of a signal on C<$self-E<gt>{'object'}> to use to listen for
changes to the property value.

The signal name may vary with the property name C<$self-E<gt>{'pname'}>, as
for example the plain object properties using C<notify>,

    sub read_signal {
      my ($self) = @_;
      return 'notify::'.$self->{'pname'};
    }

For some element subclasses there might be a single signal for the changes
in a set of related properties,

    use constant read_signal => 'foo-changed';

C<read_signal()> is only used for readable properties.  The C<read_signal>
option to ConnectProperties can override it.

The return from C<read_signal()> is actually a list of signal names.  If a
class doesn't need any signal at all on C<$self-E<gt>{'object'}> then return
an empty list.

    use constant read_signal => ();

=item C<$value = $elem-E<gt>get_value()>

=item C<$elem-E<gt>set_value($value)>

Get or set the value of the C<$elem-E<gt>{'pname'}> property on
C<$elem-E<gt>{'object'}>.

This is usually a method call on the object, some attribute it doesn't offer
as a real property or which is more convenient when transformed in some way.

An element subclass will generally look up or derive a method name from
C<$elem-E<gt>{'pname'}>.

    my %get_method = (width  => 'get_width',
                      height => 'get_height');
    sub get_value {
      my ($self) = @_;
      my $method = $method{$self->{'pname'}};
      return $self->{'object'}->$method;
    }

=back

=head2 Optional Methods

=over

=item C<$elem-E<gt>check_property()>

Check that C<$elem-E<gt>{'pname'}> is a valid property for the target
C<$elem-E<gt>{'object'}>.  Croak if it's not.

This is called during element initialization.  The base implementation does
C<$elem-E<gt>find_property()> and if that's C<undef> then croaks with "no
such property".  An element subclass might make additional checks, or might
give a better explanation if perhaps a property is sometimes available and
sometimes not.

It's suggested that an element class should not check the class of the
target C<$elem-E<gt>{'object'}>, but only perhaps for availability of
required methods, signals, etc.  That allows a similar object with
compatible features to be used with the element class.

=back

=head1 SEE ALSO

L<Glib::Ex::ConnectProperties>

L<Glib::Object>,
L<Glib::ParamSpec>

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
