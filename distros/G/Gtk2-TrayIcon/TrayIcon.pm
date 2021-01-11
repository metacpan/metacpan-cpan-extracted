package Gtk2::TrayIcon;

use 5.008;
use strict;
use warnings;

use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);


our $VERSION = '0.07';

sub dl_load_flags { 0x01 }

bootstrap Gtk2::TrayIcon $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

Gtk2::TrayIcon - (DEPRECATED) Perl interface to the EggTrayIcon library

=head1 SYNOPSIS

  use Gtk2::TrayIcon;
  Gtk2->init;

  my $icon= Gtk2::TrayIcon->new("test");
  my $label= Gtk2::Label->new("test");
  $icon->add($label);
  $icon->show_all;

  Gtk2->main;

=head1 ABSTRACT

B<DEPRECATED> This module allows a Perl developer to embed an arbitrary widget
in a System Tray like the Gnome notification area.

=head1 DESCRIPTION

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

Perl URL: https://gitlab.gnome.org/GNOME/perl-gtk2-trayicon

=item *

Upstream URL: https://gitlab.gnome.org/GNOME/libegg

=item *

Last upstream version: N/A

=item *

Last upstream release date: 2009-05-01

=item *

Migration path for this module: Gtk3::StatusIcon

=item *

Migration module URL: https://metacpan.org/pod/Gtk3

=back

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>


EggTrayIcon is slated for inclusion in Gtk+ at some point, which is the
reason the C<Gtk2::TrayIcon> namespace. As all egg libs, EggTrayIcon
is not considered api stable and its not installed as a shared object.

Enough about what it is not, C<Gtk2::TrayIcon> is first and foremost
a simple way of giving a Gtk2 script access to the system tray.

System Trays are found in both KDE and Gnome. But neither support the
spec fully (see below).

C<Gtk2::TrayIcon> is a subclass of C<Gtk2::Plug> and should be used
as such.

=head1 METHODS

5 methods are available.

=over 4

=item $trayicon= Gtk2::TrayIcon->new_from_screen($screen, $name)

This creates a widget already connected to the notification area
of C<$screen>. C<$screen> should be a C<Gtk::Gdk::Screen>.

=item $trayicon= Gtk2::TrayIcon->new($name)

Like C<new_from_screen> but uses the default screen of the active
display.

=item $msgid= $trayicon->send_message($timeout, $message)

Ask the tray to display C<$message> for C<$timeout> milliseconds.
If C<$timeout> is 0, the message will not expire.

Note that it is up to the tray to decide what to do with the message
both Gnome and KDE just ignores it.

=item $trayicon->cancel_message($msgid)

Ask the tray to cancel the message.

=back

=head1 SEE ALSO

L<Glib>, L<Gtk2> and The System Tray Spec http://www.freedesktop.org/Standards/systemtray-spec.

=head1 AUTHOR

Christian Borup E<lt>gtk2-perl at borup dot comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by the gtk2-perl team.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, see
<https://www.gnu.org/licenses/>.

=cut
