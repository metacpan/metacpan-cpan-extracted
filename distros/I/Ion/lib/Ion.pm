package Ion;
# ABSTRACT: A clear and concise API for writing TCP servers and clients
$Ion::VERSION = '0.06';
use common::sense;

use Carp;
use Coro;
use AnyEvent;
use Ion::Server;
use Ion::Conn;

use parent 'Exporter';

our @EXPORT = qw(
  Connect
  Listen
  Service
);

sub Connect (;$$) {
  my ($host, $port) = @_;
  return Ion::Conn->new(handle => $host) if ref $host;
  return Ion::Conn->new(host => $host, port => $port);
}

sub Listen (;$$) {
  my ($port, $host) = @_;
  Ion::Server->new(host => $host, port => $port);
}

sub Service (&;$$) {
  my $callback = shift;
  my $server = shift;
  $server = Listen($server, shift) unless ref $server;
  $server->start;

  async_pool {
    my ($callback, $server) = @_;

    while (defined(my $conn = <$server>)) {
      async_pool {
        my ($callback, $conn, $server) = @_;

        while (defined(my $line = <$conn>)) {
          my $reply = $callback->($line, $conn, $server);
          last unless defined $reply;
          $conn->($reply) if $reply;
        }

        $conn->close;
      } $callback, $conn, $server;
    }

  } $callback, $server;

  return $server;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ion - A clear and concise API for writing TCP servers and clients

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use Ion;

  # A simple echo server
  my $echo = Listen 7777;

  while (my $conn = <$echo>) {
      while (my $line = <$conn>) {
          $conn->("you said: $line");
      }
  }


  # Or separate the protocol from the listener and let Ion handle the rest
  Service { return "you said: $_[0]" } $echo;


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

  while (my $conn = <$server>) {        # cedes until $conn is ready
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

=head2 Service

Begins serving requests on the specified listening service by calling the
supplied code block for each line received from a client connection. The
service may be specified as the server object itself (the return value of
L</Listen>) or by passing the port and host name, which are passed unchanged to
L</Listen>.

The handler block will be called for each incoming line of data and
additionally is passed the L<client connection|Ion::Conn> and the
L<server|Ion::Server> objects.

  Service {
      my ($line, $conn, $server) = @_;
      return do_something_with_line($line);
  } 7777, '127.0.0.1';

The return value of the handler function is then returned to the client. If the
handler function returns a false value, the client will be disconnected.
Alternately, the handler function may return any defined, false value (e.g., 0)
to retain the client connection but handle the response itself.

  Service {
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

C<Connect> may also be used to build an L<Ion::Conn> out of an existing
L<Coro::Handle>. The handle may then be used like any other Ion connection.
This is particularly useful for serializing data across a non-blocking pipe.

  use Coro::Handle 'unblock';
  use AnyEvent::Util 'portable_pipe';
  use JSON::XS qw(encode_json decode_json);
  use Ion;

  my ($r, $w) = portable_pipe;
  my $in  = Connect(unblock($r)) << \&decode_json;
  my $out = Connect(unblock($w)) >> \&encode_json;

=head1 MESSAGE FORMATS

Sending a raw line of text is sometimes desireable, but complex applications
will want to use an established protocol when transmitting complex data. Rather
than fill request handling logic with the details of encoding and decoding data
for transmission, the routines used for translating structured data into line
data and vice versa may be specified using the >> and << operators,
respectively.

The syntax is identical for both servers and client connections. When applied
to a server instance, client connections accepted on the server side inherit
the server's configuration (note: the connecting client code will need to be
similarly configured).

Multiple routines may be chained together as a single expression or multiple
statements with the assignment version of each operator (>>= and <<=). When
more than one routine is specified, they will each be called in turn on the
result of the previous routine, with the first routine receiving the raw line
data.

=head2 EXAMPLE: JSON

  use Ion;
  use JSON::XS;

  my $server = Listen;
  $server << sub{ decode_json(shift) };
  $server >> sub{ encode_json(shift) };

  while (my $conn = <$server>) {
    while (my $data = <$conn>) {              # $data is perl data
      $conn->({foo => 'bar', baz => 'bat'});  # $conn is sent json: "{'foo': 'bar', 'baz': 'bat'}"
    }
  }

=head2 EXAMPLE: CHAINING

  use Ion;
  use Data::Dumper;
  use MIME::Base64 qw(encode_base64 decode_base64);

  my $client = Connect somehost => 4242;

  # Compound expression
  $client << sub{ decode_base64(shift) }                # decode line format
    << sub{ my $msg = eval shift; $@ && die $@; $msg }; # eval perl string

  # Individual statements
  $client >>= sub{ Dumper(shift) };                     # serialize with Dumper
  $client >>= sub{ encode_base64(shift, '') };          # single line of base64

=head1 ENDLINES

As one would expect using the <> operator, the value of C<$/> controls the character
or string used to match the end of a line of input from the socket. It is also appended
to all output.

  local $/ = "\n\n";
  my $http_request = <$conn>;

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
