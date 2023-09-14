#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter 0.08;  # ->read

use Future::AsyncAwait;

use Device::Chip::PCF8575;

my $chip = Device::Chip::PCF8575->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

my $gpios = await $chip->as_adapter->make_protocol( "GPIO" );

# list
{
   is(
      [ $gpios->list_gpios ],
      [qw( P00 P01 P02 P03 P04 P05 P06 P07 ),
       qw( P10 P11 P12 P13 P14 P15 P16 P17 )],
      '$gpios->list_gpios'
   );
}

# read
{
   $adapter->expect_read( 2 )->returns( "\x00\x00" );

   is(
      await $gpios->read_gpios( [ 'P00' ] ),
      { P00 => !!0 },
      '$gpios->read_gpios returns value'
   );

   $adapter->check_and_clear( '$gpios->read_gpios' );
}

# write
{
   $adapter->expect_write( "\xFD\xFF" );

   await $gpios->write_gpios( { P01 => 0 } );

   $adapter->check_and_clear( '$gpios->write_gpios' );
}

done_testing;
