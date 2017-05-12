package Gnome2::PanelApplet;

# $Id$

use 5.008;
use strict;
use warnings;

use Gnome2;
use Gnome2::GConf;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.03';

sub import {
  my $self = shift();
  $self -> VERSION(@_);
}

sub dl_load_flags { 0x01 }

Gnome2::PanelApplet -> bootstrap($VERSION);

sub gconf_get_list {
  my ($applet, $key, $check_error) = @_;
  $check_error = 1 unless defined $check_error;

  my $value = $applet->gconf_get_value ($key, $check_error);
  return $value->{value};
}

sub gconf_set_list {
  my ($applet, $key, $list_type, $list, $check_error) = @_;
  $check_error = 1 unless defined $check_error;

  $applet->gconf_set_value ($key,
                            { type => $list_type,
                              value => $list },
                            $check_error);
}

1;
__END__

=head1 NAME

Gnome2::PanelApplet - Perl interface to GNOME's applet library

=head1 SYNOPSIS

  # Initialize.
  Gnome2::Program->init ('My Applet', '0.01', 'libgnomeui'
                         sm_connect => FALSE);

  # Register our applet with that bonobo thingy.  The OAFIID stuff is
  # specified in a .server file.  See
  # C<examples/GNOME_PerlAppletSample.server> in the
  # I<Gnome2::PanelApplet> tarball for an example.
  Gnome2::PanelApplet::Factory->main (
    'OAFIID:PerlSampleApplet_Factory', # iid of the applet
    'Gnome2::PanelApplet',             # type of the applet
    \&fill                             # sub that populates the applet
  );

  sub fill {
    my ($applet, $iid, $data) = @_;

    # Safety measure: if we're passed the wrong IID, just return.
    if ($iid ne 'OAFIID:PerlSampleApplet') {
      return FALSE;
    }

    # Gnome2::PanelApplet isa Gtk2::EventBox, so it isa Gtk2::Container
    # in particular.  That means we can call add() on it.
    my $label = Gtk2::Label->new ('Hi, there!');
    $applet->add ($label);
    $applet->show_all;

    return TRUE;
  }

=head1 ABSTRACT

Use Perl to write GNOME applets that sit on the panel.

=head1 DOCUMENTATION

I<Gnome2::PanelApplet::Factory-E<gt>main> is documented in
L<Gnome2::PanelApplet::Factory>.  The methods you can call on the applet
instance are documented in L<Gnome2::PanelApplet::main>.  The GConf helper
functions are documented in L<Gnome2::PanelApplet::GConf>.

=head1 SEE ALSO

L<Gnome2::PanelApplet::index>, L<Gnome2>, L<Gtk2>, L<Gtk2::api> and
L<http://developer.gnome.org/doc/API/2.0/panel-applet/>.

=head1 AUTHOR

Emmanuele Bassi E<lt>emmanuele.bassi at iol dot itE<gt>

Torsten Schoenfeld E<lt>kaffeetisch at gmx dot deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003, 2007 by the gtk2-perl team

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
details.

You should have received a copy of the GNU Lesser General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 51
Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

=cut
