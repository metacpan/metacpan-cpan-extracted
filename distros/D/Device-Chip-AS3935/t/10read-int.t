#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::AS3935;

my $chip = Device::Chip::AS3935->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

{
   $adapter->expect_write_then_read( "\x03", 1 )
      ->returns( "\x00" );

   is( await $chip->read_int,
      { INT_NH => '', INT_D => '', INT_L => '' },
      '$chip->read_int when idle'
   );

   $adapter->expect_write_then_read( "\x03", 1 )
      ->returns( "\x01" );

   is( await $chip->read_int,
      { INT_NH => 1, INT_D => '', INT_L => '' },
      '$chip->read_int when noise detected'
   );

   $adapter->expect_write_then_read( "\x03", 1 )
      ->returns( "\x02" );

   is( await $chip->read_int,
      { INT_NH => '', INT_D => '', INT_L => '' },
      '$chip->read_int when disturbed'
   );

   $adapter->expect_write_then_read( "\x03", 1 )
      ->returns( "\x08" );

   is( await $chip->read_int,
      { INT_NH => '', INT_D => '', INT_L => 1 },
      '$chip->read_int when lightning detected'
   );

   $adapter->check_and_clear( '$chip->read_int' );
}

done_testing;
