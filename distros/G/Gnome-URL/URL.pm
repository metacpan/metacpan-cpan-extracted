package Gnome::URL;

use 5.006;
use strict;
use warnings;
use Errno;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT_OK = (qw(GNOME_URL_H));

our @EXPORT = qw();
our $VERSION = '0.02';

sub AUTOLOAD {

	# This AUTOLOAD is used to 'autoload' constants from the constant()
	# XS function.  If a constant is not found then control is passed
	# to the AUTOLOAD in AutoLoader.

	my $constname;
	our $AUTOLOAD;
	($constname = $AUTOLOAD) =~ s/.*:://;
	croak "& not defined" if $constname eq 'constant';
	my $val = constant($constname, @_ ? $_[ 0 ] : 0);
	if ($! != 0) {
		if ($!{EINVAL}) {
			$AutoLoader::AUTOLOAD = $AUTOLOAD;
			goto &AutoLoader::AUTOLOAD;
		} else {
			croak "Your vendor has not defined Gnome::URL macro $constname";
		}
	}
	{
		no strict 'refs';

		# Fixed between 5.005_53 and 5.005_61
		if ($] >= 5.00561) {
			*$AUTOLOAD = sub () { $val };
		} else {
			*$AUTOLOAD = sub { $val };
		}
	}
	goto &$AUTOLOAD;
}

bootstrap Gnome::URL $VERSION;

1;
__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Gnome::URL - Perl extension for libgnome/gnome-url (GNOME 1.x)

=head1 SYNOPSIS

  use Gnome::URL;
  Gnome::URL::show($url);

=head1 DESCRIPTION

This module provides a Perl binding for url handling in the GNOME 
environment (http://www.gnome.org).
It can handle various types of URLs including http, https, ftp, file, info,
man, ghelp, and possibly others.

The commands used to view different types of URLs are determined by the user's
gnome configuration (most likely stored in ~/.gnome/Gnome).

See http://developer.gnome.org/doc/API/libgnome/gnome-gnome-url.html for
more information.

=head2 EXPORT

None by default.

=head2 Exportable constants

  GNOME_URL_H


=head1 AUTHOR

Mark A. Stratman <mark@sporkstorms.org>

=head1 COPYRIGHT

Copyright (c) 2001, Mark Stratman.  All Rights Reserved.
This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

The GNOME libraries (libgnome) are released under the LGPL (Library General
Public License). Visit http://www.gnu.org for more details.

=cut

