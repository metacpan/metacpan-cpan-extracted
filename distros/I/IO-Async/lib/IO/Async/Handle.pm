#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2006-2019 -- leonerd@leonerd.org.uk

package IO::Async::Handle;

use strict;
use warnings;
use base qw( IO::Async::Notifier );

our $VERSION = '0.77';

use Carp;

use IO::Handle; # give methods to bare IO handles

use Future;
use Future::Utils qw( try_repeat );

use IO::Async::OS;

=head1 NAME

C<IO::Async::Handle> - event callbacks for a non-blocking file descriptor

=head1 SYNOPSIS

This class is likely not to be used directly, because subclasses of it exist
to handle more specific cases. Here is an example of how it would be used to
watch a listening socket for new connections. In real code, it is likely that
the C<< Loop->listen >> method would be used instead.

 use IO::Socket::INET;
 use IO::Async::Handle;

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 my $socket = IO::Socket::INET->new( LocalPort => 1234, Listen => 1 );

 my $handle = IO::Async::Handle->new(
    handle => $socket,

    on_read_ready  => sub {
       my $new_client = $socket->accept; 
       ...
    },
 );

 $loop->add( $handle );

For most other uses with sockets, pipes or other filehandles that carry a byte
stream, the L<IO::Async::Stream> class is likely to be more suitable. For
non-stream sockets, see L<IO::Async::Socket>.

=head1 DESCRIPTION

This subclass of L<IO::Async::Notifier> allows non-blocking IO on filehandles.
It provides event handlers for when the filehandle is read- or write-ready.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 on_read_ready

Invoked when the read handle becomes ready for reading.

=head2 on_write_ready

Invoked when the write handle becomes ready for writing.

=head2 on_closed

Optional. Invoked when the handle becomes closed.

This handler is invoked before the filehandles are closed and the Handle
removed from its containing Loop. The C<loop> will still return the containing
Loop object.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 read_handle => IO

=head2 write_handle => IO

The reading and writing IO handles. Each must implement the C<fileno> method.
Primarily used for passing C<STDIN> / C<STDOUT>; see the SYNOPSIS section of
L<IO::Async::Stream> for an example.

=head2 handle => IO

The IO handle for both reading and writing; instead of passing each separately
as above. Must implement C<fileno> method in way that C<IO::Handle> does.

=head2 read_fileno => INT

=head2 write_fileno => INT

File descriptor numbers for reading and writing. If these are given as an
alternative to C<read_handle> or C<write_handle> then a new C<IO::Handle>
instance will be constructed around each.

=head2 on_read_ready => CODE

=head2 on_write_ready => CODE

=head2 on_closed => CODE

CODE references for event handlers.

=head2 want_readready => BOOL

=head2 want_writeready => BOOL

If present, enable or disable read- or write-ready notification as per the
C<want_readready> and C<want_writeready> methods.

It is required that a matching C<on_read_ready> or C<on_write_ready> are
available for any handle that is provided; either passed as a callback CODE
reference or as an overridden the method. I.e. if only a C<read_handle> is
given, then C<on_write_ready> can be absent. If C<handle> is used as a
shortcut, then both read and write-ready callbacks or methods are required.

If no IO handles are provided at construction time, the object is still
created but will not yet be fully-functional as a Handle. IO handles can be
assigned later using the C<set_handle> or C<set_handles> methods, or by
C<configure>. This may be useful when constructing an object to represent a
network connection, before the C<connect(2)> has actually been performed yet.

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   if( exists $params{on_read_ready} ) {
      $self->{on_read_ready} = delete $params{on_read_ready};
      undef $self->{cb_r};

      $self->_watch_read(0), $self->_watch_read(1) if $self->want_readready;
   }

   if( exists $params{on_write_ready} ) {
      $self->{on_write_ready} = delete $params{on_write_ready};
      undef $self->{cb_w};

      $self->_watch_write(0), $self->_watch_write(1) if $self->want_writeready;
   }

   if( exists $params{on_closed} ) {
      $self->{on_closed} = delete $params{on_closed};
   }

   if( defined $params{read_fileno} and defined $params{write_fileno} and
       $params{read_fileno} == $params{write_fileno} ) {
      $params{handle} = IO::Handle->new_from_fd( $params{read_fileno}, "r+" );

      delete $params{read_fileno};
      delete $params{write_fileno};
   }
   else {
      $params{read_handle} = IO::Handle->new_from_fd( delete $params{read_fileno}, "r" )
         if defined $params{read_fileno};

      $params{write_handle} = IO::Handle->new_from_fd( delete $params{write_fileno}, "w" )
         if defined $params{write_fileno};
   }

   # 'handle' is a shortcut for setting read_ and write_
   if( exists $params{handle} ) {
      $params{read_handle}  = $params{handle};
      $params{write_handle} = $params{handle};
      delete $params{handle};
   }

   if( exists $params{read_handle} ) {
      my $read_handle = delete $params{read_handle};

      if( defined $read_handle ) {
         if( !defined eval { $read_handle->fileno } ) {
            croak 'Expected that read_handle can ->fileno';
         }

         unless( $self->can_event( 'on_read_ready' ) ) {
            croak 'Expected either a on_read_ready callback or an ->on_read_ready method';
         }

         my @layers = PerlIO::get_layers( $read_handle );
         if( grep m/^encoding\(/, @layers or grep m/^utf8$/, @layers ) {
            # Only warn for now, because if it's UTF-8 by default but only
            # passes ASCII then all will be well
            carp "Constructing a ".ref($self)." with an encoding-enabled handle may not read correctly";
         }

         $self->{read_handle} = $read_handle;

         $self->want_readready( defined $read_handle );
      }
      else {
         $self->want_readready( 0 );

         undef $self->{read_handle};
      }

      # In case someone has reopened the filehandles during an on_closed handler
      undef $self->{handle_closing};
   }

   if( exists $params{write_handle} ) {
      my $write_handle = delete $params{write_handle};

      if( defined $write_handle ) {
         if( !defined eval { $write_handle->fileno } ) {
            croak 'Expected that write_handle can ->fileno';
         }

         unless( $self->can_event( 'on_write_ready' ) ) {
            # This used not to be fatal. Make it just a warning for now.
            carp 'A write handle was provided but neither a on_write_ready callback nor an ->on_write_ready method were. Perhaps you mean \'read_handle\' instead?';
         }

         $self->{write_handle} = $write_handle;
      }
      else {
         $self->want_writeready( 0 );

         undef $self->{write_handle};
      }

      # In case someone has reopened the filehandles during an on_closed handler
      undef $self->{handle_closing};
   }

   if( exists $params{want_readready} ) {
      $self->want_readready( delete $params{want_readready} );
   }

   if( exists $params{want_writeready} ) {
      $self->want_writeready( delete $params{want_writeready} );
   }

   $self->SUPER::configure( %params );
}

# We'll be calling these any of three times
#   adding to/removing from loop
#   caller en/disables readiness checking
#   changing filehandle

sub _watch_read
{
   my $self = shift;
   my ( $want ) = @_;

   my $loop = $self->loop or return;
   my $fh = $self->read_handle or return;

   if( $want ) {
      $self->{cb_r} ||= $self->make_event_cb( 'on_read_ready' );

      $loop->watch_io(
         handle => $fh,
         on_read_ready => $self->{cb_r},
      );
   }
   else {
      $loop->unwatch_io(
         handle => $fh,
         on_read_ready => 1,
      );
   }
}

sub _watch_write
{
   my $self = shift;
   my ( $want ) = @_;

   my $loop = $self->loop or return;
   my $fh = $self->write_handle or return;

   if( $want ) {
      $self->{cb_w} ||= $self->make_event_cb( 'on_write_ready' );

      $loop->watch_io(
         handle => $fh,
         on_write_ready => $self->{cb_w},
      );
   }
   else {
      $loop->unwatch_io(
         handle => $fh,
         on_write_ready => 1,
      );
   }
}

sub _add_to_loop
{
   my $self = shift;
   my ( $loop ) = @_;

   $self->_watch_read(1)  if $self->want_readready;
   $self->_watch_write(1) if $self->want_writeready;
}

sub _remove_from_loop
{
   my $self = shift;
   my ( $loop ) = @_;

   $self->_watch_read(0);
   $self->_watch_write(0);
}

sub notifier_name
{
   my $self = shift;

   my @parts;

   if( length( my $name = $self->SUPER::notifier_name ) ) {
      push @parts, $name;
   }

   my $r = $self->read_fileno;
   my $w = $self->write_fileno;

   if( defined $r and defined $w and $r == $w ) {
      push @parts, "rw=$r";
   }
   elsif( defined $r and defined $w ) {
      push @parts, "r=$r,w=$w";
   }
   elsif( defined $r ) {
      push @parts, "r=$r";
   }
   elsif( defined $w ) {
      push @parts, "w=$w";
   }

   return join ",", @parts;
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 set_handle

   $handle->set_handles( %params )

Sets new reading or writing filehandles. Equivalent to calling the
C<configure> method with the same parameters.

=cut

sub set_handles
{
   my $self = shift;
   my %params = @_;

   $self->configure(
      exists $params{read_handle}  ? ( read_handle  => $params{read_handle} )  : (),
      exists $params{write_handle} ? ( write_handle => $params{write_handle} ) : (),
   );
}

=head2 set_handle

   $handle->set_handle( $fh )

Shortcut for

 $handle->configure( handle => $fh )

=cut

sub set_handle
{
   my $self = shift;
   my ( $fh ) = @_;

   $self->configure( handle => $fh );
}

=head2 close

   $handle->close

This method calls C<close> on the underlying IO handles. This method will then
remove the handle from its containing loop.

=cut

sub close
{
   my $self = shift;

   # Prevent infinite loops if there's two crosslinked handles
   return if $self->{handle_closing};
   $self->{handle_closing} = 1;

   $self->want_readready( 0 );
   $self->want_writeready( 0 );

   my $read_handle = delete $self->{read_handle};
   $read_handle->close if defined $read_handle;

   my $write_handle = delete $self->{write_handle};
   $write_handle->close if defined $write_handle;

   $self->_closed;
}

sub _closed
{
   my $self = shift;

   $self->maybe_invoke_event( on_closed => );
   if( $self->{close_futures} ) {
      $_->done for @{ $self->{close_futures} };
   }
   $self->remove_from_parent;
}

=head2 close_read

=head2 close_write

   $handle->close_read

   $handle->close_write

Closes the underlying read or write handle, and deconfigures it from the
object. Neither of these methods will invoke the C<on_closed> event, nor
remove the object from the Loop if there is still one open handle in the
object. Only when both handles are closed, will C<on_closed> be fired, and the
object removed.

=cut

sub close_read
{
   my $self = shift;

   $self->want_readready( 0 );

   my $read_handle = delete $self->{read_handle};
   $read_handle->close if defined $read_handle;

   $self->_closed if !$self->{write_handle};
}

sub close_write
{
   my $self = shift;

   $self->want_writeready( 0 );

   my $write_handle = delete $self->{write_handle};
   $write_handle->close if defined $write_handle;

   $self->_closed if !$self->{read_handle};
}

=head2 new_close_future

   $handle->new_close_future->get

Returns a new L<IO::Async::Future> object which will become done when the
handle is closed. Cancelling the C<$future> will remove this notification
ability but will not otherwise affect the C<$handle>.

=cut

sub new_close_future
{
   my $self = shift;

   push @{ $self->{close_futures} }, my $future = $self->loop->new_future;
   $future->on_cancel(
      $self->_capture_weakself( sub {
         my $self = shift or return;
         my $future = shift;

         @{ $self->{close_futures} } = grep { $_ != $future } @{ $self->{close_futures} };
      })
   );

   return $future;
}

=head2 read_handle

=head2 write_handle

   $handle = $handle->read_handle

   $handle = $handle->write_handle

These accessors return the underlying IO handles.

=cut

sub read_handle
{
   my $self = shift;
   return $self->{read_handle};
}

sub write_handle
{
   my $self = shift;
   return $self->{write_handle};
}

=head2 read_fileno

=head2 write_fileno

   $fileno = $handle->read_fileno

   $fileno = $handle->write_fileno

These accessors return the file descriptor numbers of the underlying IO
handles.

=cut

sub read_fileno
{
   my $self = shift;
   my $handle = $self->read_handle or return undef;
   return $handle->fileno;
}

sub write_fileno
{
   my $self = shift;
   my $handle = $self->write_handle or return undef;
   return $handle->fileno;
}

=head2 want_readready

=head2 want_writeready

   $value = $handle->want_readready

   $oldvalue = $handle->want_readready( $newvalue )

   $value = $handle->want_writeready

   $oldvalue = $handle->want_writeready( $newvalue )

These are the accessor for the C<want_readready> and C<want_writeready>
properties, which define whether the object is interested in knowing about 
read- or write-readiness on the underlying file handle.

=cut

sub want_readready
{
   my $self = shift;
   if( @_ ) {
      my ( $new ) = @_;

      $new = !!$new;
      return $new if !$new == !$self->{want_readready}; # compare bools

      if( $new ) {
         defined $self->read_handle or
            croak 'Cannot want_readready in a Handle with no read_handle';
      }

      my $old = $self->{want_readready};
      $self->{want_readready} = $new;

      $self->_watch_read( $new );

      return $old;
   }
   else {
      return $self->{want_readready};
   }
}

sub want_writeready
{
   my $self = shift;
   if( @_ ) {
      my ( $new ) = @_;

      $new = !!$new;
      return $new if !$new == !$self->{want_writeready}; # compare bools

      if( $new ) {
         defined $self->write_handle or
            croak 'Cannot want_writeready in a Handle with no write_handle';
      }

      my $old = $self->{want_writeready};
      $self->{want_writeready} = $new;

      $self->_watch_write( $new );

      return $old;
   }
   else {
      return $self->{want_writeready};
   }
}

=head2 socket

   $handle->socket( $ai )

Convenient shortcut to creating a socket handle, as given by an addrinfo
structure, and setting it as the read and write handle for the object.

C<$ai> may be either a C<HASH> or C<ARRAY> reference of the same form as given
to L<IO::Async::OS>'s C<extract_addrinfo> method.

This method returns nothing if it succeeds, or throws an exception if it
fails.

=cut

sub socket
{
   my $self = shift;
   my ( $ai ) = @_;

   # TODO: Something about closing the old one?

   my ( $family, $socktype, $protocol ) = IO::Async::OS->extract_addrinfo( $ai );

   my $sock = IO::Async::OS->socket( $family, $socktype, $protocol );
   $sock->blocking( 0 );

   $self->set_handle( $sock );
}

=head2 bind

   $handle = $handle->bind( %args )->get

Performs a C<getaddrinfo> resolver operation with the C<passive> flag set,
and then attempts to bind a socket handle of any of the return values.

=head2 bind (1 argument)

   $handle = $handle->bind( $ai )->get

When invoked with a single argument, this method is a convenient shortcut to
creating a socket handle and C<bind()>ing it to the address as given by an
addrinfo structure, and setting it as the read and write handle for the
object.

C<$ai> may be either a C<HASH> or C<ARRAY> reference of the same form as given
to L<IO::Async::OS>'s C<extract_addrinfo> method.

The returned future returns the handle object itself for convenience.

=cut

sub bind
{
   my $self = shift;

   if( @_ == 1 ) {
      my ( $ai ) = @_;

      $self->socket( $ai );
      my $addr = ( IO::Async::OS->extract_addrinfo( $ai ) )[3];

      $self->read_handle->bind( $addr ) or
         return Future->fail( "Cannot bind - $!", bind => $self->read_handle, $addr, $! );

      return Future->done( $self );
   }

   $self->loop->resolver->getaddrinfo( passive => 1, @_ )->then( sub {
      my @addrs = @_;

      try_repeat {
         my $ai = shift;

         $self->bind( $ai );
      } foreach => \@addrs,
        until => sub { shift->is_done };
   });
}

=head2 connect

   $handle = $handle->connect( %args )->get

A convenient wrapper for calling the C<connect> method on the underlying
L<IO::Async::Loop> object.

=cut

sub connect
{
   my $self = shift;
   my %args = @_;

   my $loop = $self->loop or croak "Cannot ->connect a Handle that is not in a Loop";

   $self->debug_printf( "CONNECT " . join( ", ",
      # These args should be stringy
      ( map { defined $args{$_} ? "$_=$args{$_}" : () } qw( host service family socktype protocol local_host local_service ) )
   ) );

   return $self->loop->connect( %args, handle => $self );
}

=head1 SEE ALSO

=over 4

=item *

L<IO::Handle> - Supply object methods for I/O handles

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
