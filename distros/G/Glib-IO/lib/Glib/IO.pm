package Glib::IO;
$Glib::IO::VERSION = '0.001';
=encoding utf8

=head1 NAME

Glib::IO - Perl bindings to the GIO library

=head1 SYNOPSIS

  use Glib;
  use Glib::IO;

  # Synchronous I/O
  $cur_dir = Glib::IO::File::new_for_path('.');
  $enumerator = $cur_dir->enumerate_children('standard::*', [], undef);
  $file_info = $enumerator->next_file(undef);
  while ($next_file) {
      say 'Path: ' + $file_info->get_name();
  }

  # Asynchronous I/O
  $loop = Glib::MainLoop->new();
  $file = Glib::IO::File::new_for_path('/etc/passwd');
  $file->query_info_async('access::can-read,access::can-write', [], 0, sub {
      my ($file, $res, $data) = @_;
      my $info = $file->query_info_finish();
      say 'Can read:  ' + $info->get_attribute_boolean('access::can-read');
      say 'Can write: ' + $info->get_attribute_boolean('access::can-write');
      $loop->quit();
  }
  $loop->run();

  # Platform API
  $network_monitor = Glib::IO::NetworkMonitor::get_default();
  say 'Connected: ', $network_monitor->get_network_available() ? 'Yes' : 'No';

=head1 ABSTRACT

Perl bindings to the GIO library. This modules allows you to write portable
code to perform synchronous and asynchronous I/O; implement IPC clients and
servers using the DBus specification; interact with the operating system and
platform using various services.

=head1 DESCRIPTION

The C<Glib::IO> module allows a Perl developer to access the GIO library, the
high level I/O and platform library of the GNOME development platform. GIO is
used for:

=over

=item * local and remote enumeration and access of files

GIO has multiple backends to access local file systems; SMB/CIFS volumes;
WebDAV resources; compressed archives; local devices and remote web services.

=item * stream based I/O

Including files, memory buffers, and network streams.

=item * low level and high level network operations

Sockets, Internet addresses, datagram-based connections, and TCP connections.

=item * TLS/SSL support for socket connections

=item * DNS resolution and proxy

=item * low level and high level DBus classes

GIO allows the implementation of clients and servers, as well as proxying
objects over DBus connections.

=back

Additionally, GIO has a collection of high level classes for writing
applications that integrate with the platform, like:

=over

=item settings

=item network monitoring

=item a base Application class

=item extensible data models

=item content type matching

=item application information and launch

=back

For more information, please visit the GIO reference manual available on
L<https://developer.gnome.org/gio/stable>. The Perl API closely matches the
C one, and eventual deviations will be documented here.

The principles underlying the mapping from C to Perl are explained in the
documentation of L<Glib::Object::Introspection>, on which C<Glib::IO> is based.

L<Glib::Object::Introspection> also comes with the C<perli11ndoc> program which
displays the API reference documentation of all installed libraries organized
in accordance with these principles.

=cut

use strict;
use warnings;
use Glib::Object::Introspection;

my $GIO_BASENAME = 'Gio';
my $GIO_VERSION = '2.0';
my $GIO_PACKAGE = 'Glib::IO';

sub import {
  Glib::Object::Introspection->setup(
    basename => $GIO_BASENAME,
    version => $GIO_VERSION,
    package => $GIO_PACKAGE);
}

#=head2 Customizations and overrides
#
#=cut

1;
__END__

=head1 SEE ALSO

=over

=item * To discuss Glib::IO and ask questions join gtk-perl-list@gnome.org at
L<http://mail.gnome.org/mailman/listinfo/gtk-perl-list>.

=item * Also have a look at the gtk2-perl website and sourceforge project page,
L<http://gtk2-perl.sourceforge.net>.

=item * L<Glib>

=item * L<Glib::Object::Introspection>

=item * L<Gtk3>

=back

=head1 AUTHORS

=over

=item Torsten Schönfeld <kaffeetisch@gmx.de>

=item Emmanuele Bassi <ebassi@gnome.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2015 by Torsten Schönfeld <kaffeetisch@gmx.de>
Copyright 2017  Emmanuele Bassi

This library is free software; you can redistribute it and/or modify it under
the terms of the Lesser General Public License (LGPL).  For more information,
see http://www.fsf.org/licenses/lgpl.txt

=cut
