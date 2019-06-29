#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package Future::IO;

use strict;
use warnings;
use 5.010;  # //

our $VERSION = '0.06';

use Carp;

# These need to be visible to sub override_impl
my @alarms;
my @readers;
my @writers;

our $IMPL;

=head1 NAME

C<Future::IO> - Future-returning IO methods

=head1 SYNOPSIS

   use Future::IO;

   my $delay = Future::IO->sleep( 5 );
   # $delay will become done in 5 seconds time

   my $input = Future::IO->sysread( \*STDIN, 4096 );
   # $input will yield some input from the STDIN IO handle

=head1 DESCRIPTION

This package provides a few basic methods that behave similarly to the
same-named core perl functions relating to IO operations, but yield their
results asynchronously via L<Future> instances.

This is provided primarily as a decoupling mechanism, to allow modules to be
written that perform IO in an asynchronous manner to depend directly on this,
while allowing asynchronous event systems to provide an implementation of
these operations.

=head2 Default Implementation

If the C<override_impl> method is not invoked, a default implementation of
these operations is provided. This implementation allows a single queue of
C<sysread> or C<syswrite> calls on a single filehandle only, combined with
C<sleep> calls. It is provided for the simple cases where modules only need
one filehandle (most likely a single network socket or hardware device
handle), allowing such modules to work without needing a better event system.

If there are both read/write and C<sleep> futures pending, the implementation
will use C<select()> to wait for either. This may be problematic on MSWin32,
depending on what type of filehandle is involved.

For cases where multiple filehandles are required, or for doing more involved
IO operations, a real implementation based on an actual event loop should be
provided.

=head2 Unit Testing

The replaceable implementation is also useful for writing unit test scripts.
If the implementation is set to an instance of some sort of test fixture or
mocking object, a unit test can check that the appropriate IO operations
happen as part of the test.

=cut

=head1 METHODS

=cut

=head2 sleep

   $f = Future::IO->sleep( $secs )

Returns a L<Future> that will become done a fixed delay from now, given in
seconds. This value may be fractional.

=cut

sub sleep
{
   shift;
   my ( $secs ) = @_;

   return ( $IMPL //= "Future::IO::_DefaultImpl" )->sleep( $secs );
}

=head2 sysread

   $f = Future::IO->sysread( $fh, $length )
      $bytes = $f->get

Returns a L<Future> that will become done when at least one byte can be read
from the given filehandle. It may return up to C<$length> bytes. On EOF, the
returned future will yield an empty list (or C<undef> in scalar context). On
any error (other than C<EAGAIN> / C<EWOULDBLOCK> which are ignored), the
future fails with a suitable error message.

Note specifically this may perform only a single C<sysread()> call, and thus
is not guaranteed to actually return the full length.

=cut

sub sysread
{
   shift;
   my ( $fh, $length ) = @_;

   return ( $IMPL //= "Future::IO::_DefaultImpl" )->sysread( $fh, $length );
}

=head2 sysread_exactly

   $f = Future::IO->sysread_exactly( $fh, $length )
      $bytes = $f->get

I<Since version 0.03.>

Returns a L<Future> that will become done when exactly the given number of
bytes have been read from the given filehandle. It returns exactly C<$length>
bytes. On EOF, the returned future will yield an empty list (or C<undef> in
scalar context), even if fewer bytes have already been obtained. These bytes
will be lost. On any error (other than C<EAGAIN> / C<EWOULDBLOCK> which are
ignored), the future fails with a suitable error message.

This may make more than one C<sysread()> call.

=cut

sub sysread_exactly
{
   shift;
   my ( $fh, $length ) = @_;

   $IMPL //= "Future::IO::_DefaultImpl";

   if( my $code = $IMPL->can( "sysread_exactly" ) ) {
      return $IMPL->$code( $fh, $length );
   }

   return _sysread_into_buffer( $IMPL, $fh, $length, '' );
}

sub _sysread_into_buffer
{
   my ( $IMPL, $fh, $length, $bytes ) = @_;

   $IMPL->sysread( $fh, $length - length $bytes )->then( sub {
      my ( $more ) = @_;
      return Future->done() if !defined $more; # EOF

      $bytes .= $more;

      return Future->done( $bytes ) if length $bytes >= $length;
      return _sysread_into_buffer( $IMPL, $fh, $length, $bytes );
   });
}

=head2 syswrite

   $f = Future::IO->syswrite( $fh, $bytes )
      $written_len = $f->get

I<Since version 0.04.>

Returns a L<Future> that will become done when at least one byte has been
written to the given filehandle. It may write up to all of the bytes. On any
error (other than C<EAGAIN> / C<EWOULDBLOCK> which are ignored) the future
fails with a suitable error message.

Note specifically this may perform only a single C<syswrite()> call, and thus
is not guaranteed to actually return the full length.

=cut

sub syswrite
{
   shift;
   my ( $fh, $bytes ) = @_;

   return ( $IMPL //= "Future::IO::_DefaultImpl" )->syswrite( $fh, $bytes );
}

=head2 syswrite_exactly

   $f = Future::IO->syswrite_exactly( $fh, $bytes )
      $written_len = $f->get;

I<Since version 0.04.>

Returns a L<Future> that will become done when exactly the given bytes have
been written to the given filehandle. On any error (other than C<EAGAIN> /
C<EWOULDBLOCK> which are ignored) the future fails with a suitable error
message.

This may make more than one C<syswrite()> call.

=cut

sub syswrite_exactly
{
   shift;
   my ( $fh, $bytes ) = @_;

   $IMPL //= "Future::IO::_DefaultImpl";

   if( my $code = $IMPL->can( "syswrite_exactly" ) ) {
      return $IMPL->$code( $fh, $bytes );
   }

   return _syswrite_from_buffer( $IMPL, $fh, $bytes, length $bytes );
}

sub _syswrite_from_buffer
{
   my ( $IMPL, $fh, $bytes, $len ) = @_;

   $IMPL->syswrite( $fh, $bytes )->then( sub {
      my ( $written_len ) = @_;
      substr $bytes, 0, $written_len, "";

      return Future->done( $len ) if !length $bytes;
      return _syswrite_from_buffer( $IMPL, $fh, $bytes, $len );
   });
}

=head2 override_impl

   Future::IO->override_impl( $impl )

Sets a new implementation for C<Future::IO>, replacing the minimal default
internal implementation. This can either be a package name or an object
instance reference, but must provide the methods named above.

This method is intended to be called by event loops and other similar places,
to provide a better integration. Another way, which doesn't involve directly
depending on C<Future::IO> or loading it, is to use the C<$IMPL> variable; see
below.

Can only be called once, and only if the default implementation is not in use,
therefore a module that wishes to override this ought to invoke it as soon as
possible on program startup, before any of the main C<Future::IO> methods may
have been called.

=cut

my $overridden;

sub override_impl
{
   shift;
   croak "Future::IO implementation is already overridden" if defined $IMPL;
   croak "Future::IO implementation cannot be set once default is already in use"
      if @alarms or @readers;

   ( $IMPL ) = @_;
}

package
   Future::IO::_DefaultImpl;
use base qw( Future );
use Carp;

use Errno qw( EAGAIN EWOULDBLOCK );
use Struct::Dumb qw( readonly_struct );
use Time::HiRes qw( time );

readonly_struct Alarm => [qw( time f )];

readonly_struct Reader => [qw( fh length f )];
readonly_struct Writer => [qw( fh bytes f )];

sub sleep
{
   my $class = shift;
   return $class->_done_at( time() + shift );
}

sub sysread
{
   my $class = shift;
   my ( $fh, $length ) = @_;

   croak "This implementation can only cope with a single pending filehandle in ->syread"
      if @readers and $readers[-1]->fh != $fh;

   my $self = $class->new;
   push @readers, Reader( $fh, $length, $self );

   $self->on_cancel( sub {
      my $self = shift;

      my $idx = 0;
      $idx++ while $idx < @readers and $readers[$idx]->f != $self;

      splice @readers, $idx, 1, ();
   });

   return $self;
}

sub syswrite
{
   my $class = shift;
   my ( $fh, $bytes ) = @_;

   croak "This implementation can only cope with a single pending filehandle in ->syswrite"
      if @writers and $writers[-1]->fh != $fh;

   my $self = $class->new;
   push @writers, Writer( $fh, $bytes, $self );

   $self->on_cancel( sub {
      my $self = shift;

      my $idx = 0;
      $idx++ while $idx < @writers and $writers[$idx]->f != $self;

      splice @writers, $idx, 1, ();
   });

   return $self;
}

sub _done_at
{
   my $self = shift->new;
   my ( $time ) = @_;

   # TODO: Binary search
   my $idx = 0;
   $idx++ while $idx < @alarms and $alarms[$idx]->time < $time;

   splice @alarms, $idx, 0, Alarm( $time, $self );

   $self->on_cancel( sub {
      my $self = shift;

      my $idx = 0;
      $idx++ while $idx < @alarms and $alarms[$idx]->f != $self;

      splice @alarms, $idx, 1, ();
   } );

   return $self;
}

sub await
{
   shift;

   die "Cowardly refusing to sit idle and do nothing" unless @alarms || @readers || @writers;

   # If we always select() then problematic platforms like MSWin32 would
   # always break. Instead, we'll only select() if we're waiting on more than
   # one of alarm, reader, writer. If not we'll just presume the one operation
   # we're waiting for is definitely ready right now.

   my $rready;
   my $wready;

   if( @alarms or ( @readers && @writers ) ) {
      my $rvec = '';
      vec( $rvec, $readers[0]->fh->fileno, 1 ) = 1 if @readers;

      my $wvec = '';
      vec( $wvec, $writers[0]->fh->fileno, 1 ) = 1 if @writers;

      my $maxwait;
      $maxwait = $alarms[0]->time - time() if @alarms;

      my $ret = select( $rvec, $wvec, undef, $maxwait );

      $rready = $ret && @readers && vec( $rvec, $readers[0]->fh->fileno, 1 );
      $wready = $ret && @writers && vec( $wvec, $writers[0]->fh->fileno, 1 );
   }
   else {
      $rready = !!@readers;
      $wready = !!@writers;
   }

   if( $rready ) {
      my $r = $readers[0];

      my $len = $r->fh->sysread( my $buf, $r->length );
      if( $len ) {
         shift @readers;
         $r->f->done( $buf );
      }
      elsif( defined $len ) {
         # EOF
         shift @readers;
         $r->f->done();
      }
      elsif( $! == EAGAIN or $! == EWOULDBLOCK ) {
         # ignore it
      }
      else {
         shift @readers;
         $r->f->fail( "sysread: $!\n", sysread => $r->fh, $! );
      }
   }
   if( $wready ) {
      my $w = $writers[0];

      my $len = $w->fh->syswrite( $w->bytes );
      if( $len ) {
         shift @writers;
         $w->f->done( $len );
      }
      elsif( $! == EAGAIN or $! == EWOULDBLOCK ) {
         # ignore it
      }
      else {
         shift @writers;
         $w->f->fail( "syswrite: $!\n", syswrite => $w->fh, $! );
      }
   }

   my $now = time();
   while( @alarms and $alarms[0]->time <= $now ) {
      ( shift @alarms )->f->done;
   }
}

# TODO: Consider implementing the _exactly variants of sysread/syswrite for
#   efficiency

=head1 THE C<$IMPL> VARIABLE

I<Since version 0.02.>

As an alternative to setting an implementation by using L<override_impl>, a
package variable is also available that allows modules such as event systems
to opportunistically provide an implementation without needing to depend on
the module, or loading it C<require>. Simply directly set that package
variable to the name of an implementing package or an object instance.

Additionally, implementors may use a name within the C<Future::IO::Impl::>
namespace, suffixed by the name of their event system.

For example, something like the following code arrangement is recommended.

   package Future::IO::Impl::BananaLoop;

   {
      no warnings 'once';
      ( $Future::IO::IMPL //= __PACKAGE__ ) eq __PACKAGE__ or
         warn "Unable to set Future::IO implementation to " . __PACKAGE__ .
            " as it is already $Future::IO::IMPL\n";
   }

   sub sleep
   {
      ...
   }

   sub sysread
   {
      ...
   }

   sub syswrite
   {
      ...
   }

Optionally, you can also implement L</sysread_exactly> and
L</syswrite_exactly>:

   sub sysread_exactly
   {
      ...
   }

   sub syswrite_exactly
   {
      ...
   }

If not, they will be emulated by C<Future::IO> itself, making multiple calls
to the non-C<_exactly> versions.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
