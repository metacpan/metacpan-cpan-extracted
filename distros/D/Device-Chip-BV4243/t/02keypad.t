#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::BV4243;

my $chip = Device::Chip::BV4243->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

{
   $adapter->expect_write( "\x01" );

   await $chip->clear_keys;

   $adapter->check_and_clear( '->clear_keys' );
}

{
   $adapter->expect_write_then_read( "\x02", 1 )
      ->returns( "\x01" );

   is( await $chip->get_keycount, 1,
      '->get_keycount yields count' );

   $adapter->check_and_clear( '->get_keycount' );
}

{
   $adapter->expect_write_then_read( "\x03", 1 )
      ->returns( "\x0A" );

   is( await $chip->get_key, 10,
      '->get_key yields key' );

   $adapter->check_and_clear( '->get_key' );
}

{
   $adapter->expect_write_then_read( "\x04\x0A", 1 )
      ->returns( "\x01" );

   is( await $chip->find_key( 10 ), 1,
      '->find_key yields position' );

   $adapter->check_and_clear( '->find_key' );
}

{
   $adapter->expect_write_then_read( "\x05", 1 )
      ->returns( "\xE0" );

   is( await $chip->get_scancode, 0xE0,
      '->get_scancode yields code' );

   $adapter->check_and_clear( '->get_scancode' );
}

{
   $adapter->expect_write_then_read( "\x0A", 16 )
      ->returns( "\x01\x23\x45\x67\x89\xAB\xCD\xEF\x10\x32\x54\x76\x98\xBA\xDC\xFE" );

   is( [ await $chip->read_chan ],
      [ 291, 17767, 35243, 52719, 4146, 21622, 39098, 56574 ],
      '->read_chan yields sensor values' );

   $adapter->check_and_clear( '->read_chan' );
}

{
   $adapter->expect_write_then_read( "\x0B", 16 )
      ->returns( "\x00\x02\x00\x05\x00\x07\xCD\xEF\x00\x01\x00\x03\x00\x04\xDC\xFE" );

   is( [ await $chip->read_delta ],
      [ 2, 5, 7, 52719, 1, 3, 4, 56574 ],
      '->read_delta yields sensor values' );

   $adapter->check_and_clear( '->read_delta' );
}

done_testing;
