package Gnome::Sound;

use 5.006;
use strict;
use warnings;
use Errno;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(DynaLoader);

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
			croak "Your vendor has not defined Gnome::Sound macro $constname";
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

bootstrap Gnome::Sound $VERSION;

1;
__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Gnome::Sound - Perl extension for libgnome/gnome-sound (GNOME 1.x)

=head1 SYNOPSIS

  use Gnome::Sound;
  use Gnome;

  Gnome->init($PACKAGE, $VERSION);

  Gnome::Sound::init($hostname);
  $sample_id = Gnome::Sound::sample_load($sample_name, $filename);
  Gnome::Sound::play($filename);
  Gnome::Sound::shutdown();

=head1 DESCRIPTION

This module is a Perl interface to gnome-sound, which provides sound playing
routines for GNOME applications (http://www.gnome.org).
These routines make use of the esd sound daemon.

It is important to note that Gnome->init( ) must be called before using these
functions.

=over 4

=item Gnome::Sound::init( HOSTNAME );

This initializes a connection to the esd sound server on HOSTNAME.
This function must be called before using any other functions from this module.
HOSTNAME is a string, or scalar containing a string, and will usually
be 'localhost'.

=item Gnome::Sound::shutdown( );

Shuts down the connection to the sound server.
This function must be called before the end of your program.

=item Gnome::Sound::sample_load( SAMPLE_NAME, FILENAME );

Loads sound file, FILENAME, into an esound sample with the name SAMPLE_NAME.
Both SAMPLE_NAME and FILENAME are strings.
Returns the esound numeric ID of the sample, or a negative number otherwise.

=item Gnome::Sound::play( FILENAME );

Plays the sound file FILENAME.  This is a convenient wrapper around a number
of esd functions, as will probably be the most used function.

=back

=head1 SEE ALSO

Gnome

=head1 AUTHOR

Mark A. Stratman <mark@sporkstorms.org>

=head1 COPYRIGHT

Copyright (c) 2001, Mark Stratman.  All Rights Reserved.
This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

The GNOME libraries (libgnome) are released under the LGPL (Library General
Public License). Visit http://www.gnu.org for more details.

=cut

