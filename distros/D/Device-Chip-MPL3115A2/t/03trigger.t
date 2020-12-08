#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::MPL3115A2;

my $chip = Device::Chip::MPL3115A2->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# start_oneshot
{
   # TODO: This only needs to read one of the bytes in practice
   $adapter->expect_write_then_read( "\x26", 3 )
      ->returns( "\x00\x00\x00" );
   $adapter->expect_write( "\x26" . "\x02" );

   await $chip->start_oneshot;

   $adapter->check_and_clear( '$chip->start_oneshot' );
}

# busywait_oneshot
{
   $adapter->expect_write_then_read( "\x26", 1 )
      ->returns( "\x02" );
   $adapter->expect_write_then_read( "\x26", 1 )
      ->returns( "\x02" );
   $adapter->expect_write_then_read( "\x26", 1 )
      ->returns( "\x00" );

   await $chip->busywait_oneshot;

   $adapter->check_and_clear( '$chip->busywait_oneshot' );
}

# oneshot
{
   # CTRLREG is cached so no re-read here
   $adapter->expect_write( "\x26" . "\x02" );
   $adapter->expect_write_then_read( "\x26", 1 )
      ->returns( "\x02" );
   $adapter->expect_write_then_read( "\x26", 1 )
      ->returns( "\x02" );
   $adapter->expect_write_then_read( "\x26", 1 )
      ->returns( "\x00" );

   await $chip->oneshot;

   $adapter->check_and_clear( '$chip->oneshot' );
}

done_testing;
