package HTTP::Soup;

=head1 NAME

HTTP::Soup - HTTP client/server library for GNOME

=head1 SYNOPSIS

	use HTTP::Soup;

=head1 DESCRIPTION

This module provides the Perl bindings for the C library I<libsoup>.

Lisoup is an HTTP client/server library for GNOME. It uses GObjects and the glib
main loop, to integrate well with GNOME applications, and also has a synchronous
API, for use in threaded applications.

Libsoup is used in many GNOME projects and other software including gtk-webkit.

Features include:

=over 8

=item * Both asynchronous (GMainLoop and callback-based) and synchronous APIs

=item * Automatically caches connections

=item * SSL Support using GnuTLS

=item * Proxy support, including authentication and SSL tunneling

=item * Client support for Digest, NTLM, and Basic authentication

=item * Server support for Digest and Basic authentication

=item * Client and server support for XML-RPC

=back

For more information about libsoup refer to the library's web site:

	http://live.gnome.org/LibSoup

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use Glib::Object::Introspection;

Glib::Object::Introspection->setup(
	basename => 'Soup',
	version  => '2.4',
	package  => __PACKAGE__,
);


# XS stuff
use base 'DynaLoader';

__PACKAGE__->bootstrap($VERSION);

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }


1;

=head1 BUGS

For any kind of help or support simply send a mail to the gtk-perl mailing
list (gtk-perl-list@gnome.org).

=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms of:

=over 4

=item the GNU Lesser General Public License, version 2.1; or

=item the Artistic License, version 2.0.

=back

This module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You should have received a copy of the GNU Library General Public
License along with this module; if not, see L<http://www.gnu.org/licenses/>.

For the terms of The Artistic License, see L<perlartistic>.

=cut
