#!/usr/bin/perl

use v5.36;

use Test2::V0;
use Test::Future::IO 0.05;

use Object::Pad 0.807;
use Future::AsyncAwait;

use IPC::MicroSocket;

my $controller = Test::Future::IO->controller;

my $message_f;
class TestConnection {
   inherit IPC::MicroSocket::Connection;

   method on_recv { $message_f->done( @_ ); }
}
my $conn = TestConnection->new(
   fh => "DummyFH",
);

# send
{
   $controller->expect_syswrite( "DummyFH",
      # header
      "%" .
      # argc
      "\x02" .
      # arg[0]
      "\0\0\0\x02"."AB" .
      # arg[1]
      "\0\0\0\x04"."CDEF"
   );

   await $conn->send( "%", "AB", "CDEF" );

   $controller->check_and_clear( '->send' );
}

# on_recv
{
   $controller->use_sysread_buffer( "DummyFH" );

   my $runf = $conn->_recv
      ->on_fail( sub { warn "Runloop failed: @_\n" } );

   $message_f = $runf->new;

   $controller->write_sysread_buffer( "DummyFH",
      # header
      "^" .
      # argc
      "\x03" .
      # arg[0]
      "\0\0\0\x01"."G" .
      # arg[1]
      "\0\0\0\x02"."HI" .
      # arg[2]
      "\0\0\0\x03"."JKL"
   );

   is( [ await $message_f ], [ "^", "G", "HI", "JKL" ],
      'await $message_f' );

   $runf->cancel;

   $controller->check_and_clear( 'on_recv' );
}

done_testing;
