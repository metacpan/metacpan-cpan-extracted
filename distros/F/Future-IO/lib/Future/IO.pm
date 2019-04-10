#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package Future::IO;

use strict;
use warnings;

our $VERSION = '0.02';

use Carp;

# These need to be visible to sub override_impl
my @alarms;
my @readers;

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
C<sysread> calls on a single filehandle only, combined with C<sleep> calls.
It is provided for the simple cases where modules only need one filehandle
(most likely a single network socket or hardware device handle), allowing such
modules to work without needing a better event system.

If there are both C<sysread> and C<sleep> futures pending, the implementation
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

   return ( $IMPL //= "Future::IO::_Impl" )->sleep( $secs );
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

   return ( $IMPL //= "Future::IO::_Impl" )->sysread( $fh, $length );
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
   Future::IO::_Impl;
use base qw( Future );
use Carp;

use Errno qw( EAGAIN EWOULDBLOCK );
use Struct::Dumb qw( readonly_struct );
use Time::HiRes qw( time );

readonly_struct Alarm => [qw( time f )];

readonly_struct Reader => [qw( fh length f )];

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

   my $rvec = '';
   vec( $rvec, $readers[0]->fh->fileno, 1 ) = 1 if @readers;

   my $maxwait;
   $maxwait = $alarms[0]->time - time() if @alarms;

   die "Cowardly refusing to sit idle and do nothing" unless length $rvec or defined $maxwait;

   my $ret = ( defined $maxwait ) ?
      select( $rvec, undef, undef, $maxwait ) :
      1;

   if( $ret and @readers ) {
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

   my $now = time();
   while( @alarms and $alarms[0]->time <= $now ) {
      ( shift @alarms )->f->done;
   }
}

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

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
