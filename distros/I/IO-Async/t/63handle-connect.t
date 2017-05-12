#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;

use IO::Async::Loop;

use IO::Async::Handle;

use IO::Async::OS;

use IO::Socket::INET;
use Socket qw( SOCK_STREAM );

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

# Try connect(2)ing to a socket we've just created
my $listensock = IO::Socket::INET->new(
   Type      => SOCK_STREAM,
   LocalAddr => 'localhost',
   LocalPort => 0,
   Listen => 1
) or die "Cannot create listensock - $!";

my $addr = $listensock->sockname;

# ->connect to plain addr
{
   my $handle = IO::Async::Handle->new(
      on_read_ready => sub {},
      on_write_ready => sub {},
   );

   $loop->add( $handle );

   my $f = $handle->connect( addr => [ 'inet', 'stream', 0, $addr ] );

   ok( defined $f, '$handle->connect Future defined' );

   wait_for { $f->is_ready };
   $f->is_failed and $f->get;

   ok( defined $handle->read_handle, '$handle->read_handle defined after ->connect addr' );
   is( $handle->read_handle->peerport, $listensock->sockport, '$handle->read_handle->peerport after ->connect addr' );

   $listensock->accept; # drop it

   $loop->remove( $handle );
}

# ->connect to host/service
{
   my $handle = IO::Async::Handle->new(
      on_read_ready => sub {},
      on_write_ready => sub {},
   );

   $loop->add( $handle );

   my $f = wait_for_future $handle->connect(
      family   => "inet",
      socktype => "stream",
      host     => $listensock->sockhost,
      service  => $listensock->sockport,
   );

   $f->is_failed and $f->get;

   ok( defined $handle->read_handle, '$handle->read_handle defined after ->connect host/service' );
   is( $handle->read_handle->peerport, $listensock->sockport, '$handle->read_handle->peerport after ->connect host/service' );

   $listensock->accept; # drop it

   $loop->remove( $handle );
}

done_testing;
