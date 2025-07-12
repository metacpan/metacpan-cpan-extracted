#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.817;  # class :abstract
use Future::AsyncAwait;
use Syntax::Keyword::Match;

package IPC::MicroSocket 0.03;

=head1 NAME

C<IPC::MicroSocket> - minimal request/response or pub/sub mechanism

=head1 DESCRIPTION

This distribution provides two main modules for implementing servers or
clients that communicate over a local UNIX socket, to exchange messages. Each
client connects to one server, and a server supports multiple connected
clients.

=over 4

=item *

To implement a client, see L<IPC::MicroSocket::Client>.

=item *

To implement a server, see L<IPC::MicroSocket::Server>.

=back

=head1 MESSAGES

There are two supported kinds of message flows:

=head2 Request/Response

A client sends a request message to the server, which consists of a command
name and a list of arguments. The server eventually sends a response to it,
which contains a list of values. Responses are not necessarily delivered in
the requested order; servers are permitted to respond asynchronously. Requests
may also fail, sending a different kind of failure response to the client
instead.

=head2 Publish/Subscribe

A client subscribes to a given topic string on the server. The server can emit
messages to all the clients that subscribe to a particular topic.

=head1 DATA ENCODING

All transmitted strings are purely bytes. If you need to transmit Unicode
text, you must encode/decode it. If you need to send data structures that are
not plain byte strings, you must serialise/deserialise them.

=cut

class IPC::MicroSocket::Connection :abstract
{
   use Future::Buffer;
   use Future::IO;
   use Future::Selector 0.02; # ->run_until_ready

   field $fh :param;

   # A message is a sigil (U8), argc (U8), args (argc * U32+bytes)

   async method _recv
   {
      my $buffer = Future::Buffer->new(
         fill => sub { Future::IO->sysread( $fh, 256 ) },
      );

      MESSAGE: while(1) {
         defined( my $sigil = await $buffer->read_exactly( 1 ) )
            or last MESSAGE;

         defined( my $argc = unpack "C", await $buffer->read_exactly( 1 ) )
            or last MESSAGE;

         my @args;
         foreach my $i ( 1 .. $argc ) {
            defined( my $len = unpack "L>", await $buffer->read_exactly( 4 ) )
               or last MESSAGE;

            push @args, await $buffer->read_exactly( $len );
         }

         $self->on_recv( $sigil, @args );
      }
   }

   method on_recv;

   async method send ( $sigil, @args )
   {
      await Future::IO->syswrite( $fh,
         join "",
            $sigil,
            pack( "C", scalar @args ),
            map { pack( "L>", length ) . $_ } @args
      );
   }
}

# Message sigils
#   '(' $tag $func @args    -- request
#   ')' $tag @args          -- response OK
#   '#' $tag @args          -- response fail
#   '+' $topic              -- subscribe
#   '!' $topic @args        -- publish

class IPC::MicroSocket::ServerConnection :abstract
{
   inherit IPC::MicroSocket::Connection;

   method on_request;

   method on_subscribe;

   field %subscribed_topics;
   method is_subscribed ( $topic ) { return $subscribed_topics{ $topic }; }

   field $selector = Future::Selector->new;

   async method run ()
   {
      await $selector->run_until_ready( $self->_recv );
      return;
   }

   method on_recv ( $sigil, @args )
   {
      match( $sigil : eq ) {
         case( "(" ) {
            my $tag = shift @args;
            $selector->add(
               data => undef,
               f    => $self->on_request( @args )
                  ->then(
                     # done
                     sub { $self->send( ")", $tag, @_ ) },
                     # fail
                     sub { $self->send( "#", $tag, $_[0] ) },
                  ),
               );
         }
         case( "+" ) {
            my $topic = shift @args;
            $subscribed_topics{ $topic } = 1;
            $self->on_subscribe( $topic );
         }

         default {
            warn "TODO: Unrecognised sigil $sigil\n";
         }
      }
   }

   method publish ( $topic, @args )
   {
      $selector->add(
         data => undef,
         f    => $self->send( "!", $topic, @args ),
      );
   }
}

=head1 FAQs

=head2 Why not ZeroMQ?

I found ZeroMQ to be a lot of effort to use from Perl, and most critically it
does not appear to support both request/response and publish/subscribe message
flows to share the same UNIX socket. To support that in ZeroMQ it would appear
to be necessary to create two separate endpoints, one for each kind of message
flow.

=head2 Why not JSON/YAML/your-favourite-serialisation?

I mostly built this for a few very-small use-cases involving simple byte
strings or plain ASCII text, for which the overhead of JSON, YAML, or other
kinds of serialisation would be unnecessary. As the presented message
semantics are just opaque byte buffers, you are free to layer on top whatever
kind of message serialisation you wish.

=head2 Why not IO::Async/Mojo/your-favourite-event-system?

I wanted to use this distribution as an exercise in writing "pure"
L<Future>-driven event logic, as an experiment to test out L<Future::Selector>
and other related design shapes.

=head1 TODO

There are a number of additional features that this module I<could> support.
Each will be considered if a use-case arises. Each would add extra code and
possible dependencies, and take away from the "micro" nature of the module, so
each would have to be considered on individual merit.

=over 4

=item *

Configurations for encoding and serialisation of arguments.

=item *

Unsubscribe from individual topics by request.

=item *

Helper methods for other socket types, such as TCP sockets.

=item *

Flexible matching of subscription topics; such as string prefixes or delimited
component paths.

=item *

Other kinds of message flows, such as server-buffered streams with atomic
catchup-and-subscribe semantics ensuring clients receive all the buffer.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
