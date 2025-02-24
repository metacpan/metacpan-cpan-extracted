#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::AVR_HVSP;

my $chip = Device::Chip::AVR_HVSP->new;
my $adapter = Test::Device::Chip::Adapter->new;

# ->mount already resets GPIO lines

$adapter->expect_write_gpios( { sdi => 0, sii => 0, sci => 0 } );
$adapter->expect_tris_gpios( [ 'sdo' ] );

await $chip->mount( $adapter );

$adapter->check_and_clear( 'mount' );

# ->_transfer
# This isn't really part of API but testing it here now will allow us to test
# the higher-level bits elsewhere later on using this
{
   # bit 0
   $adapter->expect_write_gpios( { sci => 1 } );
   $adapter->expect_write_gpios( { sci => 0, sdi => 0, sii => 1 } );
   $adapter->expect_read_gpios( [ 'sdo' ] )->will_done( { sdo => 0 } );
   # bit 1
   $adapter->expect_write_gpios( { sci => 1 } );
   $adapter->expect_write_gpios( { sci => 0, sdi => 1, sii => 0 } );
   $adapter->expect_read_gpios( [ 'sdo' ] )->will_done( { sdo => 0 } );
   # bit 2
   $adapter->expect_write_gpios( { sci => 1 } );
   $adapter->expect_write_gpios( { sci => 0, sdi => 0, sii => 1 } );
   $adapter->expect_read_gpios( [ 'sdo' ] )->will_done( { sdo => 1 } );
   # bit 3
   $adapter->expect_write_gpios( { sci => 1 } );
   $adapter->expect_write_gpios( { sci => 0, sdi => 1, sii => 0 } );
   $adapter->expect_read_gpios( [ 'sdo' ] )->will_done( { sdo => 1 } );
   # bit 4
   $adapter->expect_write_gpios( { sci => 1 } );
   $adapter->expect_write_gpios( { sci => 0, sdi => 0, sii => 1 } );
   $adapter->expect_read_gpios( [ 'sdo' ] )->will_done( { sdo => 0 } );
   # bit 5
   $adapter->expect_write_gpios( { sci => 1 } );
   $adapter->expect_write_gpios( { sci => 0, sdi => 1, sii => 0 } );
   $adapter->expect_read_gpios( [ 'sdo' ] )->will_done( { sdo => 0 } );
   # bit 6
   $adapter->expect_write_gpios( { sci => 1 } );
   $adapter->expect_write_gpios( { sci => 0, sdi => 0, sii => 1 } );
   $adapter->expect_read_gpios( [ 'sdo' ] )->will_done( { sdo => 1 } );
   # bit 7
   $adapter->expect_write_gpios( { sci => 1 } );
   $adapter->expect_write_gpios( { sci => 0, sdi => 1, sii => 0 } );
   $adapter->expect_read_gpios( [ 'sdo' ] )->will_done( { sdo => 1 } );

   # 3 dummy bits nobody cares about
   $adapter->expect_write_gpios( { sci => 1 } );
   $adapter->expect_write_gpios( { sci => 0 } );
   $adapter->expect_write_gpios( { sci => 1 } );
   $adapter->expect_write_gpios( { sci => 0 } );
   $adapter->expect_write_gpios( { sci => 1 } );
   $adapter->expect_write_gpios( { sci => 0 } );

   is( await $chip->_transfer( 0x55, 0xAA ), 0x33,
      '->_transfer returns SDO value' );

   $adapter->check_and_clear( '_transfer' );
}

done_testing;
