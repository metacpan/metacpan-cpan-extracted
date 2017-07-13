#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2015 -- leonerd@leonerd.org.uk

package IO::Async::SSL;

use strict;
use warnings;

our $VERSION = '0.20';
$VERSION = eval $VERSION;

use Carp;

use IO::Socket::SSL 1.968 qw( $SSL_ERROR SSL_WANT_READ SSL_WANT_WRITE ); # default_ca
use POSIX qw( EAGAIN EWOULDBLOCK );

use Future 0.33; # ->catch_with_f
use IO::Async::Handle 0.29;
use IO::Async::Loop '0.61'; # new Listen API

=head1 NAME

C<IO::Async::SSL> - use SSL/TLS with L<IO::Async>

=head1 SYNOPSIS

 use IO::Async::Loop;
 use IO::Async::SSL;

 my $loop = IO::Async::Loop->new();

 $loop->SSL_connect(
    host     => "www.example.com",
    service  => "https",

    on_stream => sub {
       my ( $stream ) = @_;

       $stream->configure(
          on_read => sub {
             ...
          },
       );

       $loop->add( $stream );

       ...
    },

    on_resolve_error => sub { print STDERR "Cannot resolve - $_[0]\n"; },
    on_connect_error => sub { print STDERR "Cannot connect\n"; },
    on_ssl_error     => sub { print STDERR "Cannot negotiate SSL - $_[-1]\n"; },
 );

=head1 DESCRIPTION

This module extends existing L<IO::Async> classes with extra methods to allow
the use of SSL or TLS-based connections using L<IO::Socket::SSL>. It does not
directly provide any methods or functions of its own.

Primarily, it provides C<SSL_connect> and C<SSL_listen>, which yield
C<IO::Socket::SSL>-upgraded socket handles or L<IO::Async::Stream>
instances, and two forms of C<SSL_upgrade> to upgrade an existing TCP
connection to use SSL.

As an additional convenience, if the C<SSL_verify_mode> and C<SSL_ca_*>
options are omitted, the module will attempt to provide them by quering the
result of L<IO::Socket::SSL>'s C<default_ca> function. Otherwise, the module
will print a warning and set C<SSL_VERIFY_NONE> instead.

=cut

my %SSL_ca_args = IO::Socket::SSL::default_ca();

sub _SSL_args
{
   my %args = @_;

   # SSL clients (i.e. non-server) require a verify mode
   if( !$args{SSL_server} and !defined $args{SSL_verify_mode} and
       !defined $args{SSL_ca_file} and !defined $args{SSL_ca_path} ) {
      unless( %SSL_ca_args ) {
         carp "Unable to set SSL_VERIFY_PEER because IO::Socket::SSL::default_ca() gives nothing";
         $SSL_ca_args{SSL_verify_mode} = IO::Socket::SSL::SSL_VERIFY_NONE();
      }

      %args = ( %SSL_ca_args, %args );
   }

   return %args;
}

sub sslread
{
   my $stream = shift;
   my ( $fh, undef, $len ) = @_;

   my $ret = $stream->_sysread( $fh, $_[1], $len );

   my $read_wants_write = !defined $ret &&
                          ( $! == EAGAIN or $! == EWOULDBLOCK ) &&
                          $SSL_ERROR == SSL_WANT_WRITE;
   $stream->want_writeready_for_read( $read_wants_write );

   # It's possible SSL_read took all the data out of the filehandle, thus
   # making it not appear read-ready any more.
   if( $fh->pending ) {
      $stream->loop->later( sub { $stream->on_read_ready } );
   }

   return $ret;
}

sub sslwrite
{
   my $stream = shift;
   my ( $fh, undef, $len ) = @_;

   # Placate RT98372
   utf8::downgrade( $_[1] ) or
      carp "Wide character in sslwrite";

   my $ret = $stream->_syswrite( $fh, $_[1], $len );

   my $write_wants_read = !defined $ret &&
                          ( $! == EAGAIN or $! == EWOULDBLOCK ) &&
                          $SSL_ERROR == SSL_WANT_READ;
   $stream->want_readready_for_write( $write_wants_read );
   # If write wants read, there's no point waiting on writereadiness either
   $stream->want_writeready_for_write( !$write_wants_read );

   return $ret;
}

=head1 LOOP METHODS

The following extra methods are added to L<IO::Async::Loop>.

=cut

=head2 SSL_upgrade

   ( $stream or $socket ) = $loop->SSL_upgrade( %params )->get;

This method upgrades a given stream filehandle into an SSL-wrapped stream,
returning a future which will yield the given stream object or socket.

Takes the following parameters:

=over 8

=item handle => IO::Async::Stream | IO

The C<IO::Async::Stream> object containing the IO handle of an
already-established connection to act as the transport for SSL; or the plain
IO socket handle itself.

If an C<IO::Async::Stream> is passed it will have the C<reader> and C<writer>
functions set on it suitable for SSL use, and will be returned as the result
from the future.

If a plain socket handle is passed, that will be returned from the future
instead.

=item SSL_server => BOOL

If true, indicates this is the server side of the connection.

=back

In addition, any parameter whose name starts C<SSL_> will be passed to the
C<IO::Socket::SSL> constructor.

The following legacy callback arguments are also supported, in case the
returned future is not used:

=over 8

=item on_upgraded => CODE

A continuation that is invoked when the socket has been successfully upgraded
to SSL. It will be passed an instance of an C<IO::Socket::SSL>, which will
have appropriate SSL-compatible reader/writer functions attached.

 $on_upgraded->( $sslsocket )

=item on_error => CODE

A continuation that is invoked if C<IO::Socket::SSL> detects an error while
negotiating the upgrade.

 $on_error->( $! )

=back

=cut

sub IO::Async::Loop::SSL_upgrade
{
   my $loop = shift;
   my %params = @_;

   my $f = $loop->new_future;

   $params{handle} or croak "Expected 'handle'";

   my $stream;
   my $socket;
   if( $params{handle}->isa( "IO::Async::Stream" ) ) {
      $stream = delete $params{handle};
      $socket = $stream->read_handle;
   }
   else {
      $socket = delete $params{handle};
   }

   {
      my $on_upgraded = delete $params{on_upgraded} or defined wantarray
         or croak "Expected 'on_upgraded' or to return a Future";
      my $on_error    = delete $params{on_error}    or defined wantarray
         or croak "Expected 'on_error' or to return a Future";

      $f->on_done( $on_upgraded ) if $on_upgraded;
      $f->on_fail( $on_error    ) if $on_error;
   }

   my %ssl_params = map { $_ => delete $params{$_} } grep m/^SSL_/, keys %params;

   eval { $socket = IO::Socket::SSL->start_SSL( $socket, _SSL_args
      SSL_startHandshake => 0,

      # Required to make IO::Socket::SSL not ->close before we have a chance to remove it from the loop
      SSL_error_trap => sub { },

      %ssl_params,
   ) } or do {
      chomp( my $e = $@ );
      return $f->fail( $e, "ssl" );
   };

   my $ready_method = $ssl_params{SSL_server} ? "accept_SSL" : "connect_SSL";

   my $ready = sub {
      my ( $self ) = @_;
      if( $socket->$ready_method ) {
         $loop->remove( $self );

         if( $stream ) {
            $stream->configure(
               handle => $socket,
               reader => \&sslread,
               writer => \&sslwrite,
            );
         }

         $f->done( $stream || $socket );
         return;
      }

      if( $! != EAGAIN and $! != EWOULDBLOCK ) {
         my $errstr = IO::Socket::SSL::errstr();
         $loop->remove( $self );
         $f->fail( $errstr, "ssl" );
         return;
      }

      $self->want_readready ( $SSL_ERROR == SSL_WANT_READ );
      $self->want_writeready( $SSL_ERROR == SSL_WANT_WRITE );
   };

   # We're going to steal the IO handle from $stream, so we'll have to
   # temporarily deconfigure it
   $stream->configure( handle => undef ) if $stream;

   $loop->add( my $handle = IO::Async::Handle->new(
      handle => $socket,
      on_read_ready  => $ready,
      on_write_ready => $ready,
   ) );

   $ready->( $handle );

   return $f if defined wantarray;

   # Caller is not going to keep hold of the Future, so we have to ensure it
   # stays alive somehow
   $f->on_ready( sub { undef $f } ); # intentional cycle
}

=head2 SSL_connect

   $stream = $loop->SSL_connect( %params )->get;

This method performs a non-blocking connection to a given address or set of
addresses, upgrades the socket to SSL, then yields a C<IO::Async::Stream>
object when the SSL handshake is complete.

It takes all the same arguments as C<IO::Async::Loop::connect()>. Any argument
whose name starts C<SSL_> will be passed on to the L<IO::Socket::SSL>
constructor rather than the Loop's C<connect> method. It is not required to
pass the C<socktype> option, as SSL implies this will be C<stream>.

This method can also upgrade an existing C<IO::Async::Stream> or subclass
instance given as the C<handle> argument, by setting the C<reader> and
C<writer> functions.

=head2 SSL_connect (void)

   $loop->SSL_connect( %params,
      on_connected => sub { ... },
      on_stream => sub { ... },
   );

When not returning a future, this method also supports the C<on_connected> and
C<on_stream> continuations.

In addition, the following arguments are then required:

=over 8

=item on_ssl_error => CODE

A continuation that is invoked if C<IO::Socket::SSL> detects an SSL-based
error once the actual stream socket is connected.

=back

If the C<on_connected> continuation is used, the socket handle it yields will
be a C<IO::Socket::SSL>, which must be wrapped in C<IO::Async::SSLStream> to
be used by C<IO::Async>. The C<on_stream> continuation will already yield such
an instance.

=cut

sub IO::Async::Loop::SSL_connect
{
   my $loop = shift;
   my %params = @_;

   my %ssl_params = map { $_ => delete $params{$_} } grep m/^SSL_/, keys %params;

   my $on_done;
   if( exists $params{on_connected} ) {
      my $on_connected = delete $params{on_connected};
      $on_done = sub {
         my ( $stream ) = @_;
         $on_connected->( $stream->read_handle );
      };
   }
   elsif( exists $params{on_stream} ) {
      my $on_stream = delete $params{on_stream};
      $on_done = $on_stream;
   }
   else {
      croak "Expected 'on_connected' or 'on_stream' or to return a Future" unless defined wantarray;
   }

   my $on_ssl_error = delete $params{on_ssl_error} or defined wantarray or
      croak "Expected 'on_ssl_error' or to return a Future";

   my $stream = delete $params{handle} || do {
      require IO::Async::Stream;
      IO::Async::Stream->new;
   };

   $stream->isa( "IO::Async::Stream" ) or
      croak "Can only SSL_connect a handle instance of IO::Async::Stream";

   # Don't ->connect with the handle yet, because we'll first have to use the
   # socket to perform SSL_upgrade on. We don't want to confuse the loop by
   # giving it the same fd twice.

   my $f = $loop->connect(
      socktype => 'stream', # SSL over DGRAM or RAW makes no sense
      %params,
   )->then( sub {
      my ( $socket ) = @_;

      $stream->configure( handle => $socket );

      $loop->SSL_upgrade(
         _SSL_args( %ssl_params ),
         handle => $stream,
      )
   });

   $f->on_done( $on_done ) if $on_done;
   $f->on_fail( sub {
      $on_ssl_error->( $_[0] ) if defined $_[1] and $_[1] eq "ssl";
   }) if $on_ssl_error;

   return $f if defined wantarray;

   # Caller is not going to keep hold of the Future, so we have to ensure it
   # stays alive somehow
   $f->on_ready( sub { undef $f } ); # intentional cycle
}

=head2 SSL_listen

   $loop->SSL_listen( %params )->get;

This method sets up a listening socket using the addresses given, and will
invoke the callback each time a new connection is accepted on the socket and
the SSL handshake has been completed. This can be either the C<on_accept> or
C<on_stream> continuation; C<on_socket> is not supported.

It takes all the same arguments as C<IO::Async::Loop::listen()>. Any argument
whose name starts C<SSL_> will be passed on to the L<IO::Socket::SSL>
constructor rather than the Loop's C<listen> method. It is not required to
pass the C<socktype> option, as SSL implies this will be C<stream>.

In addition, the following arguments are rquired:

=over 8

=item on_ssl_error => CODE

A continuation that is invoked if C<IO::Socket::SSL> detects an SSL-based
error once the actual stream socket is connected.

=back

The underlying L<IO::Socket::SSL> socket will also require the server key and
certificate for a server-mode socket. See its documentation for more details.

If the C<on_accept> continuation is used, the socket handle it yields will be
a C<IO::Socket::SSL>, which must be wrapped in C<IO::Async::SSLStream> to be
used by C<IO::Async>. The C<on_stream> continuation will already yield such an
instance.

=cut

sub IO::Async::Loop::SSL_listen
{
   my $loop = shift;
   my %params = @_;

   my %ssl_params = map { $_ => delete $params{$_} } grep m/^SSL_/, keys %params;
   my $on_ssl_error = delete $params{on_ssl_error} or defined wantarray
      or croak "Expected 'on_ssl_error'";

   my $f = $loop->listen(
      socktype => 'stream',
      %params,
   )->on_done( sub {
      my $listener = shift;

      my $cleartext_acceptor = $listener->acceptor;
      my $ssl_acceptor = sub {
         my $listener = shift;
         my ( $listen_sock, %params ) = @_;
         my $stream = $params{handle};
         !defined $stream or $stream->isa( "IO::Async::Stream" ) or
            croak "Can only accept SSL on IO::Async::Stream handles";

         $listener->$cleartext_acceptor( $listen_sock )->then( sub {
            my ( $socket ) = @_;

            return Future->done() unless $socket; # EAGAIN

            $stream->configure( handle => $socket ) if $stream;

            $loop->SSL_upgrade(
               _SSL_args( SSL_server => 1, %ssl_params ),
               handle   => ( $stream || $socket ),
            )->catch_with_f( ssl => sub {
               my ( $f, $failure ) = @_;
               if( $on_ssl_error ) {
                  $on_ssl_error->( $failure );
                  return Future->done;  # eat it
               }
               return $f;
            });
         });
      };

      $listener->configure( acceptor => $ssl_acceptor );
   });

   return $f if defined wantarray;

   # Caller is not going to keep hold of the Future, so we have to ensure it
   # stays alive somehow
   $f->on_ready( sub { undef $f } ); # intentional cycle
}

=head1 STREAM PROTOCOL METHODS

The following extra methods are added to L<IO::Async::Protocol::Stream>.

=cut

=head2 SSL_upgrade

   $protocol->SSL_upgrade( %params )->get;

A shortcut to calling C<< $loop->SSL_upgrade >>. This method will unconfigure
the C<transport> of the Protocol, upgrade its underlying filehandle to SSL,
then reconfigure it again with SSL reader and writer functions on it. It takes
the same arguments as C<< $loop->SSL_upgrade >>, except that the C<handle>
argument is not required as it's taken from the Protocol's C<transport>.

=cut

sub IO::Async::Protocol::Stream::SSL_upgrade
{
   my $protocol = shift;
   my %params = @_;

   my $on_upgraded = delete $params{on_upgraded} or croak "Expected 'on_upgraded'";

   my $loop = $protocol->get_loop or croak "Expected to be a member of a Loop";

   my $transport = $protocol->transport;

   $protocol->configure( transport => undef );

   $loop->SSL_upgrade(
      handle => $transport,
      on_upgraded => sub {
         my ( $transport ) = @_;

         $protocol->configure( transport => $transport );

         $on_upgraded->();
      },

      %params,
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
