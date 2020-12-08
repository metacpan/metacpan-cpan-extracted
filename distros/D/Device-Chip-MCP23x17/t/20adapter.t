#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::MCP23S17;

my $chip = Device::Chip::MCP23S17->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

my $protocol = $chip->as_adapter->make_protocol( "GPIO" );
ok( $protocol, 'defined $protocol' );

is_deeply( [ $protocol->list_gpios ],
   [qw( A0 A1 A2 A3 A4 A5 A6 A7 B0 B1 B2 B3 B4 B5 B6 B7 )],
   '->list_gpios' );

{
   # OLAT
   $adapter->expect_write( "\x40\x14\x03" );
   # IODIR
   $adapter->expect_write( "\x40\x00\xFC" );

   await $protocol->write_gpios( { A0 => 1, A1 => 1 } );

   $adapter->check_and_clear( '->write_gpios' );
}

{
   # IODIR
   $adapter->expect_write( "\x40\x00\xFF" );
   # GPIO
   $adapter->expect_readwrite( "\x41\x12\x00\x00" )
      ->returns( "\x00\x00\x02\x00" );

   is_deeply( await $protocol->read_gpios( [qw( A0 A1 )] ),
      { A0 => 0, A1 => 1 }, '->read_gpios returns pin levels' );

   $adapter->check_and_clear( '->read_gpios' );
}

done_testing;
