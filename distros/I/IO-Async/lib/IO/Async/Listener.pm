#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2008-2015 -- leonerd@leonerd.org.uk

package IO::Async::Listener;

use strict;
use warnings;
use base qw( IO::Async::Handle );

our $VERSION = '0.77';

use IO::Async::Handle;
use IO::Async::OS;

use Future 0.33; # ->catch

use Errno qw( EAGAIN EWOULDBLOCK );

use Socket qw( sockaddr_family SOL_SOCKET SO_ACCEPTCONN SO_TYPE );

use Carp;

=head1 NAME

C<IO::Async::Listener> - listen on network sockets for incoming connections

=head1 SYNOPSIS

 use IO::Async::Listener;

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 my $listener = IO::Async::Listener->new(
    on_stream => sub {
       my ( undef, $stream ) = @_;

       $stream->configure(
          on_read => sub {
             my ( $self, $buffref, $eof ) = @_;
             $self->write( $$buffref );
             $$buffref = "";
             return 0;
          },
       );

       $loop->add( $stream );
    },
 );

 $loop->add( $listener );

 $listener->listen(
    service  => "echo",
    socktype => 'stream',
 )->get;

 $loop->run;

This object can also be used indirectly via an L<IO::Async::Loop>:

 use IO::Async::Stream;

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 $loop->listen(
    service  => "echo",
    socktype => 'stream',

    on_stream => sub {
       ...
    },
 )->get;

 $loop->run;

=head1 DESCRIPTION

This subclass of L<IO::Async::Handle> adds behaviour which watches a socket in
listening mode, to accept incoming connections on them.

A Listener can be constructed and given a existing socket in listening mode.
Alternatively, the Listener can construct a socket by calling the C<listen>
method. Either a list of addresses can be provided, or a service name can be
looked up using the underlying loop's C<resolve> method.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 on_accept $clientsocket | $handle

Invoked whenever a new client connects to the socket.

If neither C<handle_constructor> nor C<handle_class> parameters are set, this
will be invoked with the new client socket directly. If a handle constructor
or class are set, this will be invoked with the newly-constructed handle,
having the new socket already configured onto it.

=head2 on_stream $stream

An alternative to C<on_accept>, this is passed an instance of
L<IO::Async::Stream> when a new client connects. This is provided as a
convenience for the common case that a Stream object is required as the
transport for a Protocol object.

This is now vaguely deprecated in favour of using C<on_accept> with a handle
constructor or class.

=head2 on_socket $socket

Similar to C<on_stream>, but constructs an instance of L<IO::Async::Socket>.
This is most useful for C<SOCK_DGRAM> or C<SOCK_RAW> sockets.

This is now vaguely deprecated in favour of using C<on_accept> with a handle
constructor or class.

=head2 on_accept_error $socket, $errno

Optional. Invoked if the C<accept> syscall indicates an error (other than
C<EAGAIN> or C<EWOULDBLOCK>). If not provided, failures of C<accept> will
be passed to the main C<on_error> handler.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 on_accept => CODE

=head2 on_stream => CODE

=head2 on_socket => CODE

CODE reference for the event handlers. Because of the mutually-exclusive
nature of their behaviour, only one of these may be set at a time. Setting one
will remove the other two.

=head2 handle => IO

The IO handle containing an existing listen-mode socket.

=head2 handle_constructor => CODE

Optional. If defined, gives a CODE reference to be invoked every time a new
client socket is accepted from the listening socket. It is passed the listener
object itself, and is expected to return a new instance of
L<IO::Async::Handle> or a subclass, used to wrap the new client socket.

 $handle = $handle_constructor->( $listener )

This can also be given as a subclass method

 $handle = $listener->handle_constructor()

=head2 handle_class => STRING

Optional. If defined and C<handle_constructor> isn't, then new wrapper handles
are constructed by invoking the C<new> method on the given class name, passing
in no additional parameters.

 $handle = $handle_class->new()

This can also be given as a subclass method

 $handle = $listener->handle_class->new

=head2 acceptor => STRING|CODE

Optional. If defined, gives the name of a method or a CODE reference to use to
implement the actual accept behaviour. This will be invoked as:

 ( $accepted ) = $listener->acceptor( $socket )->get

 ( $handle ) = $listener->acceptor( $socket, handle => $handle )->get

It is invoked with the listening socket as its its argument, and optionally
an L<IO::Async::Handle> instance as a named parameter, and is expected to
return a C<Future> that will eventually yield the newly-accepted socket or
handle instance, if such was provided.

=cut

sub _init
{
   my $self = shift;
   $self->SUPER::_init( @_ );

   $self->{acceptor} = "_accept";
}

my @acceptor_events  = qw( on_accept on_stream on_socket );

sub configure
{
   my $self = shift;
   my %params = @_;

   if( grep exists $params{$_}, @acceptor_events ) {
      grep( defined $_, @params{@acceptor_events} ) <= 1 or
         croak "Can only set at most one of 'on_accept', 'on_stream' or 'on_socket'";

      # Don't exists-test, so we'll clear the other two
      $self->{$_} = delete $params{$_} for @acceptor_events;
   }

   croak "Cannot set 'on_read_ready' on a Listener" if exists $params{on_read_ready};

   if( defined $params{handle} ) {
      my $handle = delete $params{handle};
      # Sanity check it - it may be a bare GLOB ref, not an IO::Socket-derived handle
      defined getsockname( $handle ) or croak "IO handle $handle does not have a sockname";

      # So now we know it's at least some kind of socket. Is it listening?
      # SO_ACCEPTCONN would tell us, but not all OSes implement it. Since it's
      # only a best-effort sanity check, we won't mind if the OS doesn't.
      my $acceptconn = getsockopt( $handle, SOL_SOCKET, SO_ACCEPTCONN );
      !defined $acceptconn or unpack( "I", $acceptconn ) or croak "Socket is not accepting connections";

      # This is a bit naughty but hopefully nobody will mind...
      bless $handle, "IO::Socket" if ref( $handle ) eq "GLOB";

      $self->SUPER::configure( read_handle => $handle );
   }
   elsif( exists $params{handle} ) {
      delete $params{handle};

      $self->SUPER::configure( read_handle => undef );
   }

   unless( grep $self->can_event( $_ ), @acceptor_events ) {
      croak "Expected to be able to 'on_accept', 'on_stream' or 'on_socket'";
   }

   foreach (qw( acceptor handle_constructor handle_class )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   if( keys %params ) {
      croak "Cannot pass though configuration keys to underlying Handle - " . join( ", ", keys %params );
   }
}

sub on_read_ready
{
   my $self = shift;

   my $socket = $self->read_handle;

   my $on_done;
   my %acceptor_params;

   if( $on_done = $self->can_event( "on_stream" ) ) {
      # TODO: It doesn't make sense to put a SOCK_DGRAM in an
      # IO::Async::Stream but currently we don't detect this
      require IO::Async::Stream;
      $acceptor_params{handle} = IO::Async::Stream->new;
   }
   elsif( $on_done = $self->can_event( "on_socket" ) ) {
      require IO::Async::Socket;
      $acceptor_params{handle} = IO::Async::Socket->new;
   }
   # on_accept needs to be last in case of multiple layers of subclassing
   elsif( $on_done = $self->can_event( "on_accept" ) ) {
      my $handle;

      # Test both params before moving on to either method
      if( my $constructor = $self->{handle_constructor} ) {
         $handle = $self->{handle_constructor}->( $self );
      }
      elsif( my $class = $self->{handle_class} ) {
         $handle = $class->new;
      }
      elsif( $self->can( "handle_constructor" ) ) {
         $handle = $self->handle_constructor;
      }
      elsif( $self->can( "handle_class" ) ) {
         $handle = $self->handle_class->new;
      }

      $acceptor_params{handle} = $handle if $handle;
   }
   else {
      die "ARG! Missing on_accept,on_stream,on_socket!";
   }

   my $acceptor = $self->acceptor;
   my $f = $self->$acceptor( $socket, %acceptor_params )->on_done( sub {
      my ( $result ) = @_ or return; # false-alarm
      $on_done->( $self, $result );
   })->catch( accept => sub {
      my ( $message, $name, @args ) = @_;
      my ( $socket, $dollarbang ) = @args;
      $self->maybe_invoke_event( on_accept_error => $socket, $dollarbang ) or
         $self->invoke_error( "accept() failed - $dollarbang", accept => $socket, $dollarbang );
   });

   # TODO: Consider if this wants a more fine-grained place to report
   # non-accept() failures (such as SSL) to
   $self->adopt_future( $f );
}

sub _accept
{
   my $self = shift;
   my ( $listen_sock, %params ) = @_;

   my $accepted = $listen_sock->accept;

   if( defined $accepted ) {
      $accepted->blocking( 0 );
      if( my $handle = $params{handle} ) {
         $handle->set_handle( $accepted );
         return Future->done( $handle );
      }
      else {
         return Future->done( $accepted );
      }
   }
   elsif( $! == EAGAIN or $! == EWOULDBLOCK ) {
      return Future->done;
   }
   else {
      return Future->fail( "Cannot accept() - $!", accept => $listen_sock, $! );
   }
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 acceptor

   $acceptor = $listener->acceptor

Returns the currently-set C<acceptor> method name or code reference. This may
be of interest to Loop C<listen> extension methods that wish to extend or wrap
it.

=cut

sub acceptor
{
   my $self = shift;
   return $self->{acceptor};
}

sub is_listening
{
   my $self = shift;

   return ( defined $self->sockname );
}

=head2 sockname

   $name = $listener->sockname

Returns the C<sockname> of the underlying listening socket

=cut

sub sockname
{
   my $self = shift;

   my $handle = $self->read_handle or return undef;
   return $handle->sockname;
}

=head2 family

   $family = $listener->family

Returns the socket address family of the underlying listening socket

=cut

sub family
{
   my $self = shift;

   my $sockname = $self->sockname or return undef;
   return sockaddr_family( $sockname );
}

=head2 socktype

   $socktype = $listener->socktype

Returns the socket type of the underlying listening socket

=cut

sub socktype
{
   my $self = shift;

   my $handle = $self->read_handle or return undef;
   return $handle->sockopt(SO_TYPE);
}

=head2 listen

   $listener->listen( %params )

This method sets up a listening socket and arranges for the acceptor callback
to be invoked each time a new connection is accepted on the socket.

Most parameters given to this method are passed into the C<listen> method of
the L<IO::Async::Loop> object. In addition, the following arguments are also
recognised directly:

=over 8

=item on_listen => CODE

Optional. A callback that is invoked when the listening socket is ready.
Similar to that on the underlying loop method, except it is passed the
listener object itself.

 $on_listen->( $listener )

=back

=cut

sub listen
{
   my $self = shift;
   my ( %params ) = @_;

   my $loop = $self->loop;
   defined $loop or croak "Cannot listen when not a member of a Loop"; # TODO: defer?

   if( my $on_listen = delete $params{on_listen} ) {
      $params{on_listen} = sub { $on_listen->( $self ) };
   }

   $loop->listen( listener => $self, %params );
}

=head1 EXAMPLES

=head2 Listening on UNIX Sockets

The C<handle> argument can be passed an existing socket already in listening
mode, making it possible to listen on other types of socket such as UNIX
sockets.

 use IO::Async::Listener;
 use IO::Socket::UNIX;

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 my $listener = IO::Async::Listener->new(
    on_stream => sub {
       my ( undef, $stream ) = @_;

       $stream->configure(
          on_read => sub {
             my ( $self, $buffref, $eof ) = @_;
             $self->write( $$buffref );
             $$buffref = "";
             return 0;
          },
       );

       $loop->add( $stream );
    },
 );

 $loop->add( $listener );

 my $socket = IO::Socket::UNIX->new(
    Local => "echo.sock",
    Listen => 1,
 ) or die "Cannot make UNIX socket - $!\n";

 $listener->listen(
    handle => $socket,
 );

 $loop->run;

=head2 Passing Plain Socket Addresses

The C<addr> or C<addrs> parameters should contain a definition of a plain
socket address in a form that the L<IO::Async::OS> C<extract_addrinfo>
method can use.

This example shows how to listen on TCP port 8001 on address 10.0.0.1:

 $listener->listen(
    addr => {
       family   => "inet",
       socktype => "stream",
       port     => 8001,
       ip       => "10.0.0.1",
    },
    ...
 );

This example shows another way to listen on a UNIX socket, similar to the
earlier example:

 $listener->listen(
    addr => {
       family   => "unix",
       socktype => "stream",
       path     => "echo.sock",
    },
    ...
 );

=head2 Using A Kernel-Assigned Port Number

Rather than picking a specific port number, is it possible to ask the kernel
to assign one arbitrarily that is currently free. This can be done by
requesting port number 0 (which is actually the default if no port number is
otherwise specified). To determine which port number the kernel actually
picked, inspect the C<sockport> accessor on the actual socket filehandle.

Either use the L<Future> returned by the C<listen> method:

 $listener->listen(
    addr => { family => "inet" },
 )->on_done( sub {
    my ( $listener ) = @_;
    my $socket = $listener->read_handle;

    say "Now listening on port ", $socket->sockport;
 });

Or pass an C<on_listen> continuation:

 $listener->listen(
    addr => { family => "inet" },

    on_listen => sub {
       my ( $listener ) = @_;
       my $socket = $listener->read_handle;

       say "Now listening on port ", $socket->sockport;
    },
 );

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
