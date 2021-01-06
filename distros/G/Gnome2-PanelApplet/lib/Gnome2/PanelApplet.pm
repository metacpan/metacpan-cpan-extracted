package Gnome2::PanelApplet;

# $Id$

use 5.008;
use strict;
use warnings;

use Gnome2;
use Gnome2::GConf;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.04';

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

Gnome2::PanelApplet - (DEPRECATED) Perl interface to GNOME's applet library

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


B<DEPRECATED> Use Perl to write GNOME applets that sit on the panel.

=head1 DOCUMENTATION

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>

This module has been deprecated by the Gtk-Perl project.  This means that the
module will no longer be updated with security patches, bug fixes, or when
changes are made in the Perl ABI.  The Git repo for this module has been
archived (made read-only), it will no longer possible to submit new commits to
it.  You are more than welcome to ask about this module on the Gtk-Perl
mailing list, but our priorities going forward will be maintaining Gtk-Perl
modules that are supported and maintained upstream; this module is neither.

Since this module is licensed under the LGPL v2.1, you may also fork this
module, if you wish, but you will need to use a different name for it on CPAN,
and the Gtk-Perl team requests that you use your own resources (mailing list,
Git repos, bug trackers, etc.) to maintain your fork going forward.

=over

=item *

Perl URL: https://gitlab.gnome.org/GNOME/perl-gnome2-panelapplet

=item *

* Upstream URLs: https://developer.gnome.org/panel-applet/ and https://gitlab.gnome.org/GNOME/gnome-applets

=item *

* Last compatible upstream version: 2.32.1.1

=item *

* Last compatible upstream release date: 2010-11-22

=item *

* Migration path for this module: Gtk3::StatusIcon

=item *

* Migration module URL: https://metacpan.org/pod/Gtk3

=item *

=back

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>

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
with this library; if not, see <https://www.gnu.org/licenses/>.

=cut
