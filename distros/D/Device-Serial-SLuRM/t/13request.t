#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Future::IO 0.05;

use Future::AsyncAwait;

use Device::Serial::SLuRM;

use Digest::CRC qw( crc8 );

my $controller = Test::Future::IO->controller;

my $slurm = Device::Serial::SLuRM->new( fh => "DummyFH" );

sub with_crc8
{
   my ( $data ) = @_;
   return pack "a* C", $data, crc8( $data );
}

# Send request (ideal)
{
   $controller->use_sysread_buffer( "DummyFH" );

   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x31\x03" ) . "req" ) )
      ->will_write_sysread_buffer_later( "DummyFH",
         "\x55" . with_crc8( with_crc8( "\xB1\x03" ) . "res" ) );
   $controller->expect_sleep( 0.05 )
      ->will_return( my $retransmit_f = Future->new );
   # ACK is sent twice
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC1\x00" ) ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC1\x00" ) ) );

   is( await $slurm->request( "req" ), "res",
      '->request runs command and yields response' );

   ok( $retransmit_f->is_cancelled, 'Retransmit timer is cancelled' );

   $controller->check_and_clear( '->request' );

   $slurm->stop;
}

# Send request (errored)
{
   $controller->use_sysread_buffer( "DummyFH" );

   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x32\x03" ) . "req" ) )
      ->will_write_sysread_buffer_later( "DummyFH",
         "\x55" . with_crc8( with_crc8( "\xE2\x03" ) . "err" ) );
   $controller->expect_sleep( 0.05 )
      ->remains_pending;
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC2\x00" ) ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC2\x00" ) ) );

   my $f = $slurm->request( "req" );
   $f->await;
   is_deeply( [ $f->failure ], [ "Received ERR packet <65.72.72>", slurm => "err" ],
      'Request future failed with error' );

   $controller->check_and_clear( '->request for error' );

   $slurm->stop;
}

# REQUEST is retransmitted
{
   $controller->use_sysread_buffer( "DummyFH" );

   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x33\x04" ) . "req2" ) );
   $controller->expect_sleep( 0.05 )
      ->will_done(); # timeout happens
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x33\x04" ) . "req2" ) ) # retransmitted
      ->will_write_sysread_buffer_later( "DummyFH",
         "\x55" . with_crc8( with_crc8( "\xB3\x04") . "res2" ) );
   $controller->expect_sleep( 0.05 )
      ->remains_pending;
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC3\x00" ) ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC3\x00" ) ) );

   is( await $slurm->request( "req2" ), "res2",
      '->request runs command and yields response after retransmit' );

   $controller->check_and_clear( '->request for retransmit' );

   $slurm->stop;
}

# No response eventually fails f
{
   $controller->use_sysread_buffer( "DummyFH" );

   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x34\x04" ) . "req3" ) );
   $controller->expect_sleep( 0.05 )
      ->will_done(); # timeout happens
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x34\x04" ) . "req3" ) );
   $controller->expect_sleep( 0.05 )
      ->will_done(); # timeout happens
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x34\x04" ) . "req3" ) );
   $controller->expect_sleep( 0.05 )
      ->will_done(); # timeout happens

   my $f = $slurm->request( "req3" );
   $f->await;
   is( scalar $f->failure, "Request timed out after 3 attempts\n",
      'Eventual failure of ->request timeout' );

   $controller->check_and_clear( '->request for timeout' );

   $slurm->stop;
}

# RESPONSEs do not need to be sequential
{
   $controller->use_sysread_buffer( "DummyFH" );

   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x35\x02" ) . "R1" ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\x36\x02" ) . "R2" ) );
   $controller->expect_sleep( 0.05 )
      ->remains_pending;
   $controller->expect_sleep( 0.05 )
      ->remains_pending
      ->will_write_sysread_buffer_later( "DummyFH",
         "\x55" . with_crc8( with_crc8( "\xB6\x02" ) . "A2" ) .
         "\x55" . with_crc8( with_crc8( "\xB5\x02" ) . "A1" ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC6\x00" ) ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC6\x00" ) ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC5\x00" ) ) );
   $controller->expect_syswrite( "DummyFH",
      "\x55" . with_crc8( with_crc8( "\xC5\x00" ) ) );

   my $f1 = $slurm->request( "R1" );
   my $f2 = $slurm->request( "R2" );

   is( scalar await $f1, "A1", 'Reply to R1' );
   is( scalar await $f2, "A2", 'Reply to R2' );

   $controller->check_and_clear( 'Responses to ->request delivered out of order' );

   $slurm->stop;
}

done_testing;
