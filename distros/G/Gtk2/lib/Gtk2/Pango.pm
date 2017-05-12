#
# $Id$
#

package Gtk2::Pango;

our $VERSION = '0.01';

use strict;
require Exporter;

our @ISA = qw/Exporter/;

our @EXPORT = qw(
	PANGO_WEIGHT_ULTRALIGHT
	PANGO_WEIGHT_LIGHT
	PANGO_WEIGHT_NORMAL
	PANGO_WEIGHT_BOLD
	PANGO_WEIGHT_ULTRABOLD
	PANGO_WEIGHT_HEAVY

	PANGO_SCALE_XX_SMALL
	PANGO_SCALE_X_SMALL
	PANGO_SCALE_SMALL
	PANGO_SCALE_MEDIUM
	PANGO_SCALE_LARGE
	PANGO_SCALE_X_LARGE
	PANGO_SCALE_XX_LARGE

	PANGO_SCALE
);

use constant PANGO_WEIGHT_ULTRALIGHT => 200;
use constant PANGO_WEIGHT_LIGHT      => 300;
use constant PANGO_WEIGHT_NORMAL     => 400;
use constant PANGO_WEIGHT_BOLD       => 700;
use constant PANGO_WEIGHT_ULTRABOLD  => 800;
use constant PANGO_WEIGHT_HEAVY      => 900;

use constant PANGO_SCALE_XX_SMALL => 0.5787037037037;
use constant PANGO_SCALE_X_SMALL  => 0.6444444444444;
use constant PANGO_SCALE_SMALL    => 0.8333333333333;
use constant PANGO_SCALE_MEDIUM   => 1.0;
use constant PANGO_SCALE_LARGE    => 1.2;
use constant PANGO_SCALE_X_LARGE  => 1.4399999999999;
use constant PANGO_SCALE_XX_LARGE => 1.728;

use constant PANGO_SCALE => 1024;

1;

=head1 NAME

Gtk2::Pango - constants for use with Pango

=head1 SYNOPSIS

  use Gtk2; # gets the actual Pango objects and methods

  use Gtk2::Pango; # load extra constants

=head1 DESCRIPTION

To use Pango effectively, you need a few extra constants that are not
supplied in normal ways by the type system or by other means.

This module exports all of those extra constants when you load it.
They use the fully-prefixed names from the C documentation.

=head1 EXPORT

PangoWeight is indeed defined as an enumerated type whose values can be
used as nickname strings in the perl bindings, but in several places 
where a weight is needed, a gint is requested instead.  This is because
PangoWeight is actually just a set of predefined values for an integer-valued
property.  The PANGO_WEIGHT_* constants give you the predefined values:

	PANGO_WEIGHT_ULTRALIGHT
	PANGO_WEIGHT_LIGHT
	PANGO_WEIGHT_NORMAL
	PANGO_WEIGHT_BOLD
	PANGO_WEIGHT_ULTRABOLD
	PANGO_WEIGHT_HEAVY

These are #defined in the C source, and thus are not available anywhere
except here:

	PANGO_SCALE_XX_SMALL
	PANGO_SCALE_X_SMALL
	PANGO_SCALE_SMALL
	PANGO_SCALE_MEDIUM
	PANGO_SCALE_LARGE
	PANGO_SCALE_X_LARGE
	PANGO_SCALE_XX_LARGE

PANGO_SCALE is needed to convert between Pango units and pixels.
It is also available as Gtk2::Pango->scale.

	PANGO_SCALE

=head1 BUGS

This module shouldn't exist, but some parts of the API just aren't clean.

This stuff is hardcoded directly from the headers of pango 1.2.1.

=head1 SEE ALSO

L<perl>(1), L<Gtk2>(3pm)

=head1 AUTHOR

muppet E<lt>scott AT asofyet.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by muppet

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the 
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
Boston, MA  02110-1301  USA.

=cut
