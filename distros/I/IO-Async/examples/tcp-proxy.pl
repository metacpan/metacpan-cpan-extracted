#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Loop;
use IO::Async::Stream;
use IO::Async::Listener;

my $LISTEN_PORT = 12345;
my $CONNECT_HOST = "localhost";
my $CONNECT_PORT = 80;

my $loop = IO::Async::Loop->new;

my $listener = ProxyListener->new;

$loop->add( $listener );

$listener->listen(
   service  => $LISTEN_PORT,
   socktype => 'stream',
)->get;

$loop->run;

package ProxyListener;
use base qw( IO::Async::Listener );

sub on_stream
{
   my $self = shift;
   my ( $stream1 ) = @_;

   # $socket is just an IO::Socket reference
   my $socket1 = $stream1->read_handle;
   my $peeraddr = $socket1->peerhost . ":" . $socket1->peerport;

   print STDERR "Accepted new connection from $peeraddr\n";

   $loop->connect(
      host    => $CONNECT_HOST,
      service => $CONNECT_PORT,

      on_stream => sub {
         my ( $stream2 ) = @_;

         $stream1->configure(
            on_read => sub {
               my ( $self, $buffref, $eof ) = @_;
               # Just copy all the data
               $stream2->write( $$buffref ); $$buffref = "";
               return 0;
            },
            on_closed => sub {
               $stream2->close_when_empty;
               print STDERR "Connection from $peeraddr closed\n";
            },
         );

         $stream2->configure(
            on_read => sub {
               my ( $self, $buffref, $eof ) = @_;
               # Just copy all the data
               $stream1->write( $$buffref ); $$buffref = "";
               return 0;
            },
            on_closed => sub {
               $stream1->close_when_empty;
               print STDERR "Connection to $CONNECT_HOST:$CONNECT_PORT closed\n";
            },
         );

         $loop->add( $stream1 );
         $loop->add( $stream2 );
      },

      on_resolve_error => sub { print STDERR "Cannot resolve - $_[0]\n"; },
      on_connect_error => sub { print STDERR "Cannot connect\n"; },
   );
}
