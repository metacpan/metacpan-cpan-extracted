#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.807;
use Future::AsyncAwait;
use Sublike::Extended 0.29 'sub';
use Syntax::Keyword::Match;

use IPC::MicroSocket;

class IPC::MicroSocket::Client 0.03;

use Carp;

use Future::Selector;

=head1 NAME

C<IPC::MicroSocket::Client> - client connector

=head1 SYNOPSIS

=for highlighter perl

   use v5.36;
   use Future::AsyncAwait;
   use IPC::MicroSocket::Client;

   my $client = IPC::MicroSocket::Client->new_unix( path => "my-app.sock" );

   say await $client->request( "PING" );

=head1 DESCRIPTION

This module provides the client connector class for L<IPC::MicroSocket>.

=cut

inherit IPC::MicroSocket::Connection;

field %resp_f_by_tag;
field %subscribes_by_topic;

=head1 CONSTRUCTOR

=cut

=head2 new_unix

   $client = IPC::MicroSocket::Client->new_unix( path => $path );

A convenience constructor for connecting a new client instance to a given
UNIX socket path.

=cut

# class method
sub new_unix ( $class, :$path )
{
   require IO::Socket::UNIX;

   my $sock = IO::Socket::UNIX->new( Peer => $path ) or
      croak "Cannot connect to server - $@";

   return $class->new( fh => $sock );
}

method on_recv ( $sigil, @args )
{
   match( $sigil : eq ) {
      case( ")" ) {
         my $tag = shift @args;
         my $f = delete $resp_f_by_tag{ $tag } or return;
         $f->done( @args );
      }
      case( "#" ) {
         my $tag = shift @args;
         my $f = delete $resp_f_by_tag{ $tag } or return;
         $f->fail( $args[0], slurm => @args[1..$#args] );
      }
      case( "!" ) {
         my $topic = shift @args;
         $subscribes_by_topic{ $topic } and
            $subscribes_by_topic{ $topic }->( @args );
      }
      default {
         warn "Unrecognised message sigil $sigil\n";
      }
   }
}

field $selector;
method _selector
{
   return $selector if $selector;

   $selector = Future::Selector->new;
   $selector->add(
      data => "runloop",
      f    => $self->_recv,
   );

   return $selector;
}

=head1 METHODS

=cut

=head2 request

   @response = await $client->request( @args );

Sends a C<REQUEST> frame with the given arguments, waiting for a response. The
returned future will complete with its C<RESPONSE> frame.

=cut

field $last_tag = 0;
async method request ( @args )
{
   my $tag = pack "C", ( $last_tag += 1 ) %= 256;

   await $self->send( '(', $tag, @args );

   my $f = ( $resp_f_by_tag{ $tag } = Future->new );

   my $s = $self->_selector;
   await $s->run_until_ready( $f );
   return await $f;
}

=head2 subscribe

   await $client->subscribe( $topic, $on_recv );

   $on_recv->( @args );

Sends a C<SUBSCRIBE> frame for the given topic name, then waits indefinitely
for C<PUBLISH> frames that match it. Each received frame will invoke the
C<$on_recv> callback.

Note that the L<Future> returned by this method should not complete in normal
circumstances but will remain pending forever.

=cut

async method subscribe ( $topic, $on_recv )
{
   await $self->send( '+', $topic );

   $subscribes_by_topic{ $topic } = $on_recv;

   my $s = $self->_selector;
   await $s->select while 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
