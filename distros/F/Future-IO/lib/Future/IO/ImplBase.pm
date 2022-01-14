#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019-2021 -- leonerd@leonerd.org.uk

package Future::IO::ImplBase;

use strict;
use warnings;

our $VERSION = '0.11';

use Errno qw( EAGAIN EWOULDBLOCK EINPROGRESS );
use Socket qw( SOL_SOCKET SO_ERROR );

# connect() yields EWOULDBLOCK on MSWin32
use constant CONNECT_EWOULDBLOCK => ( $^O eq "MSWin32" );

use constant HAVE_MULTIPLE_FILEHANDLES => 1;

=head1 NAME

C<Future::IO::ImplBase> - base class for C<Future::IO> implementations

=head1 DESCRIPTION

This package provides a few utility methods that may help writing actual
L<Future::IO> implementation classes. It is entirely optional; implementations
are not required to use it.

=cut

=head1 CLASS METHODS

=cut

=head2 APPLY

   __PACKAGE__->APPLY

Attempts to set the value of the C<$Future::IO::IMPL> variable to the name of
the calling package.

=cut

sub APPLY
{
   my $pkg = shift;

   no warnings 'once';
   ( $Future::IO::IMPL //= $pkg ) eq $pkg or
      warn "Unable to set Future::IO implementation to $pkg".
         " as it is already $Future::IO::IMPL\n";
}

=head1 DEFAULT METHODS

These methods are provided based on lower-level functionallity that the
implementing class should provide.

=cut

=head2 accept

Implemented by wrapping C<ready_for_read>, as L</sysread> uses.

=cut

sub accept
{
   my $self = shift;
   my ( $fh ) = @_;

   return $self->ready_for_read( $fh )->then( sub {
      my $accepted = $fh->accept;
      if( $accepted ) {
         return Future->done( $accepted );
      }
      else {
         return Future->fail( "accept: $!\n", accept => $fh, $! );
      }
   } );
}

=head2 alarm

Implemented by wrapping C<sleep>.

=cut

sub alarm
{
   my $self = shift;
   my ( $time ) = @_;

   return $self->sleep( $time - Time::HiRes::time() );
}

=head2 connect

Implemented by wrapping C<ready_for_write>, as L</syswrite> uses.

=cut

sub connect
{
   my $self = shift;
   my ( $fh, $name ) = @_;

   # We can't use IO::Socket->connect here because
   #   https://github.com/Perl/perl5/issues/19326

   my $ret = CORE::connect( $fh, $name );
   my $errno = $!;

   if( $ret ) {
      return Future->done;
   }
   elsif( $errno != EINPROGRESS and !CONNECT_EWOULDBLOCK || $errno != EWOULDBLOCK ) {
      return Future->fail( "connect: $errno\n", connect => $fh, $errno );
   }

   # not synchronous result

   return $self->ready_for_write( $fh )->then( sub {
      $errno = $fh->getsockopt( SOL_SOCKET, SO_ERROR );

      if( $errno ) {
         $! = $errno;
         return Future->fail( "connect: $!\n", connect => $fh, $! );
      }

      return Future->done;
   } );
}

=head2 sysread

Requires a lower-level method

   $f = $class->ready_for_read( $fh )

which should return a Future that completes when the given filehandle may be
ready for reading.

=cut

sub sysread
{
   my $self = shift;
   my ( $fh, $length ) = @_;

   $self->ready_for_read( $fh )->then( sub {
      my $ret = $fh->sysread( my $buf, $length );
      if( $ret ) {
         return Future->done( $buf );
      }
      elsif( defined $ret ) {
         # EOF
         return Future->done();
      }
      elsif( $! == EAGAIN or $! == EWOULDBLOCK ) {
         # Try again
         return $self->sysread( $fh, $length );
      }
      else {
         return Future->fail( "sysread: $!\n", sysread => $fh, $! );
      }
   });
}

=head2 syswrite

Requires a lower-level method

   $f = $class->ready_for_write( $fh )

which should return a Future that completes when the given filehandle may be
ready for writing.

=cut

sub syswrite
{
   my $self = shift;
   my ( $fh, $data ) = @_;

   return $self->ready_for_write( $fh )->then( sub {
      my $len = $fh->syswrite( $data );
      if( defined $len ) {
         return Future->done( $len );
      }
      elsif( $! == EAGAIN or $! == EWOULDBLOCK ) {
         # Try again
         return $self->syswrite( $fh, $data );
      }
      else {
         return Future->fail( "syswrite: $!\n", syswrite => $fh, $! );
      }
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
