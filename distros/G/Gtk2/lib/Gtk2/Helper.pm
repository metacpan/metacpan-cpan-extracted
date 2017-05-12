#
# $Id$
#

package Gtk2::Helper;

our $VERSION = '0.02';

use Carp;
use strict;

use Glib;

sub add_watch {
	shift; # lose the class
	my ($fd, $cond, $callback, $data) = @_;

	# map 'in' and 'out' to GIO enums
	$cond = $cond eq 'in'  ? 'G_IO_IN'  :
		$cond eq 'out' ? 'G_IO_OUT' :
		croak "Invalid condition flag. Expecting: 'in' / 'out'";

	# In Gtk 1.x the callback was called also for the eof() / pipe close
	# events, but Gtk 2.x doesn't. We need to connect to the G_IO_HUP
	# event also to get this convenient behaviour again.

	my $tag = {
		io_id  => Glib::IO->add_watch ($fd, $cond, $callback, $data),
		hup_id => Glib::IO->add_watch ($fd, 'G_IO_HUP', $callback, $data),
	};

	return $tag;
}

sub remove_watch {
	shift; # lose the class
	my ($tag) = @_;

	my $rc_io  = Glib::Source->remove ($tag->{io_id});
	my $rc_hup = Glib::Source->remove ($tag->{hup_id});
	
	return ($rc_io && $rc_hup);
}

1;

__END__

=head1 NAME

Gtk2::Helper - Convenience functions for the Gtk2 module

=head1 SYNOPSIS

  use Gtk2::Helper;

  # Handle I/O watchers easily, like Gtk 1.x did
  $tag = Gtk2::Helper->add_watch ( $fd, $cond, $callback, $data )
  $rc  = Gtk2::Helper->remove_watch ( $tag )

=head1 ABSTRACT

This module collects Gtk2 helper functions, which should make
implementing some common tasks easier.

=head1 DESCRIPTION

=head2 Gtk2::Helper->add_watch ( ... )

  $tag = Gtk2::Helper->add_watch ( $fd, $cond, $callback, $data )

This method is a wrapper for Glib::IO->add_watch. The callback is
called every time when it's safe to read from or write to the
watched filehandle.

=over 4

=item $fd

Unix file descriptor to be watched. If you use the FileHandle
module you get this value from the FileHandle->fileno() method.

=item $cond

May be either 'in' or 'out', depending if you want to read from
the filehandle ('in') or write to it ('out').

=item $callback

A subroutine reference or closure, which is called, if you can safely
operate on the filehandle, without the risk of blocking your application,
because the filehandle is not ready for reading resp. writing.

But aware: you should not use Perl's builtin read and write functions here
because these operate always with buffered I/O. Use low level sysread() and
syswrite() instead. Otherwise Perl may read more data into its internal
buffer as your callback actually consumes. But Glib won't call the callback
on data which is already in Perl's buffer, only when events on the
the underlying Unix file descriptor occur.

The callback subroutine should return always true. Two signal
watchers are connected internally (the I/O watcher, and a HUP
watcher, which is called on eof() or other exceptions). Returning
false from a watcher callback, removes the correspondent watcher
automatically. Because we have two watchers internally, only one
of them is removed, but probably not both. So always return true
and use Gtk2::Helper->remove_watch to disable a watcher, which was
installed with Gtk2::Helper->add_watch.

(Gtk2::Helper could circumvent this by wrapping your callback
with a closure returning always true. But why adding another level
of indirection if writing a simple "1;" at the end of your callback
solves this problem? ;)

=item $data

This data is passed to the callback.

=item $tag

The method returns a tag which represents the created watcher.
Later you need to pass this tag to Gtk2::Helper->remove_watch to
remove the watcher.

=back

B<Example:>

  # open a pipe to a ls command
  use FileHandle;
  my $fh = FileHandle->new;
  open ($fh, "ls -l |") or die "can't fork";

  # install a read watcher for this pipe
  my $tag;
  $tag = Gtk2::Helper->add_watch ( $fh->fileno, 'in', sub {
    watcher_callback( $fh, $tag );
  });

  sub watcher_callback {
      my ($fh, $tag) = @_;

      # we safely can read a chunk into $buffer
      my $buffer;

      if ( not sysread($fh, $buffer, 4096) ) {
        # obviously the connected pipe was closed
        Gtk2::Helper->remove_watch ($tag)
	    or die "couldn't remove watcher";
	close($fh);
	return 1;
      }

      # do something with $buffer ...
      print $buffer;

      # *always* return true
      return 1;
  }

=head2 Gtk2::Helper->remove_watch ( ... )

  $rc = Gtk2::Helper->remove_watch ( $tag )

This method removes a watcher, which was created using
Gtk2::Helper->add_watch().

=over 4

=item $tag

This is the tag returned from Gtk2::Helper->add_watch().

=item $rc

The method returns true, if the watcher could be removed
successfully, and false if not.

=back

=head1 SEE ALSO

perl(1), Gtk2(1)

=head1 AUTHOR

=encoding utf8

Jörn Reder E<lt>joern AT zyn.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Jörn Reder

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
