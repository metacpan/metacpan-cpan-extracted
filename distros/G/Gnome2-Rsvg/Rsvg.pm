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
our $VERSION = '0.12';

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

Gnome2::Rsvg -> bootstrap($VERSION);

1;
__END__

=head1 NAME

Gnome2::Rsvg - (DEPRECATED) Perl interface to the RSVG library

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

B<DEPRECATED> This module allows a Perl developer to use the Scalable Vector
Graphics library (librsvg for short).

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

Perl URL: https://gitlab.gnome.org/GNOME/perl-gnome2-rsvg

=item *

Upstream URL: https://gitlab.gnome.org/GNOME/librsvg

=item *

Last compatible upstream version: 2.32.1

=item *

Last compatible upstream release date: 2010-11-13

=item *

Migration path for this module: G:O:I

=item *

Migration module URL: https://metacpan.org/pod/Glib::Object::Introspection

=back

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>

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
License along with this library; if not, see
<https://www.gnu.org/licenses/>.

=cut
