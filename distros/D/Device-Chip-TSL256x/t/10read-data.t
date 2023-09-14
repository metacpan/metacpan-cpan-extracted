#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::TSL256x;

my $chip = Device::Chip::TSL256x->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

{
   $adapter->expect_write_then_read( "\x8C", 2 )
      ->returns( "\x34\x12" );

   is( await $chip->read_data0, 0x1234,
      '->read_data0 returns data' );

   $adapter->check_and_clear( '$chip->read_data0' );
}

{
   $adapter->expect_write_then_read( "\x8E", 2 )
      ->returns( "\x78\x56" );

   is( await $chip->read_data1, 0x5678,
      '->read_data1 returns data' );

   $adapter->check_and_clear( '$chip->read_data1' );
}

{
   $adapter->expect_write_then_read( "\x8C", 4 )
      ->returns( "\x34\x12\x78\x56" );

   is( [ await $chip->read_data ],
              [ 0x1234, 0x5678 ],
      '->read_data returns data' );

   $adapter->check_and_clear( '$chip->read_data' );
}

done_testing;
