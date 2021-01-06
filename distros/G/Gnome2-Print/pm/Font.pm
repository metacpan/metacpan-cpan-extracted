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

Gnome2::Print::Font::Constants

=head1 SYNOPSIS

  use Gnome2::Print; # gets the actual Gnome2::Print::Font objects and methods

  use Gnome2::Print::Font::Constants; # load extra constants

=head1 ABSTRACT

B<DEPRECATED> Constants for use with Gnome2::Print::Font

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

Perl URL: https://gitlab.gnome.org/GNOME/perl-gnome2-print

=item *

Upstream URL: https://gitlab.gnome.org/Archive/libgnomeprint

=item *

Last upstream version: 2.18.8

=item *

Last upstream release date: 2010-09-28

=item *

Migration path for this module: Gtk3::Print*

=item *

Migration module URL: https://metacpan.org/pod/Gtk3

=back

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>


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
License along with this library; if not, see
<https://www.gnu.org/licenses/>.

=cut
