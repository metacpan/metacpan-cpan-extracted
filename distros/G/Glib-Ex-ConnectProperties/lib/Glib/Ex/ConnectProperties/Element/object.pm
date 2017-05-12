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

package Glib::Ex::ConnectProperties::Element::object;
use 5.008;
use strict;
use warnings;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 19;

# uncomment this to run the ### lines
#use Smart::Comments;

sub find_property {
  my ($self) = @_;
  return $self->{'object'}->find_property ($self->{'pname'});
}

sub read_signal {
  my ($self) = @_;
  return 'notify::' . $self->{'pname'};
}

sub get_value {
  my ($self) = @_;
  return $self->{'object'}->get_property ($self->{'pname'});
}
sub set_value {
  my ($self, $value) = @_;
  $self->{'object'}->set_property ($self->{'pname'}, $value);
}

1;
__END__

=for stopwords Glib-Ex-ConnectProperties ConnectProperties Ryde

=head1 NAME

Glib::Ex::ConnectProperties::Element::object -- plain object properties

=for test_synopsis my ($object,$another);

=head1 SYNOPSIS

 Glib::Ex::ConnectProperties->new([$object,  'propname'],
                                  [$another, 'propname']);

=head1 DESCRIPTION

This element class is the ConnectProperties access to the plain
C<get_property()> etc properties of an object.

There's no special C<object#> prefix for these properties, just give the
property name.  See L<Glib::Ex::ConnectProperties> for details.

=head1 SEE ALSO

L<Glib::Ex::ConnectProperties>,
L<Glib::Object>

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
