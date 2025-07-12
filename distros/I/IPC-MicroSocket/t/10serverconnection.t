#!/usr/bin/perl

use v5.36;

use Test2::V0;
use Test::Future::IO 0.05;

use Object::Pad 0.807;
use Future::AsyncAwait;

use IPC::MicroSocket;

my $controller = Test::Future::IO->controller;

$controller->use_sysread_buffer( "DummyFH" )
   ->indefinitely;

my $next_subscribe;

class TestConnection {
   inherit IPC::MicroSocket::ServerConnection;

   async method on_request ( $meth, @args )
   {
      if( $meth eq "ABC" ) { return "DEF" }
      if( $meth eq "FAIL" ) { die "Oopsie\n" }
   }

   method on_subscribe { $next_subscribe->done( @_ ); }
}
my $conn = TestConnection->new(
   fh => "DummyFH",
);

my $runf = $conn->run
   ->on_fail( sub { warn "Runloop failed: @_\n" } );

# request OK
{
   $controller->expect_syswrite( "DummyFH",
      ")" . "\x02" .
         "\0\0\0\x01"."\x01" .
         "\0\0\0\x03"."DEF" );

   # TODO: We could do with a ->write_sysread_buffer_later
   $controller->write_sysread_buffer( "DummyFH",
      "(" . "\x02" .
         "\0\0\0\x01"."\x01" .
         "\0\0\0\x03"."ABC" );

   $controller->check_and_clear( 'request OK' );
}

# request fails
{
   $controller->expect_syswrite( "DummyFH",
      "#" . "\x02" .
         "\0\0\0\x01"."\x02" .
         "\0\0\0\x07"."Oopsie\n" );

   # TODO: We could do with a ->write_sysread_buffer_later
   $controller->write_sysread_buffer( "DummyFH",
      "(" . "\x02" .
         "\0\0\0\x01"."\x02" .
         "\0\0\0\x04"."FAIL" );

   $controller->check_and_clear( 'request fails' );
}

# subscribe/publish
{
   $next_subscribe = Test::Future::Deferred->new;

   $controller->write_sysread_buffer( "DummyFH",
      "+" . "\x01" .
         "\0\0\0\x01"."T" );

   is( [ await $next_subscribe ], [ "T" ],
      'on_subscribe invoked' );
   ok( $conn->is_subscribed( "T" ), '->is_subscribed after subscribe' );

   $controller->expect_syswrite( "DummyFH",
      "!" . "\x02" .
         "\0\0\0\x01"."T" .
         "\0\0\0\x07"."a thing" );

   $conn->publish( "T", "a thing" );

   $controller->check_and_clear( '->publish' );
}

$runf->cancel;

done_testing;
