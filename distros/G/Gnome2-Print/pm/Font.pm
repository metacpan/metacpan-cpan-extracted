package Gnome2::Print::Font::Constants;

use strict;
require Exporter;

our @ISA = qw/Exporter/;

our @EXPORT = qw(
	GNOME_FONT_LIGHTEST
	GNOME_FONT_EXTRA_LIGHT
	GNOME_FONT_THIN
	GNOME_FONT_LIGHT
	GNOME_FONT_BOOK
	GNOME_FONT_REGULAR
	GNOME_FONT_MEDIUM
	GNOME_FONT_SEMI
	GNOME_FONT_DEMI
	GNOME_FONT_BOLD
	GNOME_FONT_HEAVY
	GNOME_FONT_EXTRABOLD
	GNOME_FONT_BLACK
	GNOME_FONT_EXTRABLACK
	GNOME_FONT_HEAVIEST
);

use constant GNOME_FONT_LIGHTEST => 100;
use constant GNOME_FONT_EXTRA_LIGHT => 100;
use constant GNOME_FONT_THIN => 200;
use constant GNOME_FONT_LIGHT => 300;
use constant GNOME_FONT_BOOK => 400;
use constant GNOME_FONT_REGULAR => 400;
use constant GNOME_FONT_MEDIUM => 500;
use constant GNOME_FONT_SEMI => 600;
use constant GNOME_FONT_DEMI => 600;
use constant GNOME_FONT_BOLD => 700;
use constant GNOME_FONT_HEAVY => 900;
use constant GNOME_FONT_EXTRABOLD => 900;
use constant GNOME_FONT_BLACK => 1000;
use constant GNOME_FONT_EXTRABLACK => 1100;
use constant GNOME_FONT_HEAVIEST => 1100;

1;

=head1 NAME

Gnome2::Print::Font::Constants - constants for use with Gnom2::Print::Font

=head1 SYNOPSIS

  use Gnome2::Print; # gets the actual Gnome2::Print::Font objects and methods

  use Gnome2::Print::Font::Constants; # load extra constants

=head1 DESCRIPTION

Similarily to Pango, in order to effectively use Gnome2::Print::Font you need
a few constants that are not supplied by the type system or by other means.

This module exports all of those extra constants when you load it.
They use the fully-prefixed names from the C documentation.

=head1 EXPORT

GnomeFontWeight is an enumeration, but it's not registered inside the Glib
type system:

  GNOME_FONT_LIGHTEST
  GNOME_FONT_EXTRA_LIGHT
  GNOME_FONT_THIN
  GNOME_FONT_LIGHT
  GNOME_FONT_BOOK
  GNOME_FONT_REGULAR
  GNOME_FONT_MEDIUM
  GNOME_FONT_SEMI
  GNOME_FONT_DEMI
  GNOME_FONT_BOLD
  GNOME_FONT_HEAVY
  GNOME_FONT_EXTRABOLD
  GNOME_FONT_BLACK
  GNOME_FONT_EXTRABLACK
  GNOME_FONT_HEAVIEST

These weights are also available without importing this module, using
Gnome2::Print::Font-E<gt>I<weight>, e.g.:

  Gnome2::Print::Font->bold;

=head1 BUGS

This module shouldn't exist, but some parts of the API just aren't clean.

This stuff is hardcoded directly from the headers of libgnomeprint 2.2.3

=head1 SEE ALSO

perl(1), Gtk2(3pm), Gnome2(3pm), Gnome2::Print(3pm).

=head1 AUTHOR

Emmanuele Bassi E<lt>emmanuele.bassi@iol.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Emmanuele Bassi

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
