package Gtk2::TrayIcon;

use 5.008;
use strict;
use warnings;

use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);


our $VERSION = '0.06';

sub dl_load_flags { 0x01 }

bootstrap Gtk2::TrayIcon $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

Gtk2::TrayIcon - Perl interface to the EggTrayIcon library

=head1 SYNOPSIS

  use Gtk2::TrayIcon;
  Gtk2->init;

  my $icon= Gtk2::TrayIcon->new("test");
  my $label= Gtk2::Label->new("test");
  $icon->add($label);
  $icon->show_all;

  Gtk2->main;

=head1 ABSTRACT

This module allows a Perl developer to embed an arbitrary widget
in a System Tray like the Gnome notification area.

=head1 DESCRIPTION

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
License along with this library; if not, write to the 
Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
Boston, MA  02111-1307  USA.

=cut
