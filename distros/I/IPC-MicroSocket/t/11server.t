#!/usr/bin/perl

use v5.36;

use Test2::V0;
use Test::Future::IO 0.05;

use Object::Pad 0.800;
use Future::AsyncAwait;

use IPC::MicroSocket::Server;

my $controller = Test::Future::IO->controller;

my $latest_command;

class TestServer {
   apply IPC::MicroSocket::Server;

   async method on_connection_request ( $conn, $cmd, @args )
   {
      $latest_command = $cmd;
      return "Response<$cmd>";
   }

   method on_connection_subscribe {}
}
my $server = TestServer->new(
   fh => "ListenFH",
);

# We have to set this up before connection is accepted
$controller->use_sysread_buffer( "ClientFH" )
   ->indefinitely;

my $client;
my $run_f;
# A new client is accepted
{
   $controller->expect_accept( "ListenFH" )
      ->will_done( "ClientFH" );
   $controller->expect_accept( "ListenFH" )
      ->remains_pending;

   $run_f = $server->run;
   $run_f->on_fail( sub { die "@_" } );

   # UGH this is terrible
   Test::Future::Deferred->done_later->await until $server->clients > 0;

   # TODO: Maybe think about some assertions on server state to find its
   # clients?

   ok( !$run_f->is_ready, '->run future remains pending' );
   $controller->check_and_clear( 'client connect' );
}

# accept a command
{
   $controller->expect_syswrite( "ClientFH",
      ")" . "\x02" .
         "\0\0\0\x01"."\x01" .
         "\0\0\0\x11"."Response<REQUEST>" );

   $controller->write_sysread_buffer( "ClientFH",
      "(" . "\x02" .
         "\0\0\0\x01"."\x01" .
         "\0\0\0\x07"."REQUEST" );

   is( $latest_command, "REQUEST", 'Server saw request' );

   $controller->check_and_clear( 'request/response' );
}

# publish to clients
{
   $controller->write_sysread_buffer( "ClientFH",
      "+" . "\x01" .
         "\0\0\0\x05"."TOPIC" );

   $controller->expect_syswrite( "ClientFH",
      "!" . "\x02" .
         "\0\0\0\x05"."TOPIC" .
         "\0\0\0\x07"."message" );

   $server->publish( "TOPIC", "message" );

   $controller->check_and_clear( '->publish' );

   $server->publish( "DIFFERENT", "message" ); # nothing should happen

   $controller->check_and_clear( '->publish unsubscribed' );
}

done_testing;
