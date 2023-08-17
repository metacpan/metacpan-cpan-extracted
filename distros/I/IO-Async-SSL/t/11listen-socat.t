#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use IO::Async::Test;

use IO::Async::OS;
use IO::Async::Loop;
use IO::Async::SSL;
use IO::Async::Listener;

use POSIX qw( WEXITSTATUS );

system( "socat -help >/dev/null 2>&1" ) == 0 or
   plan skip_all => "no socat";

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

   extensions => [ 'SSL' ],
   SSL_key_file  => "t/privkey.pem",
   SSL_cert_file => "t/server.pem",

   on_resolve_error => sub { die "Cannot resolve - $_[-1]\n" },
   on_listen_error  => sub { die "Cannot listen - $_[-1]\n" },
   on_ssl_error     => sub { die "SSL error - $_[-1]\n" },
)->get;

my $port = $listener->read_handle->sockport;

my ( $my_rd, $ssl_wr, $ssl_rd, $my_wr ) = IO::Async::OS->pipequad
   or die "Cannot pipequad - $!";

my $kid = $loop->spawn_child(
   setup => [
      stdin  => $ssl_rd,
      stdout => $ssl_wr,
   ],
   command => [ "socat", "OPENSSL:localhost:$port,verify=0", "STDIO" ],
   on_exit => sub {
      my ( $pid, $exitcode ) = @_;

      my $status = WEXITSTATUS( $exitcode );

      $status == 0 or die "socat failed with $status\n";
   },
);

close $ssl_rd;
close $ssl_wr;

END { kill TERM => $kid if defined $kid }

my @socat_lines;
$loop->add( my $socat_stream = IO::Async::Stream->new(
   read_handle => $my_rd,
   write_handle => $my_wr,

   on_read => sub {
      my ( $stream, $buffref, $closed ) = @_;
      push @socat_lines, $1 while $$buffref =~ s/^(.*)\n//;
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

undef @socat_lines;

$sslstream->write( "Send a line\n" );

wait_for { @socat_lines };

is( $socat_lines[0], "Send a line", 'Line received by socat' );

$socat_stream->write( "Reply a line\n" );

wait_for { @local_lines };

is( $local_lines[0], "Reply a line", 'Line received by local socket' );

undef @socat_lines;
undef @local_lines;

done_testing;
