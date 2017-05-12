#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Loop;
use IO::Async::Stream;

my $PORT = 12345;

my $loop = IO::Async::Loop->new;

my $listener = ChatListener->new;

$loop->add( $listener );

$listener->listen(
   service  => $PORT,
   socktype => 'stream',
)->on_done( sub {
   my ( $listener ) = @_;
   my $socket = $listener->read_handle;

   printf STDERR "Listening on %s:%d\n", $socket->sockhost, $socket->sockport;
})->get;

$loop->run;

package ChatListener;
use base qw( IO::Async::Listener );

my @clients;

sub on_stream
{
   my $self = shift;
   my ( $stream ) = @_;

   # $socket is just an IO::Socket reference
   my $socket = $stream->read_handle;
   my $peeraddr = $socket->peerhost . ":" . $socket->peerport;

   # Inform the others
   $_->write( "$peeraddr joins\n" ) for @clients;

   $stream->configure(
      on_read => sub {
         my ( $self, $buffref, $eof ) = @_;

         while( $$buffref =~ s/^(.*\n)// ) {
            # eat a line from the stream input

            # Reflect it to all but the stream who wrote it
            $_ == $self or $_->write( "$peeraddr: $1" ) for @clients;
         }

         return 0;
      },

      on_closed => sub {
         my ( $self ) = @_;
         @clients = grep { $_ != $self } @clients;

         # Inform the others
         $_->write( "$peeraddr leaves\n" ) for @clients;
      },
   );

   $loop->add( $stream );
   push @clients, $stream;
}
