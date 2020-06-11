#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::NoritakeGU_D;

my $chip = Device::Chip::NoritakeGU_D->new( interface => "I2C" );

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->text
{
   $adapter->expect_write( "\x41\x42\x43" );

   $chip->text( "ABC" )->get;

   $adapter->check_and_clear( '$chip->text' );
}

# ->clear
{
   $adapter->expect_write( "\x0C" );

   $chip->clear->get;

   $adapter->check_and_clear( '$chip->clear' );
}

# internal ->read method
{
   $adapter->expect_read( 2 )
      ->returns( "\x44\x45" );

   is( $chip->read( 2 )->get, "DE", '$chip->read returns data' );

   $adapter->check_and_clear( '$chip->read' );
}

done_testing;
