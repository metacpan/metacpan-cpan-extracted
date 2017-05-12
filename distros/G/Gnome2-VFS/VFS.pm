# $Id$

package Gnome2::VFS;

use 5.008;
use strict;
use warnings;

use Glib;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT_OK = qw(
  GNOME_VFS_PRIORITY_MIN
  GNOME_VFS_PRIORITY_MAX
  GNOME_VFS_PRIORITY_DEFAULT
  GNOME_VFS_SIZE_FORMAT_STR
  GNOME_VFS_OFFSET_FORMAT_STR
  GNOME_VFS_MIME_TYPE_UNKNOWN
  GNOME_VFS_URI_MAGIC_STR
  GNOME_VFS_URI_PATH_STR
);

# --------------------------------------------------------------------------- #

our $VERSION = '1.083';

sub import {
  my ($self) = @_;
  my @symbols = ();

  foreach (@_) {
    if (/^-?init$/) {
      $self -> init();
    } else {
      push @symbols, $_;
    }
  }

  Gnome2::VFS -> export_to_level(1, @symbols);
}

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

Gnome2::VFS -> bootstrap($VERSION);

# --------------------------------------------------------------------------- #

use constant GNOME_VFS_PRIORITY_MIN => -10;
use constant GNOME_VFS_PRIORITY_MAX => 10;
use constant GNOME_VFS_PRIORITY_DEFAULT => 0;

use constant GNOME_VFS_SIZE_FORMAT_STR => "Lu";
use constant GNOME_VFS_OFFSET_FORMAT_STR => "Ld";

use constant GNOME_VFS_MIME_TYPE_UNKNOWN => "application/octet-stream";

use constant GNOME_VFS_URI_MAGIC_STR => "#";
use constant GNOME_VFS_URI_PATH_STR => "/";

1;

# --------------------------------------------------------------------------- #

__END__

=head1 NAME

Gnome2::VFS - Perl interface to the 2.x series of the GNOME VFS library

=head1 SYNOPSIS

  use Gnome2::VFS;

  sub die_already {
    my ($action) = @_;
    die("An error occured while $action.\n");
  }

  die_already("initializing GNOME VFS") unless (Gnome2::VFS -> init());

  my $source = "http://www.perldoc.com/about.html";
  my ($result, $handle, $info);

  # Open a connection to Perldoc.
  ($result, $handle) = Gnome2::VFS -> open($source, "read");
  die_already("opening connection to '$source'")
    unless ($result eq "ok");

  # Get the file information.
  ($result, $info) = $handle -> get_file_info("default");
  die_already("retrieving information about '$source'")
    unless ($result eq "ok");

  # Read the content.
  my $bytes = $info -> { size };

  my $bytes_read = 0;
  my $buffer = "";

  do {
    my ($tmp_buffer, $tmp_bytes_read);

    ($result, $tmp_bytes_read, $tmp_buffer) =
      $handle -> read($bytes - $bytes_read);

    $buffer .= $tmp_buffer;
    $bytes_read += $tmp_bytes_read;
  } while ($result eq "ok" and $bytes_read < $bytes);

  die_already("reading $bytes bytes from '$source'")
    unless ($result eq "ok" && $bytes_read == $bytes);

  # Close the connection.
  $result = $handle -> close();
  die_already("closing connection to '$source'")
    unless ($result eq "ok");

  # Create and open the target.
  my $target = "/tmp/" . $info -> { name };
  my $uri = Gnome2::VFS::URI -> new($target);

  ($result, $handle) = $uri -> create("write", 1, 0644);
  die_already("creating '$target'") unless ($result eq "ok");

  # Write to it.
  my $bytes_written;

  ($result, $bytes_written) = $handle -> write($buffer, $bytes);
  die_already("writing $bytes bytes to '$target'")
    unless ($result eq "ok" && $bytes_written == $bytes);

  # Close the target.
  $result = $handle -> close();
  die_already("closing '$target'") unless ($result eq "ok");

  Gnome2::VFS -> shutdown();

=head1 ABSTRACT

This module allows you to interface with the GNOME Virtual File System library.
It provides the means to transparently access files on all kinds of
filesystems.

=head1 DESCRIPTION

Since this module tries to stick very closely to the C API, the documentation
found at

  L<http://developer.gnome.org/doc/API/2.0/gnome-vfs-2.0/>

is the canonical reference.

In addition to that, there's also the automatically generated API
documentation: L<Gnome2::VFS::index>.

The mapping described in L<Gtk2::api> also applies to this module.

To discuss this module, ask questions and flame/praise the authors, join
gtk-perl-list@gnome.org at lists.gnome.org.

=head1 KNOWN BUGS

There are some memory leaks especially with respect to callbacks.  This mainly
affects GnomeVFSAsync as well as some parts of GnomeVFSXfer and GnomeVFSOps.
GnomeVFSMime leaks some list data.

GnomeVFSAsync is also known to crash under certain conditions when there are
many concurrent transfers.

=head1 SEE ALSO

L<Gnome2::VFS::index>, L<Glib>, L<Gtk2>, L<Gtk2::api>.

=head1 AUTHOR

Torsten Schoenfeld E<lt>kaffeetisch@web.deE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2007 by the gtk2-perl team (see the file AUTHORS)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
details.

You should have received a copy of the GNU Lesser General Public License along
with this library; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

=cut
