package Ion;
# ABSTRACT: A clear and concise API for writing TCP servers and clients
$Ion::VERSION = '0.02';
use common::sense;

use Carp;
use Coro;
use Ion::Server;
use Ion::Conn;

use parent 'Exporter';

our @EXPORT = qw(
  Connect
  Listen
);

sub Connect ($$) {
  my ($host, $port) = @_;
  Ion::Conn->new(host => $host, port => $port);
}

sub Listen {
  my $service = pop;
  my $server  = Ion::Server->new(port => shift, host => shift);
  $server->start;

  if ($service) {
    async_pool {
      my ($service, $server) = @_;

      while (defined(my $conn = <$server>)) {
        async_pool {
          my ($service, $conn, $server) = @_;

          while (defined(my $line = <$conn>)) {
            my $reply = $service->($line, $conn, $server);
            last unless defined $reply;
            $conn->($reply) if $reply;
          }

          $conn->close;
        } $service, $conn, $server;
      }
    } $service, $server;
  }

  return $server;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ion - A clear and concise API for writing TCP servers and clients

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Ion;

  # A simple echo server
  my $echo = Listen 7777;

  while (my $conn = <$echo>) {
    while (my $line = <$conn>) {
      $conn->($line);
    }
  }


  # Or separate the protocol from the listener
  sub echo {
    my $line = shift;
    return $line;
  }

  # ...and let Ion handle the rest
  my $server = Listen 7777, \&echo;


  # Client connections
  my $conn = Connect localhost => 7777; # Connect to the server
  $conn->('hello world');               # Send a message
  my $reply = <$conn>;                  # Get it back

=head1 DESCRIPTION

Ion is intended as an easy to use, concise interface for building TCP
networking applications in Perl using L<Coro>. Although it is not strictly
necessary, it is recommended that one have at least a passing familiarity with
L<Coro> when building services with this module.

=head1 EXPORTED SUBROUTINES

=head2 Listen

C<Listen> builds and initializes a TCP listening socket, returning an
L<Ion::Server>.

Incoming L<connections|Ion::Conn> are accepted using the readline operator
(<>). This will cede to the event loop until a new connection is ready.

Incoming data from the client connection is read similarly. The client is
overloaded to send response data when called as a function.

Because each of these operations has the potential to cede control to the event
loop, it is recommended that the client response loop be called using
L<async|Coro>. That allows other incoming connections to be accepted without
waiting for the original client to disconnect.

  my $server = Listen 1234, 'localhost';

  while (my $conn = <$server>) {    # cedes until $conn is ready
    async {
      while (my $line = <$conn>) {  # cedes until $line is ready
        $conn->(do_something_with($line));
      }
    };
  }

The port number and host interface are optional. If left undefined, these will
be assigned by the operating system and are accessible via the C<port> and
C<host> methods of the server.

  my $server = Listen;
  my $port   = $server->port;
  my $host   = $server->host;

If desirable, a request handler function may also be provided as the final
argument to C<Listen>. This will be called for each incoming line of data and
additionally is passed the L<client connection|Ion::Conn> and the
L<server|Ion::Server> objects.

  Listen 7777, sub {
    my ($line, $conn, $server) = @_;
    return do_something_with_line($line);
  };

The return value of the handler function is then returned to the client. If the
handler function returns a false value, the client will be disconnected.
Alternately, the handler function may return any defined, false value (e.g., 0)
to retain the client connection but handle the response itself.

  Listen 777, sub {
    my ($line, $conn, $server) = @_;
    $conn->(do_something_with_line($line));
    return 0;
  };

=head2 Connect

Opens a connection to a remote host and returns an L<Ion::Conn> object. The
connection object is overloaded to send data when called as a function and read
the next line of data using the readline operator (<>). The connection is
safely closed by calling the C<close> method.

  my $conn = Connect 'localhost', 7777;
  $conn->('ping');
  my $pong = <$conn>;
  $conn->close;

The readline operator will block until a complete message arrives. To continue
thread execution while waiting for the message, use an L<async|Coro> block and
C<join> with it later.

  my $pending  = async { <$conn> };
  my $response = $pending->join;

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
