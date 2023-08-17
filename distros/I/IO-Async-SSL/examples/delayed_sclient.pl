#!/usr/bin/perl

use v5.14;
use warnings;

use Getopt::Long;
use IO::Async::Loop;
use IO::Async::Protocol::Stream;
use IO::Async::Signal;
use IO::Async::Stream 0.54; # ->new_close_future
use IO::Async::SSL;
use IO::Async::SSLStream;

my $DUMPCERT;
my $NO_VERIFY;
my $FAMILY;
GetOptions(
   'd|dumpcert'   => \$DUMPCERT,
   'nv|no-verify' => \$NO_VERIFY,
   '4|ipv4'       => sub { $FAMILY = "inet" },
   '6|ipv6'       => sub { $FAMILY = "inet6" },
) or exit 1;

my $HOST = shift @ARGV or die "Need HOST";
my $PORT = shift @ARGV or die "Need PORT";

my $loop = IO::Async::Loop->new;

my ( $socketstream, $stdiostream );
my $peeraddr;

$socketstream = IO::Async::Stream->new(
   on_read => sub {
      my ( undef, $buffref, $closed ) = @_;

      # Turn CRLFs into plain \n by stripping \r
      $$buffref =~ s/\r//g;
      $stdiostream->write( $$buffref );
      $$buffref = "";

      return 0;
   },

   on_closed => sub {
      print STDERR "Closed connection to $peeraddr\n";
      $stdiostream->close_when_empty;
   },
);
$loop->add( $socketstream );

$stdiostream = IO::Async::Stream->new(
   read_handle  => \*STDIN,
   write_handle => \*STDOUT,

   on_read => sub {
      my ( undef, $buffref, $closed ) = @_;

      # Turn plain \n into CRLFs
      $$buffref =~ s/\n/\x0d\x0a/g;
      $socketstream->write( $$buffref );
      $$buffref = "";

      return 0;
   },

   on_closed => sub {
      $socketstream->close_when_empty;
   },
);
$loop->add( $stdiostream );

$loop->connect(
   host     => $HOST,
   service  => $PORT,
   family   => $FAMILY,
   socktype => 'stream',

   handle => $socketstream,
)->get;

my $socket = $socketstream->read_handle;
$peeraddr = $socket->peerhost . ":" . $socket->peerport;

print STDERR "Connected to $peeraddr. Send SIGQUIT (Ctrl-\\) to start SSL upgrade\n";

my $signal = IO::Async::Signal->new(
   name => "QUIT",
   on_receipt => sub {
      my ( $self ) = @_;
      $loop->remove( $self );

      $loop->remove( $socketstream );
      $loop->SSL_upgrade(
         handle => $socketstream->read_handle,
         ( $NO_VERIFY ? ( SSL_verify_mode => 0 ) : () ),
      )->on_done( sub {
         print STDERR "Now upgraded to SSL\n"; # TODO: get actual name somehow?
         $loop->add( $socketstream );

         if( $DUMPCERT ) {
            my $socket = $socketstream->read_handle;
            print STDERR Net::SSLeay::PEM_get_string_X509($socket->peer_certificate) . "\n";
         }
      })->on_fail( sub {
         die "Cannot upgrade to SSL - $_[0]\n";
      });
   },
);
$loop->add( $signal );

$loop->await( $socketstream->new_close_future, $stdiostream->new_close_future );
