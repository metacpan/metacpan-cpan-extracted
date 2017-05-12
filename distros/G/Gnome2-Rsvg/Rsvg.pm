package Gnome2::Rsvg;

use 5.008;
use strict;
use warnings;


# If librsvg-2.0 >= 2.14, we need Cairo.  Gtk2 may or may not load Cairo for,
# so better do it here.
eval "use Cairo;";

use Glib;
use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);
our $VERSION = '0.11';

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

Gnome2::Rsvg -> bootstrap($VERSION);

1;
__END__

=head1 NAME

Gnome2::Rsvg - Perl interface to the RSVG library

=head1 SYNOPSIS

  use Gnome2::Rsvg;

  my $svg = "path/to/image.svg";

  # The easy way.
  my $pixbuf = Gnome2::Rsvg -> pixbuf_from_file($svg);

  # The harder way.
  my $handle = Gnome2::Rsvg::Handle -> new();

  open(SVG, $svg) or die("Opening '$svg': $!");

  while (<SVG>) {
    $handle -> write($_) or die("Could not parse '$svg'");
  }

  close(SVG);

  $handle -> close() or die("Could not parse '$svg'");

  $pixbuf = $handle -> get_pixbuf();

=head1 ABSTRACT

This module allows a Perl developer to use the Scalable Vector Graphics library
(librsvg for short).

=head1 SEE ALSO

L<Gnome2::Rsvg::index>(3pm), L<Gtk2>(3pm), L<Gtk2::api>(3pm) and
L<http://librsvg.sourceforge.net/docs/html/index.html>

=head1 AUTHOR

Torsten Schoenfeld E<lt>kaffeetisch at gmx dot deE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2005, 2010  Torsten Schoenfeld

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
