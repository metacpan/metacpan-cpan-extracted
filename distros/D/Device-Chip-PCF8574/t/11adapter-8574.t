#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter 0.08;  # ->read

use Device::Chip::PCF8574;

my $chip = Device::Chip::PCF8574->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

my $gpios = $chip->as_adapter->make_protocol( "GPIO" )->get;

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
      $gpios->read_gpios( [ 'P0' ] )->get,
      { P0 => !!0 },
      '$gpios->read_gpios returns value'
   );

   $adapter->check_and_clear( '$gpios->read_gpios' );
}

# write
{
   $adapter->expect_write( "\xFD" );

   $gpios->write_gpios( { P1 => 0 } )->get;

   $adapter->check_and_clear( '$gpios->write_gpios' );
}

done_testing;
