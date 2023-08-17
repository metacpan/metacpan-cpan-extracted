#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Identity;

use IO::Async::Test 0.68;  # wait_for_future

use Future;
use IO::Async::OS;
use IO::Async::Loop;
use IO::Async::SSL;
use IO::Async::Stream;

my $loop = IO::Async::Loop->new;

testing_loop( $loop );

# ->SSL_upgrade on IO::Async::Stream
{
   my ( $server_sock, $client_sock ) = IO::Async::OS->socketpair or
      die "Cannot socketpair - $!";

   $server_sock->blocking( 0 );
   $client_sock->blocking( 0 );

   my @server_lines;
   my $server_stream = IO::Async::Stream->new(
      handle => $server_sock,
      on_read => sub {
         my ( $self, $buffref, $closed ) = @_;
         push @server_lines, $1 while $$buffref =~ s/^(.*)\n//;
         return 0;
      },
   );
   $loop->add( $server_stream );

   my @client_lines;
   my $client_stream = IO::Async::Stream->new(
      handle => $client_sock,
      on_read => sub {
         my ( $self, $buffref, $closed ) = @_;
         push @client_lines, $1 while $$buffref =~ s/^(.*)\n//;
         return 0;
      },
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

   wait_for_future( Future->needs_all( $server_f, $client_f ) );

   identical( $server_f->get, $server_stream, 'server SSL_upgrade yields $server_stream' );
   identical( $client_f->get, $client_stream, 'client SSL_upgrade yields $client_stream' );

   # Gutwrenching but no other easy way to do this
   is( $server_stream->{reader}, \&IO::Async::SSL::sslread,  '$server_stream has SSL reader' );
   is( $server_stream->{writer}, \&IO::Async::SSL::sslwrite, '$server_stream has SSL writer' );
   is( $client_stream->{reader}, \&IO::Async::SSL::sslread,  '$client_stream has SSL reader' );
   is( $client_stream->{writer}, \&IO::Async::SSL::sslwrite, '$client_stream has SSL writer' );

   $server_stream->write( "Send a line\n" );

   wait_for { @client_lines };

   is( $client_lines[0], "Send a line", 'Line received by client' );

   $client_stream->write( "Reply a line\n" );

   wait_for { @server_lines };

   is( $server_lines[0], "Reply a line", 'Line received by server' );
}

# ->SSL_upgrade on IO handles
{
   my ( $server_sock, $client_sock ) = IO::Async::OS->socketpair or
      die "Cannot socketpair - $!";

   $server_sock->blocking( 0 );
   $client_sock->blocking( 0 );

   my ( $server_upgraded, $client_upgraded );

   my $server_f = $loop->SSL_upgrade(
      handle => $server_sock,
      SSL_server => 1,
      SSL_key_file  => "t/privkey.pem",
      SSL_cert_file => "t/server.pem",

      on_upgraded => sub { $server_upgraded++ },
      on_error => sub { die "Test failed early - $_[-1]" },
   );

   my $client_f = $loop->SSL_upgrade(
      handle => $client_sock,
      SSL_verify_mode => 0,

      on_upgraded => sub { $client_upgraded++ },
      on_error => sub { die "Test failed early - $_[-1]" },
   );

   ok( defined $server_f, 'defined ->SSL_upgrade Future for server' );
   ok( defined $client_f, 'defined ->SSL_upgrade Future for client' );

   wait_for_future( Future->needs_all( $server_f, $client_f ) );

   identical( $server_f->get, $server_sock, 'server SSL_upgrade yields $server_sock' );
   identical( $client_f->get, $client_sock, 'client SSL_upgrade yields $client_sock' );
}

{
   my ( $server_sock, $client_sock ) = IO::Async::OS->socketpair or
      die "Cannot socketpair - $!";

   $server_sock->blocking( 0 );
   $client_sock->blocking( 0 );

   my $client_errored;
   my $f = $loop->SSL_upgrade(
      handle => $client_sock,
      SSL_verify_mode => 0,

      on_upgraded => sub { die "Test failed early - SSL upgrade succeeded" },
      on_error => sub { $client_errored++ },
   );

   $server_sock->syswrite( "A line of plaintext content\n" );

   wait_for { $f->is_ready };

   ok( scalar $f->failure, '$f indicates client upgrade failure' );
   ok( $client_errored, 'on_error invoked for client upgrade failure' );
}

# An erroneous SSL_upgrade
{
   my ( $server_sock, $client_sock ) = IO::Async::OS->socketpair or
      die "Cannot socketpair - $!";

   $server_sock->blocking( 0 );
   $client_sock->blocking( 0 );

   my ( $server_upgraded, $client_upgraded );

   my $server_f = $loop->SSL_upgrade(
      handle => $server_sock,
      SSL_server => 1,
      SSL_key_file  => {},
      SSL_cert_file => {},
   );

   wait_for { $server_f->is_ready };

   # Message wording changed format a lot at 1.92
   if( eval { Net::SSLeay->VERSION( '1.92' ) } ) {
      # Don't be too dependent on the exact wording of the message
      like( $server_f->failure, qr/^Failed to load certificate from file /,
         'SSL_upgrade yields correct error on failure' );
   }
}

{
   my ( $server_sock, $client_sock ) = IO::Async::OS->socketpair or
      die "Cannot socketpair - $!";

   $server_sock->blocking( 0 );
   $client_sock->blocking( 0 );

   my $server_errored;
   my $f = $loop->SSL_upgrade(
      handle => $server_sock,
      SSL_server => 1,
      SSL_key_file  => "t/privkey.pem",
      SSL_cert_file => "t/server.pem",

      on_upgraded => sub { die "Test failed early - SSL upgrade succeeded" },
      on_error => sub { $server_errored++ },
   );

   $client_sock->syswrite( "A line of plaintext content\n" );

   wait_for { $f->is_ready };

   ok( scalar $f->failure, '$f indicates server upgrade failure' );
   ok( $server_errored, 'on_error invoked for server upgrade failure' );
}

done_testing;
