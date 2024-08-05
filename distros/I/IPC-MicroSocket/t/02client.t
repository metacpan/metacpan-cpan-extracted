#!/usr/bin/perl

use v5.36;

use Test2::V0;
use Test::Future::IO 0.05;

use Object::Pad 0.800;
use Future::AsyncAwait;

use IPC::MicroSocket::Client;

my $controller = Test::Future::IO->controller;

$controller->use_sysread_buffer( "DummyFH" )
   ->indefinitely;

my $client = IPC::MicroSocket::Client->new(
   fh => "DummyFH",
);

# request OK
{
   $controller->expect_syswrite( "DummyFH",
      "(" . "\x03" .
         "\0\0\0\x01"."\x01" .
         "\0\0\0\x03"."123" .
         "\0\0\0\x03"."456" )
      ->will_write_sysread_buffer_later( "DummyFH",
         ")" . "\x03" .
            "\0\0\0\x01"."\x01" .
            "\0\0\0\x02"."78" .
            "\0\0\0\x02"."90" );

   is( [ await $client->request( "123", "456" ) ], [ "78", "90" ],
      'Result of ->request' );

   $controller->check_and_clear( '->request' );
}

# request fails
{
   $controller->expect_syswrite( "DummyFH",
      "(" . "\x02" .
         "\0\0\0\x01"."\x02" .
         "\0\0\0\x05"."bloop" )
      ->will_write_sysread_buffer_later( "DummyFH",
         "#" . "\x02" .
            "\0\0\0\x01"."\x02" .
            "\0\0\0\x07"."failure" );

   is( eval { await $client->request( "bloop" ); 1 } ? undef : $@,
      'failure',
      'Failure from ->request' );

   $controller->check_and_clear( '->request fails' );
}

# subscribe
{
   $controller->expect_syswrite( "DummyFH",
      "+" . "\x01" .
         "\0\0\0\x01"."T" )
      ->will_write_sysread_buffer_later( "DummyFH",
         "!" . "\x03" .
            "\0\0\0\x01"."T" .
            "\0\0\0\x03"."the" .
            "\0\0\0\x07"."message" );

   my $next_event_f = Test::Future::Deferred->new;
   my $subf = $client->subscribe( "T" => sub { $next_event_f->done( @_ ) } );
   $subf->on_fail( sub { die "FAILED @_" } );

   is( [ await $next_event_f ], [ "the", "message" ],
      'on_recv saw message' );

   $controller->check_and_clear( '->subscribe' );

   $subf->cancel;
}

done_testing;
