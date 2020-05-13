#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2007-2015 -- leonerd@leonerd.org.uk

package IO::Async::Test;

use strict;
use warnings;

our $VERSION = '0.77';

use Exporter 'import';
our @EXPORT = qw(
   testing_loop
   wait_for
   wait_for_stream
   wait_for_future
);

=head1 NAME

C<IO::Async::Test> - utility functions for use in test scripts

=head1 SYNOPSIS

 use Test::More tests => 1;
 use IO::Async::Test;

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;
 testing_loop( $loop );

 my $result;

 $loop->do_something( 
    some => args,

    on_done => sub {
       $result = the_outcome;
    }
 );

 wait_for { defined $result };

 is( $result, what_we_expected, 'The event happened' );

 ...

 my $buffer = "";
 my $handle = IO::Handle-> ...

 wait_for_stream { length $buffer >= 10 } $handle => $buffer;

 is( substr( $buffer, 0, 10, "" ), "0123456789", 'Buffer was correct' );

 my $result = wait_for_future( $stream->read_until( "\n" ) )->get;

=head1 DESCRIPTION

This module provides utility functions that may be useful when writing test
scripts for code which uses L<IO::Async> (as well as being used in the
L<IO::Async> test scripts themselves).

Test scripts are often synchronous by nature; they are a linear sequence of
actions to perform, interspersed with assertions which check for given
conditions. This goes against the very nature of L<IO::Async> which, being an
asynchronisation framework, does not provide a linear stepped way of working.

In order to write a test, the C<wait_for> function provides a way of
synchronising the code, so that a given condition is known to hold, which
would typically signify that some event has occurred, the outcome of which can
now be tested using the usual testing primitives.

Because the primary purpose of L<IO::Async> is to provide IO operations on
filehandles, a great many tests will likely be based around connected pipes or
socket handles. The C<wait_for_stream> function provides a convenient way
to wait for some content to be written through such a connected stream.

=cut

my $loop;
END { undef $loop }

=head1 FUNCTIONS

=cut

=head2 testing_loop

   testing_loop( $loop )

Set the L<IO::Async::Loop> object which the C<wait_for> function will loop
on.

=cut

sub testing_loop
{
   $loop = shift;
}

=head2 wait_for

   wait_for { COND } OPTS

Repeatedly call the C<loop_once> method on the underlying loop (given to the
C<testing_loop> function), until the given condition function callback
returns true.

To guard against stalled scripts, if the loop indicates a timeout for (a
default of) 10 consequentive seconds, then an error is thrown.

Takes the following named options:

=over 4

=item timeout => NUM

The time in seconds to wait before giving up the test as being stalled.
Defaults to 10 seconds.

=back

=cut

sub wait_for(&@)
{
   my ( $cond, %opts ) = @_;

   my ( undef, $callerfile, $callerline ) = caller;

   my $timedout = 0;
   my $timerid = $loop->watch_time(
      after => $opts{timeout} // 10,
      code => sub { $timedout = 1 },
   );

   $loop->loop_once( 1 ) while !$cond->() and !$timedout;

   if( $timedout ) {
      die "Nothing was ready after 10 second wait; called at $callerfile line $callerline\n";
   }
   else {
      $loop->unwatch_time( $timerid );
   }
}

=head2 wait_for_stream

   wait_for_stream { COND } $handle, $buffer

As C<wait_for>, but will also watch the given IO handle for readability, and
whenever it is readable will read bytes in from it into the given buffer. The
buffer is NOT initialised when the function is entered, in case data remains
from a previous call.

C<$buffer> can also be a CODE reference, in which case it will be invoked
being passed data read from the handle, whenever it is readable.

=cut

sub wait_for_stream(&$$)
{
   my ( $cond, $handle, undef ) = @_;

   my $on_read;
   if( ref $_[2] eq "CODE" ) {
      $on_read = $_[2];
   }
   else {
      my $varref = \$_[2];
      $on_read = sub { $$varref .= $_[0] };
   }

   $loop->watch_io(
      handle => $handle,
      on_read_ready => sub {
         my $ret = $handle->sysread( my $buffer, 8192 );
         if( !defined $ret ) {
            die "Read failed on $handle - $!\n";
         }
         elsif( $ret == 0 ) {
            die "Read returned EOF on $handle\n";
         }
         $on_read->( $buffer );
      }
   );

   # Have to defeat the prototype... grr I hate these
   &wait_for( $cond );

   $loop->unwatch_io(
      handle => $handle,
      on_read_ready => 1,
   );
}

=head2 wait_for_future

   $future = wait_for_future $future

I<Since version 0.68.>

A handy wrapper around using C<wait_for> to wait for a L<Future> to become
ready. The future instance itself is returned, allowing neater code.

=cut

sub wait_for_future
{
   my ( $future ) = @_;

   wait_for { $future->is_ready };

   return $future;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
