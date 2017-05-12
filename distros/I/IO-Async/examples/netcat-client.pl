#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Loop;
use IO::Async::Stream;

my $CRLF = "\x0d\x0a"; # because \r\n is not portable

my $HOST = shift @ARGV or die "Need HOST";
my $PORT = shift @ARGV or die "Need PORT";

my $loop = IO::Async::Loop->new;

my $socket = $loop->connect(
   host     => $HOST,
   service  => $PORT,
   socktype => 'stream',
)->get;

# $socket is just an IO::Socket reference
my $peeraddr = $socket->peerhost . ":" . $socket->peerport;

print STDERR "Connected to $peeraddr\n";

# We need to create a cross-connected pair of Streams. Can't do that
# easily without a temporary variable
my ( $socketstream, $stdiostream );

$socketstream = IO::Async::Stream->new(
   handle => $socket,

   on_read => sub {
      my ( undef, $buffref, $eof ) = @_;

      while( $$buffref =~ s/^(.*)$CRLF// ) {
         $stdiostream->write( $1 . "\n" );
      }

      return 0;
   },

   on_closed => sub {
      print STDERR "Closed connection to $peeraddr\n";
      $stdiostream->close_when_empty;
   },
);
$loop->add( $socketstream );

$stdiostream = IO::Async::Stream->new_for_stdio(
   on_read => sub {
      my ( undef, $buffref, $eof ) = @_;

      while( $$buffref =~ s/^(.*)\n// ) {
         $socketstream->write( $1 . $CRLF );
      }

      return 0;
   },

   on_closed => sub {
      $socketstream->close_when_empty;
   },
);
$loop->add( $stdiostream );

$loop->await_all( $socketstream->new_close_future, $stdiostream->new_close_future );
