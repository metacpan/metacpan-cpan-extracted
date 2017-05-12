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


package Glib::Ex::ConnectProperties::Element::widget_allocation;
use 5.008;
use strict;
use warnings;
use Glib;
use Gtk2;  # for Gtk2::Gdk::Rectangle class
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 19;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant pspec_hash =>
  do {
    # dummy names and dummy range, just want an "int" type
    # note paramspec names cannot be empty strings
    # width/height min is actually 1, but that that doesn't matter as it's
    # read-only
    my $pspec = Glib::ParamSpec->int ('x',    # name
                                      '',     # nick
                                      '',     # blurb
                                      -32768, # min
                                      32767,  # max
                                      0,      # default
                                      'readable');
    ({
      x      => $pspec,
      y      => $pspec,
      width  => $pspec,
      height => $pspec,
      rectangle => Glib::ParamSpec->boxed ('rectangle',  # name
                                           '',           # nick
                                           '',           # blurb
                                           'Gtk2::Gdk::Rectangle',
                                           'readable'),
     })
  };

use constant read_signal => 'size-allocate';

sub get_value {
  my ($self) = @_;
  ### widget_allocation get_value()
  my $pname = $self->{'pname'};
  my $rect = $self->{'object'}->allocation;
  ### rect: $rect->values
  if ($pname eq 'rectangle') {
    return $rect->copy;
  }
  return $rect->$pname;
}

1;
__END__

=for stopwords Glib-Ex-ConnectProperties ConnectProperties widget's Ryde

=head1 NAME

Glib::Ex::ConnectProperties::Element::widget_allocation -- widget size and position

=for test_synopsis my ($widget,$another);

=head1 SYNOPSIS

 Glib::Ex::ConnectProperties->new([$widget, 'widget-allocation#width'],
                                  [$another, 'something']);

=head1 DESCRIPTION

This element class implements ConnectProperties access to the fields of
C<< $widget->allocation() >> on a C<Gtk2::Widget> (see L<Gtk2::Widget>).

    widget-allocation#width       integer, read-only
    widget-allocation#height      integer, read-only
    widget-allocation#x           integer, read-only
    widget-allocation#y           integer, read-only
    widget-allocation#rectangle   Gtk2::Gdk::Rectangle, read-only

C<widget-allocation#width> and C<widget-allocation#height> are the widget's
current size as set by its container parent (or set by the window manager
for a top level).  The values are read-only, but for example might be
connected up to display the size somewhere,

    Glib::Ex::ConnectProperties->new
      ([$toplevel, 'widget-allocation#width'],
       [$label,    'label']);

One use could be to connect the allocated size of one widget to the
C<width-request> or C<height-request> of another so as to make it follow
that size, though how closely depends on what the target's container parent
does for a given requested size.  (See C<Gtk2::SizeGroup> for making a
common width or height request among a set of widgets.)

    Glib::Ex::ConnectProperties->new
      ([$image,  'widget-allocation#height'],
       [$vscale, 'height-request']);

C<widget-allocation#x> and C<widget-allocation#y> are the position of the
widget area within its windowed ancestor.  These may be of limited use but
are included for completeness.

C<widget-allocation#rectangle> is the whole C<< $widget->allocation() >>
object.

=head1 SEE ALSO

L<Glib::Ex::ConnectProperties>,
L<Glib::Ex::ConnectProperties::Element::widget>,
L<Gtk2::Widget>,
L<Gtk2::Gdk::Rectangle>

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
