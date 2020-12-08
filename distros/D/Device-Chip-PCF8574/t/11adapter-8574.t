#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter 0.08;  # ->read

use Future::AsyncAwait;

use Device::Chip::PCF8574;

my $chip = Device::Chip::PCF8574->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

my $gpios = await $chip->as_adapter->make_protocol( "GPIO" );

# list
{
   is_deeply(
      [ $gpios->list_gpios ],
      [qw( P0 P1 P2 P3 P4 P5 P6 P7 )],
      '$gpios->list_gpios'
   );
}

# read
{
   $adapter->expect_read( 1 )->returns( "\x00" );

   is_deeply(
      await $gpios->read_gpios( [ 'P0' ] ),
      { P0 => !!0 },
      '$gpios->read_gpios returns value'
   );

   $adapter->check_and_clear( '$gpios->read_gpios' );
}

# write
{
   $adapter->expect_write( "\xFD" );

   await $gpios->write_gpios( { P1 => 0 } );

   $adapter->check_and_clear( '$gpios->write_gpios' );
}

done_testing;
