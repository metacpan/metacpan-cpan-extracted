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
   $adapter->expect_write( "\x1E" );

   await $chip->lcd_reset;

   $adapter->check_and_clear( '->lcd_reset' );
}

{
   $adapter->expect_write( "\x1F\x80" );

   await $chip->lcd_command( 0x80 );

   $adapter->check_and_clear( '->lcd_command' );
}

{
   $adapter->expect_write( "\x20\x41" );

   await $chip->lcd_data( 0x41 );

   $adapter->check_and_clear( '->lcd_data' );
}

{
   $adapter->expect_write( "\x21Hello\0" );

   await $chip->lcd_string( "Hello" );

   $adapter->check_and_clear( '->lcd_string' );
}

{
   $adapter->expect_write( "\x23" );

   await $chip->lcd_signon;

   $adapter->check_and_clear( '->lcd_signon' );
}

{
   $adapter->expect_write( "\x24\x0A\x08\x06" );

   await $chip->lcd_backlight( 10, 8, 6 );

   $adapter->check_and_clear( '->lcd_backlight' );
}

done_testing;
