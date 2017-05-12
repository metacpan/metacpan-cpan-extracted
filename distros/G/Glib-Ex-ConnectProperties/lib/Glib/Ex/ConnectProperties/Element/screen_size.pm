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

package Glib::Ex::ConnectProperties::Element::screen_size;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;
use Scalar::Util;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 19;

# uncomment this to run the ### lines
#use Smart::Comments;


# _gdk_x11_screen_size_changed() emits size-changed if pixels changed, but
# not if pixels same but millimetres changed.
#
# _gdk_x11_screen_process_monitors_change() emits monitors-changed for any
# RandrNotify.
#

use constant pspec_hash =>
  do {
    # dummy name since paramspec name cannot be empty string
    my $pspec = Glib::ParamSpec->int ('width',   # name, unused
                                      '',        # nick, unused
                                      '',        # blurb, unused
                                      0, 32767,  # min,max, unused
                                      0,         # default, unused
                                      'readable');
    ({
      'width'     => $pspec,
      'height'    => $pspec,
      'width-mm'  => $pspec,
      'height-mm' => $pspec,
     })
  };

sub read_signal {
  my ($self) = @_;
  if ($self->{'pname'} =~ /mm/) {
    # "width-mm", "height-mm"
    my $screen = $self->{'object'};
    if ($screen->signal_query('monitors-changed')) {
      # new in gtk 2.14
      return 'monitors-changed';
    } else {
      # before gtk 2.14 there was no randr listening and width_mm/height_mm
      # were unchanging
      return;
    }
  } else {
    # "width", "height"
    return 'size-changed';
  }
}

my %method = ('width'     => 'get_width',
              'height'    => 'get_height',
              'width-mm'  => 'get_width_mm',
              'height-mm' => 'get_height_mm',
             );
sub get_value {
  my ($self) = @_;
  my $method = $method{$self->{'pname'}};
  return $self->{'object'}->$method;
}

1;
__END__

=for stopwords Glib-Ex-ConnectProperties ConnectProperties Gtk RANDR Xinerama Ryde

=head1 NAME

Glib::Ex::ConnectProperties::Element::screen_size -- screen size in pixels or millimetres

=for test_synopsis my ($screen,$another);

=head1 SYNOPSIS

 Glib::Ex::ConnectProperties->new([$screen, 'screen-size#width'],
                                  [$another, 'something']);

=head1 DESCRIPTION

This element class implements ConnectProperties access to the size of a a
L<Gtk2::Gdk::Screen>, either in pixels or millimetres.

    screen-size#width        integer pixels, read-only
    screen-size#height       integer pixels, read-only
    screen-size#width-mm     integer millimetres, read-only
    screen-size#height-mm    integer millimetres, read-only

These are C<< $screen->get_width() >> etc.

C<screen-size#width> and C<screen-size#height> changes are noticed with the
C<size-changed> signal.  In Gtk 2.14 C<screen-size#width-mm> and
C<screen-size#height-mm> changes are noticed with the C<monitors-changed>
signal.  Before Gtk 2.14 the millimetres don't change.

The size in pixels can change with the video mode.  The size in millimetres
can change from a RANDR or Xinerama rearrangement of output monitors.  In
all cases the sizes are read-only since C<Gtk2::Gdk::Screen> doesn't have
anything to perform video mode or monitor changes.

For example to display the width in a label,

    my $toplevel = Gtk2::Window->new('toplevel');
    my $screen = $toplevel->get_screen;

    # to display the size in some label widget
    Glib::Ex::ConnectProperties->new
      ([$screen, 'screen-size#width'],
       [$label,  'label']);

For reference, under X the way C<Gtk2::Gdk::Window> implements
C<fullscreen()> probably requires the window manager to notice screen size
changes and keep the window full screen on a screen size change.  Hopefully
an application doesn't have to link C<screen-size#> to the window size to
keep full screen.

=head1 SEE ALSO

L<Glib::Ex::ConnectProperties>,
L<Glib::Ex::ConnectProperties::Element::widget_allocation>,
L<Gtk2::Gdk::Screen>

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
