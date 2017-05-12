package Gtk2::TrayManager;

use 5.008;
use strict;
use warnings;

use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.05';

sub dl_load_flags { 0x01 }

bootstrap Gtk2::TrayManager $VERSION;

1;

__END__

=pod

=for comment
written by Gavin Brown <gavin.brown@uk.com>

=head1 NAME

Gtk2::TrayManager - Perl bindings for EggTrayManager

=head1 SYNOPSIS

	use Gtk2 -init;
	use Gtk2::TrayManager;

	my $screen = Gtk2::Gdk::Screen->get_default;

	if (Gtk2::TrayManager->check_running($screen)) {
		print STDERR "A tray manager is already running, sorry!\n";
		exit 256;
	}

	my $tray = Gtk2::TrayManager->new;
	$tray->manage_screen($screen);
	$tray->set_orientation('vertical');

	$tray->signal_connect('tray_icon_added', sub {
		# $_[1] is a Gtk2::Socket
	});

	$tray->signal_connect('tray_icon_removed', sub {
		# $_[1] is a Gtk2::Socket
	});

=head1 ABSTRACT

The EggTrayManager library is used internally by GNOME to implement the
server-side of the Notification Area (or system tray) protocol.
Gtk2::TrayManager allows you to create notification area applications using
Gtk2-Perl.

=head1 METHODS

	$running = Gtk2::TrayManager->check_running($screen);

This method returns a boolean value indicating whether another program is
already managing notifications for the given L<Gtk2::Gdk::Screen>. If this
method returns a false value, then you should give way to the application that
is already running.

	$tray = Gtk2::TrayManager->new;

This creates a tray manager object.

	$tray->manage_screen($screen);

This tells the tray to manage notifications for the L<Gtk2::Gdk::Screen>
referenced by C<$screen>.

	$tray->set_orientation($orientation);

This method tells the tray whether icons are to be arranged vertically or
horizontally. C<$orientation> may be either 'C<vertical>' or 'C<horizontal>'.

	$title = $tray->get_child_title($child);

This method returns a string containing the title of the icon defined by
C<$child>.

=head1 SIGNALS

=over

=item C<tray_icon_added>

Emitted when a client plug (eg one created by L<Gtk2::TrayIcon>) wants to
connect. For callbacks connected to this signal, C<@_> will have the form

	@_ = (
		bless( {}, 'Gtk2::TrayManager' ),
		bless( {}, 'Gtk2::Socket' )
	);

=item C<tray_icon_added>

Emitted when a client plug has disconnected. For callbacks connected to this
signal, C<@_> will have the form

	@_ = (
		bless( {}, 'Gtk2::TrayManager' ),
		bless( {}, 'Gtk2::Socket' )
	);

=item C<message_sent>, C<message_removed>

The Freedesktop.org specification includes support for "balloon messages", but
these are not currently implemented in EggTrayManager.

=item C<lost_selection>

As a rule, compliant applications should check to for an already running
manager, and give way to it if it finds one. However, it is possible that
your application might have its X selection forcibly removed; this signal
is emitted if this should happen.

=back

=head1 SEE ALSO

L<Glib>, L<Gtk>, L<Gtk2::TrayIcon> and the System Tray spec at L<http://www.freedesktop.org/Standards/systemtray-spec>.

=head1 AUTHOR

Christian Borup <borup at cpan dot org>. Nagging and documentation by Gavin Brown <gavin.brown@uk.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by the gtk2-perl team.  

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.  

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public License for more details.  

You should have received a copy of the GNU Library General Public License along with this library; if not, write to the  Free Software Foundation, Inc., 59 Temple Place - Suite 330,  Boston, MA  02111-1307  USA.  

=cut
