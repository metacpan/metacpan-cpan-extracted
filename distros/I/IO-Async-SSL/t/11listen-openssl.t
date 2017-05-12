#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Async::Test;

use IO::Async::OS;
use IO::Async::Loop;
use IO::Async::SSL;
use IO::Async::Listener;

use POSIX qw( WEXITSTATUS );

system( "openssl --help >/dev/null 2>&1" ) == 0 or
   plan skip_all => "no openssl";

my $loop = IO::Async::Loop->new;

testing_loop( $loop );

my $sslstream;

my $listener = IO::Async::Listener->new(
   handle_class => "IO::Async::Stream",
   on_accept => sub {
      shift;
      $sslstream = shift;
   },
);
$loop->add( $listener );

$listener->listen(
   addr => { family => "inet", socktype => "stream" },

   extensions    => [ 'SSL' ],
   SSL_key_file  => "t/privkey.pem",
   SSL_cert_file => "t/server.pem",
)->get;

my $port = $listener->read_handle->sockport;

my ( $my_rd, $ssl_wr, $ssl_rd, $my_wr ) = IO::Async::OS->pipequad
   or die "Cannot pipequad - $!";

my $kid = $loop->spawn_child(
   setup => [
      stdin  => $ssl_rd,
      stdout => $ssl_wr,
      stderr => [ open => ">", "/dev/null" ],
   ],
   command => [ "openssl", "s_client", "-host", "localhost", "-port", $port, "-quiet" ],
   on_exit => sub {
      my ( $pid, $exitcode ) = @_;

      my $status = WEXITSTATUS( $exitcode );

      $status == 0 or die "openssl failed with $status\n";
   },
);

close $ssl_rd;
close $ssl_wr;

END { kill 'TERM', $kid }

my @openssl_lines;
$loop->add( my $openssl_stream = IO::Async::Stream->new(
   read_handle => $my_rd,
   write_handle => $my_wr,

   on_read => sub {
      my ( $stream, $buffref, $closed ) = @_;
      push @openssl_lines, $1 while $$buffref =~ s/^(.*)\n//;
      return 0;
   },
) );

wait_for { defined $sslstream };

my @local_lines;

$sslstream->configure(
   on_read => sub {
      my ( $self, $buffref, $closed ) = @_;
      push @local_lines, $1 while $$buffref =~ s/^(.*)\n//;
      return 0;
   },
);

$loop->add( $sslstream );

undef @openssl_lines;

$sslstream->write( "Send a line\n" );

wait_for { @openssl_lines };

is( $openssl_lines[0], "Send a line", 'Line received by openssl' );

$openssl_stream->write( "Reply a line\n" );

wait_for { @local_lines };

is( $local_lines[0], "Reply a line", 'Line received by local socket' );

undef @openssl_lines;
undef @local_lines;

done_testing;
