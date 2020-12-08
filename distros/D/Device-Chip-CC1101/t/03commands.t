#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::CC1101;

my $chip = Device::Chip::CC1101->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->reset
{
   $adapter->expect_write( "\x30" );

   await $chip->reset;

   $adapter->check_and_clear( '->reset' );
}

# ->flush_fifos
{
   $adapter->expect_write( "\x3A" );
   $adapter->expect_write( "\x3B" );

   await $chip->flush_fifos;

   $adapter->check_and_clear( '->flush_fifos' );
}

# ->start_rx
{
   $adapter->expect_write( "\x36" );
   $adapter->expect_write_then_read( "\xF5", 1 )
      ->returns( "\x01" );
   $adapter->expect_write( "\x34" );
   # read MARCSTATE - return IDLE at first
   $adapter->expect_write_then_read( "\xF5", 1 )
      ->returns( "\x01" );
   # second attempt now ready
   $adapter->expect_write_then_read( "\xF5", 1 )
      ->returns( "\x0D" );

   await $chip->start_rx;

   $adapter->check_and_clear( '->start_rx' );
}

# ->start_tx
{
   $adapter->expect_write( "\x36" );
   $adapter->expect_write_then_read( "\xF5", 1 )
      ->returns( "\x01" );
   $adapter->expect_write( "\x35" );
   # read MARCSTATE - return IDLE at first
   $adapter->expect_write_then_read( "\xF5", 1 )
      ->returns( "\x01" );
   # second attempt now ready
   $adapter->expect_write_then_read( "\xF5", 1 )
      ->returns( "\x13" );

   await $chip->start_tx;

   $adapter->check_and_clear( '->start_tx' );
}

# Not technically "commands" as such but they are action-like primitives

# ->read_rxfifo
{
   $adapter->expect_write_then_read( "\xFB", 1 )
      ->returns( "\x04" );
   $adapter->expect_write_then_read( "\xFF", 4 )
      ->returns( "1234" );

   is( await $chip->read_rxfifo( 4 ), "1234",
      '->read_rxfifo yields bytes' );

   $adapter->check_and_clear( '->read_rxfifo' );
}

# ->write_txfifo
{
   $adapter->expect_write( "\x7F" . "ABCD" );

   await $chip->write_txfifo( "ABCD" );

   $adapter->check_and_clear( '->write_txfifo' );
}

done_testing;
