#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::MPL3115A2;

my $chip = Device::Chip::MPL3115A2->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# start_oneshot
{
   # TODO: This only needs to read one of the bytes in practice
   $adapter->expect_write_then_read( "\x26", 3 )
      ->returns( "\x00\x00\x00" );
   $adapter->expect_write( "\x26" . "\x02" );

   $chip->start_oneshot->get;

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

   $chip->busywait_oneshot->get;

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

   $chip->oneshot->get;

   $adapter->check_and_clear( '$chip->oneshot' );
}

done_testing;
