#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Async::Test;

use IO::Async::Loop;
use IO::Async::Listener;
use IO::Async::SSL;
use Socket qw( unpack_sockaddr_in );

use IO::Async::Stream 0.59;

my $loop = IO::Async::Loop->new;

testing_loop( $loop );

{
   my $a_stream;

   my $listener = IO::Async::Listener->new(
      handle_class => "IO::Async::Stream",
      on_accept => sub {
         shift;
         $a_stream = shift;
      },
   );
   $loop->add( $listener );

   my $listen_f = $listener->listen(
      family   => "inet",
      host     => "localhost",
      service  => "",
      socktype => "stream", # TODO imply

      extensions    => [ 'SSL' ],
      SSL_key_file  => "t/privkey.pem",
      SSL_cert_file => "t/server.pem",
   );

   wait_for { $listen_f->is_ready };

   my $port = $listener->read_handle->sockport;

   my @c_lines;
   my $c_stream = IO::Async::Stream->new(
      on_read => sub {
         my ( $self, $buffref, $closed ) = @_;
         push @c_lines, $1 while $$buffref =~ s/^(.*)\n//;
         return 0;
      },
   );
   $loop->add( $c_stream );

   my $conn_f = $loop->SSL_connect(
      family  => "inet",
      host    => "localhost",
      service => $port,

      SSL_verify_mode => 0,

      handle => $c_stream,
   );

   wait_for { $conn_f->is_ready and defined $a_stream };

   # Gutwrenching but no other easy way to do this
   is( $a_stream->{reader}, \&IO::Async::SSL::sslread,  '$a_stream has SSL reader' );
   is( $a_stream->{writer}, \&IO::Async::SSL::sslwrite, '$a_stream has SSL writer' );
   is( $c_stream->{reader}, \&IO::Async::SSL::sslread,  '$c_stream has SSL reader' );
   is( $c_stream->{writer}, \&IO::Async::SSL::sslwrite, '$c_stream has SSL writer' );

   $conn_f->get if $conn_f->failure;

   is_deeply( [ unpack_sockaddr_in $c_stream->read_handle->sockname ],
              [ unpack_sockaddr_in $a_stream->write_handle->peername ],
              'Sockets crossconnected' );

   my @a_lines;
   $a_stream->configure(
      on_read => sub {
         my ( $self, $buffref, $closed ) = @_;
         push @a_lines, $1 while $$buffref =~ s/^(.*)\n//;
         return 0;
      },
   );
   $loop->add( $a_stream );

   $a_stream->write( "Send a line\n" );

   wait_for { @c_lines };

   is( $c_lines[0], "Send a line", 'Line received by openssl' );

   $c_stream->write( "Reply a line\n" );

   wait_for { @a_lines };

   is( $a_lines[0], "Reply a line", 'Line received by local socket' );

   undef @c_lines;
   undef @a_lines;

   $a_stream->write( ("X" x 1_000_000 ) . "\n" );

   wait_for { @c_lines };

   is( length $c_lines[0], 1_000_000, 'Bulk data received by openssl' );

   $c_stream->write( ("X" x 1_000_000 ) . "\n" );

   wait_for { @a_lines };

   is( length $a_lines[0], 1_000_000, 'Bulk data received by local socket' );

   undef @c_lines;
   undef @a_lines;

   # syswrite() more than we sysread(), so as to try to provoke a condition where
   # SSL_read() reads all the data from the socket, making it not read-ready, but
   # that we haven't yet got all the data at the on_read level.
   $a_stream->configure( write_len => 16384, read_len => 128 );
   $c_stream->configure( write_len => 16384, read_len => 128 );

   $a_stream->write( ("X" x 1024 ) . "\n" );

   wait_for { @c_lines };

   is( length $c_lines[0], 1024, 'Data received by openssl without stall' );

   $c_stream->write( ("X" x 1024 ) . "\n" );

   wait_for { @a_lines };

   is( length $a_lines[0], 1024, 'Data received by local socket without stall' );

   $loop->remove( $listener );
   $loop->remove( $c_stream );
   $loop->remove( $a_stream );
}

# $loop->connect( SSL )
{
   my $a_stream;

   my $listener = IO::Async::Listener->new(
      handle_class => "IO::Async::Stream",
      on_accept => sub {
         shift;
         $a_stream = shift;
      },
   );
   $loop->add( $listener );

   my $listen_f = $listener->listen(
      family   => "inet",
      host     => "localhost",
      service  => "",
      socktype => "stream", # TODO imply

      extensions    => [ 'SSL' ],
      SSL_key_file  => "t/privkey.pem",
      SSL_cert_file => "t/server.pem",

      on_resolve_error => sub { die "Cannot resolve - $_[-1]\n" },
      on_listen_error  => sub { die "Cannot listen - $_[-1]\n" },
      on_ssl_error     => sub { die "SSL error - $_[-1]\n" },
   );

   wait_for { $listen_f->is_ready };

   my $port = $listener->read_handle->sockport;

   my $conn_f = $loop->connect(
      extensions => [ 'SSL' ],

      family  => "inet",
      host    => "localhost",
      service => $port,

      SSL_verify_mode => 0,

      on_resolve_error => sub { die "Cannot resolve - $_[-1]\n" },
      on_connect_error => sub { die "Cannot connect\n" },
      on_ssl_error     => sub { die "SSL error - $_[-1]\n" },

      handle => IO::Async::Stream->new,
   );

   wait_for { $conn_f->is_ready and defined $a_stream };

   $conn_f->get if $conn_f->failure;

   is_deeply( [ unpack_sockaddr_in $conn_f->get->read_handle->sockname ],
              [ unpack_sockaddr_in $a_stream->write_handle->peername ],
              'Sockets crossconnected using ->connect extensions' );
}

# connect SSL error
{
   my $listen_sock;
   my $accepted_sock;

   $loop->listen(
      family   => "inet",
      host     => "localhost",
      service  => "",
      socktype => "stream",

      on_listen => sub { $listen_sock = shift },
      on_accept => sub { $accepted_sock = shift },

      on_resolve_error => sub { die "Cannot resolve - $_[-1]\n" },
      on_listen_error  => sub { die "Cannot listen - $_[-1]\n" },
   );

   wait_for { defined $listen_sock };

   my $port = $listen_sock->sockport;

   my $connected_sock;
   my $client_errored;

   $loop->SSL_connect(
      family  => "inet",
      host    => "localhost",
      service => $port,

      SSL_verify_mode => 0,

      on_connected => sub { $connected_sock = shift },

      on_resolve_error => sub { die "Cannot resolve - $_[-1]\n" },
      on_connect_error => sub { die "Cannot connect\n" },
      on_ssl_error     => sub { $client_errored++ },
   );

   wait_for { defined $accepted_sock };

   $accepted_sock->syswrite( "A line of plaintext content\n" );

   wait_for { $client_errored };

   ok( 1, "Client socket indicates error" );
}

# connect SSL error
{
   my $listen_sock;
   my $server_errored;

   $loop->SSL_listen(
      family  => "inet",
      host    => "localhost",
      service => "",

      SSL_key_file  => "t/privkey.pem",
      SSL_cert_file => "t/server.pem",

      on_listen => sub { $listen_sock = shift },
      on_accept => sub { die "Test failed early - SSL listen succeeded" },

      on_resolve_error => sub { die "Cannot resolve - $_[-1]\n" },
      on_listen_error  => sub { die "Cannot listen - $_[-1]\n" },
      on_ssl_error     => sub { $server_errored++ },
   );

   wait_for { defined $listen_sock };

   my $port = $listen_sock->sockport;

   my $connected_sock;

   $loop->connect(
      family   => "inet",
      host     => "localhost",
      service  => $port,
      socktype => "stream",

      on_connected => sub { $connected_sock = shift },

      on_resolve_error => sub { die "Cannot resolve - $_[-1]\n" },
      on_connect_error => sub { die "Cannot connect\n" },
   );

   wait_for { defined $connected_sock };

   $connected_sock->syswrite( "A line of plaintext content\n" );

   wait_for { $server_errored };

   ok( 1, "Server socket indicates error" );
}

done_testing;
