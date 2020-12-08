#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::PCF8563;

my $chip = Device::Chip::PCF8563->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);


# ->write_time
{
   $adapter->expect_write( "\x02" . "\x10\x11\x12\x15\x00\x02\x14" );

   await $chip->write_time( 10, 11, 12, 15, 2-1, 2014-1900, 0 );

   $adapter->check_and_clear( '$chip->write_time' );
}

# ->read_time
{
   $adapter->expect_write_then_read( "\x02", 7 )
      # chip sometimes returns junk bits as 1s
      ->returns( "\x10\x11\x92\x15\x40\x02\x14" );

   is_deeply( [ await $chip->read_time ], [ 10, 11, 12, 15, 2-1, 2014-1900, 0 ],
      '$chip->read_time returns time' );

   $adapter->check_and_clear( '$chip->read_time' );
}

done_testing;
