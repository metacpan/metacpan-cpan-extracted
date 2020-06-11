#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::NoritakeGU_D;

my $chip = Device::Chip::NoritakeGU_D->new( interface => "SPI" );

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->text
{
   $adapter->expect_write( "\x44" . "\x41\x42\x43" );

   $chip->text( "ABC" )->get;

   $adapter->check_and_clear( '$chip->text' );
}

# ->clear
{
   $adapter->expect_write( "\x44" . "\x0C" );

   $chip->clear->get;

   $adapter->check_and_clear( '$chip->clear' );
}

# internal ->read method
{
   $adapter->expect_write_then_read( "\x58", 2 )
      ->returns( "\x58\x02" );

   $adapter->expect_write_then_read( "\x54", 4 )
      ->returns( "\x54\x00\x44\x45" );

   is( $chip->read( 2 )->get, "DE", '$chip->read returns data' );

   $adapter->check_and_clear( '$chip->read' );
}

done_testing;
