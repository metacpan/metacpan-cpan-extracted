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


package Glib::Ex::ConnectProperties::Element::widget;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;
use Gtk2;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 19;

# uncomment this to run the ### lines
#use Smart::Comments;


# For reference, among the various "-set" and "-changed" signals,
#
#    parent-set   - already a "parent" property
#
# Other possibilities:
#     widget#screen-nodefault      only when has-screen
#     
#     widget#mapped
#     widget-flags#mapped
#         change on map-event, unmap-event, or unmap action?
#
#     widget-style#pname         style-set prop readable
#     widget-style#fg.normal     writable modify-fg
#     widget-style#property.foo
#     widget-style-property#pname     style-set prop readable
#

my %pspecs = (direction => Glib::ParamSpec->enum ('direction',
                                                  'direction',
                                                  '', # blurb
                                                  'Gtk2::TextDirection',
                                                  'none', # default, unused
                                                  Glib::G_PARAM_READWRITE),
              state => Glib::ParamSpec->enum ('state',
                                              'state',
                                              '', # blurb
                                              'Gtk2::StateType',
                                              'normal', # default, unused
                                              Glib::G_PARAM_READWRITE),
              toplevel => Glib::ParamSpec->object ('toplevel',
                                                   'toplevel',
                                                   '', # blurb
                                                   'Gtk2::Widget',
                                                   'readable'),
             );
my $pspec_screen_writable;
if (Gtk2::Widget->can('get_screen')) {
  # get_screen() new in Gtk 2.2
  $pspecs{'screen'} = Glib::ParamSpec->object ('screen',
                                               'screen',
                                               '', # blurb
                                               'Gtk2::Gdk::Screen',
                                               'readable');
  $pspec_screen_writable = Glib::ParamSpec->object ('screen',
                                                    'screen',
                                                    '', # blurb
                                                    'Gtk2::Gdk::Screen',
                                                    Glib::G_PARAM_READWRITE);
}
if (Gtk2::Widget->can('has_screen')) {
  # has_screen() new in Gtk 2.2
  $pspecs{'has-screen'} = Glib::ParamSpec->boolean ('has-screen',
                                                    'has-screen',
                                                    '', # blurb
                                                    0, # default
                                                    'readable');
}
sub find_property {
  my ($self) = @_;
  my $pname = $self->{'pname'};
  if ($pname eq 'screen' && $self->{'object'}->can('set_screen')) {
    return $pspec_screen_writable;
  }
  return $pspecs{$pname};
}

my %read_signal = ('has-screen' => 'screen-changed',
                   toplevel     => 'hierarchy-changed');
sub read_signal {
  my ($self) = @_;
  my $pname = $self->{'pname'};
  return ($read_signal{$pname} || "$pname-changed");
}

my %get_method = ('has-screen' => 'has_screen',
                  toplevel     => \&_widget_get_toplevel,
                  (Gtk2::Widget->can('get_state') # new in Gtk 2.18
                   ? ()
                   : (state => 'state')),  # otherwise field directly
                 );

sub get_value {
  my ($self) = @_;
  my $pname = $self->{'pname'};
  my $get_method = $get_method{$pname} || "get_$pname";
  return $self->{'object'}->$get_method;
}
sub set_value {
  my ($self, $newval) = @_;
  my $set_method = "set_$self->{'pname'}";
  return $self->{'object'}->$set_method ($newval);
}

sub _widget_get_toplevel {
  my ($widget) = @_;
  my $toplevel;
  return (($toplevel = $widget->get_toplevel) && $toplevel->flags & 'toplevel'
          ? $toplevel
          : undef);
}

1;
__END__

=for stopwords Glib-Ex-ConnectProperties ConnectProperties ltr rtl toplevel Gtk prelight Ryde

=head1 NAME

Glib::Ex::ConnectProperties::Element::widget -- various widget attributes

=for test_synopsis my ($widget,$another);

=head1 SYNOPSIS

 Glib::Ex::ConnectProperties->new([$widget, 'widget#direction'],
                                  [$another, 'something']);

=head1 DESCRIPTION

This element class implements ConnectProperties access to the following
attributes of a L<Gtk2::Widget>,

    widget#direction      Gtk2::TextDirection enum, ltr or rtl
    widget#screen         Gtk2::Gdk::Screen
    widget#has-screen     boolean, read-only
    widget#state          Gtk2::StateType enum
    widget#toplevel       Gtk2::Window or undef, read-only

These things are not available as widget properties as such (though perhaps
they could have been) but instead have get/set methods and report changes
with specific signals.

=over

=item *

C<widget#direction> is the "ltr" or "rtl" text direction, per
C<get_direction()> and C<set_direction()> methods.

If "none" is set then C<get_direction()> gives back "ltr" or "rtl" following
the global default.  Storing "none" with ConnectProperties probably won't
work very well, except to a forced C<write_only> target so that it's not
read back.

=item *

C<widget#screen> uses the C<get_screen()> method.  This means it will give
the default screen until the widget is added to a toplevel C<Gtk2::Window>
or similar to determine the screen.

C<widget#screen> is read-only for most widgets, but is writable for anything
with a C<set_screen()> such as C<Gtk2::Menu>.  There's a plain C<screen>
property on C<Gtk2::Window> so it doesn't need this special
C<widget#screen>, but other widgets benefit.

C<Gtk2::Gdk::Screen> is new in Gtk 2.2 and C<widget#screen> and
C<widget#has-screen> are not available in Gtk 2.0.x.

=item *

C<widget#state> is the C<state()> / C<set_state()> condition, such as
"normal" or "prelight".

Note that storing "insensitive" doesn't work very well, since a subsequent
setting back to "normal" doesn't turn the sensitive flag back on.  Perhaps
this will change in the future, so as to actually enforce the desired new
state.

=item *

C<widget#toplevel> is the widget ancestor with C<toplevel> flag set, or
C<undef> if none.  This is C<get_toplevel()> plus its recommended
C<< $parent->toplevel() >> flag check.  The C<hierarchy-changed> signal
indicates a change to the toplevel.

    Glib::Ex::ConnectProperties->new
      ([$toolitem, 'widget#toplevel'],
       [$dialog,   'transient-for']);

The toplevel is normally a C<Gtk2::Window> or subclass, but in principle
could be another class.

=back

=head1 SEE ALSO

L<Glib::Ex::ConnectProperties>,
L<Glib::Ex::ConnectProperties::Element::widget_allocation>,
L<Gtk2::Widget>

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
