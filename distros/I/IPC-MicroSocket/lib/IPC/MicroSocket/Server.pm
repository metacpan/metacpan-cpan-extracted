#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.817;  # class :abstract
use Future::AsyncAwait;
use Sublike::Extended 0.29 'method';

use IPC::MicroSocket;

package IPC::MicroSocket::Server 0.03;  # this 'package' statement just to keep CPAN indexers happy
class IPC::MicroSocket::Server :abstract;

use Carp;

use Future::Selector;

=head1 NAME

C<IPC::MicroSocket::Server> - server role

=head1 SYNOPSIS

=for highlighter perl

   use v5.36;
   use Future::AsyncAwait;
   use Object::Pad v0.807;
   use IPC::MicroSocket::Server;

   class ExampleServer {
      apply IPC::MicroSocket::Server;

      async method on_connection_request ( $conn, $cmd, @args )
      {
         say "Connection sends $cmd";
         return "Response for $cmd";
      }

      method on_connection_subscribe {}
   }

   await ExampleServer->new_unix( path => "my-app.sock" )
      ->run;

=head1 DESCRIPTION

This module provides the server role for L<IPC::MicroSocket>. This is an
incomplete role, which requires any class that applies it to provide some
methods that contain the actual behaviour for the server.

=cut

field $fh :param;

field $connection_class :param = "IPC::MicroSocket::Server::_Connection";

field @clients :reader;

=head1 CONSTRUCTOR

=cut

=head2 new_unix

   $server = IPC::MicroSocket::Server->new_unix( path => $path, %args );

A convenience constructor for creating a new server instance listening on the
given UNIX socket path.

Note as this is a role, this must be invoked on a class that applies the role
and implements the missing methods.

Takes the following named arguments:

=over 4

=item listen => INT

Sets the size of the C<listen(2)> queue; defaults to 5 if not specified.

=back

I<Since version 0.03> any other remaining arguments are passed to the instance
constructor of the underlying object class.

=cut

method new_unix :common ( :$path, :$listen //= 5, %rest )
{
   require IO::Socket::UNIX;

   my $listensock = IO::Socket::UNIX->new(
      Local => $path,
      Listen => $listen,
      ReuseAddr => 1,
   ) or croak "Cannot create socket - $@";

   return $class->new( fh => $listensock, %rest );
}

field $selector;
method _selector
{
   return $selector if $selector;

   $selector = Future::Selector->new;
   $selector->add(
      data => "acceptor",
      gen  => sub { $self->_accept },
   );

   return $selector;
}

async method _accept
{
   my $clientsock = await Future::IO->accept( $fh );

   push @clients, my $client = $connection_class->new(
      server => $self,
      fh     => $clientsock,
   );

   $self->_selector->add(
      data => $client,
      f    => $client->run
         ->on_ready(sub {
            @clients = grep { $_ != $client } @clients;
         }),
   );
}

=head1 METHODS

=cut

=head2 publish

   $server->publish( $topic, @args );

Sends a C<PUBLISH> frame to every connected client.

Note that this is I<not> an C<async> method; the send future for each client
becomes owned by the selector for each connected client instance individually.

=cut

method publish ( $topic, @args )
{
   foreach my $client ( @clients ) {
      $client->is_subscribed( $topic ) and $client->publish( $topic, @args );
   }
}

=head2 run

   await $server->run;

Returns a L<Future> that represents the indefinite runtime of the server
instance.

=cut

method run ()
{
   return $self->_selector->run;
}

=head1 REQUIRED METHODS

=cut

=head2 on_connection_request

   @response = await $server->on_connection_request( $conn, $cmd, @args );

Invoked on receipt of a C<REQUEST> frame from a connected client. It should
asynchronously return the response list to be sent back to the client.

=cut

method on_connection_request;

=head2 on_connection_subscribe

   $server->on_connection_subscribe( $conn, $topic );

Invoked on receipt of a C<SUBSCRIBE> frame from a connected client.

=cut

method on_connection_subscribe;

# The default server connection class
class IPC::MicroSocket::Server::_Connection
{
   inherit IPC::MicroSocket::ServerConnection;

   field $server :param;

   async method on_request ( $cmd, @args )
   {
      await $server->on_connection_request( $self, $cmd, @args );
   }

   method on_subscribe ( $topic )
   {
      $server->on_connection_subscribe( $self, $topic );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
