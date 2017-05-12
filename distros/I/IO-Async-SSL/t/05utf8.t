#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;
use Test::Identity;

use IO::Async::Test;

use IO::Async::OS;
use IO::Async::Loop;
use IO::Async::SSL;
use IO::Async::Stream;

use Encode qw( encode_utf8 decode_utf8 );

my $loop = IO::Async::Loop->new;

# A message containing non-8859-1 characters as this tests Perl more interestingly
my $message = "Ĉu vi ĉi tio vidas?";

sub chomped { chomp( my $tmp = $_[0] ); return $tmp }

testing_loop( $loop );

{
   my ( $server_sock, $client_sock ) = IO::Async::OS->socketpair or
      die "Cannot socketpair - $!";

   $server_sock->blocking( 0 );
   $client_sock->blocking( 0 );

   my $server_stream = IO::Async::Stream->new(
      handle => $server_sock,
      on_read => sub { 0 },
   );
   $loop->add( $server_stream );

   my $client_stream = IO::Async::Stream->new(
      handle => $client_sock,
      on_read => sub { 0 },
   );
   $loop->add( $client_stream );

   my $server_f = $loop->SSL_upgrade(
      handle => $server_stream,
      SSL_server => 1,
      SSL_key_file  => "t/privkey.pem",
      SSL_cert_file => "t/server.pem",
   );

   my $client_f = $loop->SSL_upgrade(
      handle => $client_stream,
      SSL_verify_mode => 0,
   );

   wait_for { $server_f->is_ready and $client_f->is_ready };

   # Check that we can pass UTF-8 bytes unmolested
   my $bytes = encode_utf8( $message );

   $client_stream->write( "$bytes\n" );

   my $read_f = $server_stream->read_until( "\n" );
   wait_for { $read_f->is_ready };
   is( decode_utf8( chomped $read_f->get ), $message,
      'UTF-8 string unmolested' );

   # Check further that the bytes remain umolested even if they somehow end
   # up with the SvUTF8 flag set
   utf8::upgrade( $bytes );

   $client_stream->write( "$bytes\n" );

   $read_f = $server_stream->read_until( "\n" );
   wait_for { $read_f->is_ready };
   is( decode_utf8( chomped $read_f->get ), $message,
      'UTF-8 string unmolested even with SvUTF8' );
}

done_testing;
