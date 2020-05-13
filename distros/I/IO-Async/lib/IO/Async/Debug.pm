#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015 -- leonerd@leonerd.org.uk

package IO::Async::Debug;

use strict;
use warnings;

our $VERSION = '0.77';

our $DEBUG = $ENV{IO_ASYNC_DEBUG} || 0;
our $DEBUG_FD   = $ENV{IO_ASYNC_DEBUG_FD};
our $DEBUG_FILE = $ENV{IO_ASYNC_DEBUG_FILE};
our $DEBUG_FH;
our %DEBUG_FLAGS = map { $_ => 1 } split m/,/, $ENV{IO_ASYNC_DEBUG_FLAGS} || "";

=head1 NAME

C<IO::Async::Debug> - debugging control and support for L<IO::Async>

=head1 DESCRIPTION

The following methods and behaviours are still experimental and may change or
even be removed in future.

Debugging support is enabled by an environment variable called
C<IO_ASYNC_DEBUG> having a true value.

When debugging is enabled, the C<make_event_cb> and C<invoke_event> methods
on L<IO::Async::Notifier> (and their C<maybe_> variants) are altered such that
when the event is fired, a debugging line is printed, using the C<debug_printf>
method. This identifes the name of the event.

By default, the line is only printed if the caller of one of these methods is
the same package as the object is blessed into, allowing it to print the
events of the most-derived class, without the extra verbosity of the
lower-level events of its parent class used to create it. All calls regardless
of caller can be printed by setting a number greater than 1 as the value of
C<IO_ASYNC_DEBUG>.

By default the debugging log goes to C<STDERR>, but two other environment
variables can redirect it. If C<IO_ASYNC_DEBUG_FILE> is set, it names a file
which will be opened for writing, and logging written into it. Otherwise, if
C<IO_ASYNC_DEBUG_FD> is set, it gives a file descriptor number that logging
should be written to. If opening the named file or file descriptor fails then
the log will be written to C<STDERR> as normal.

Extra debugging flags can be set in a comma-separated list in an environment
variable called C<IO_ASYNC_DEBUG_FLAGS>. The presence of these flags can cause
extra information to be written to the log. Full details on these flags will
be documented by the implementing classes. Typically these flags take the form
of one or more capital letters indicating the class, followed by one or more
lowercase letters enabling some particular feature within that class.

=cut

sub logf
{
   my ( $fmt, @args ) = @_;

   $DEBUG_FH ||= do {
      my $fh;
      if( $DEBUG_FILE ) {
         open $fh, ">", $DEBUG_FILE or undef $fh;
      }
      elsif( $DEBUG_FD ) {
         $fh = IO::Handle->new;
         $fh->fdopen( $DEBUG_FD, "w" ) or undef $fh;
      }
      $fh ||= \*STDERR;
      $fh->autoflush;
      $fh;
   };

   printf $DEBUG_FH $fmt, @args;
}

sub log_hexdump
{
   my ( $bytes ) = @_;

   foreach my $chunk ( $bytes =~ m/(.{1,16})/sg ) {
      my $chunk_hex = join " ", map { sprintf "%02X", ord $_ } split //, $chunk;
      ( my $chunk_safe = $chunk ) =~ s/[^\x20-\x7e]/./g;

      logf "  | %-48s | %-16s |\n", $chunk_hex, $chunk_safe;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
