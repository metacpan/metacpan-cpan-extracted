#! perl

package EekBoek;

# NOTE: This is a documentation-only module.

use strict;
use utf8;

# Minimal version to prevent many Unicode bugs.
use 5.008003;

require EB::Version;

our $PACKAGE = 'EekBoek';

our $VERSION = $EB::Version::VERSION;

=head1 NAME

EekBoek - Bookkeeping software for small and medium-size businesses

=head1 SYNOPSIS

EekBoek is a bookkeeping package for small and medium-size businesses.
Unlike other accounting software, EekBoek has both a command-line
interface (CLI) and a graphical user-interface (GUI). Furthermore, it
has a complete Perl API to create your own custom applications.

EekBoek is designed for the Dutch/European market and currently
available in Dutch only. An English translation is in the works (help
appreciated).

=head1 DESCRIPTION

For a description how to use the program, see L<http://www.eekboek.nl/docs/index.html>.

=head1 BUGS AND PROBLEMS

Please use the eekboek-users mailing list at SourceForge.

=head1 AUTHOR AND CREDITS

Johan Vromans (jvromans@squirrel.nl) wrote this module.

Web site: L<http://www.eekboek.nl>.

=head1 COPYRIGHT AND DISCLAIMER

This program is Copyright 2005-2011 by Squirrel Consultancy. All
rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either: a) the GNU General Public License as
published by the Free Software Foundation; either version 1, or (at
your option) any later version, or b) the "Artistic License" which
comes with Perl.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See either the
GNU General Public License or the Artistic License for more details.

=cut

1;
