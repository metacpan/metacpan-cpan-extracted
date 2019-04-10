#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Device::BusPirate;
use lib "t/lib";
use TestBusPirate;

my $bp = Device::BusPirate->new(
   fh => [], # unused
);

# enter_mode
my $spi;
{
   expect_write "\x00";
   expect_read "BBIO1";
   expect_write "\x01";
   expect_read "SPI1";

   $spi = $bp->enter_mode( "SPI" )->get;
   ok( $spi, '->enter_mode( "SPI" )' );

   check_and_clear '->enter_mode SPI';
}

# configure
{
   expect_write "\x82";
   expect_read "\x01";

   $spi->configure( mode => 0 )->get;

   expect_write "\x80";
   expect_read "\x01";

   $spi->configure( ckp => 0, cke => 0 )->get;

   expect_write "\x84";
   expect_read "\x01";

   $spi->configure( cpol => 1, cpha => 1 )->get;

   expect_write "\x63";
   expect_read "\x01";

   $spi->configure( speed => "1M" )->get;

   check_and_clear '->configure';
}

# chip_select
{
   expect_write "\x02";
   expect_read "\x01";

   $spi->chip_select( 0 )->get;

   check_and_clear '->chip_select';
}

# writeread
{
   expect_write "\x11\x12\x34";
   expect_read "\x01\x56\x78";

   is( $spi->writeread( "\x12\x34" )->get, "\x56\x78",
      '->writeread yields bytes' );

   check_and_clear '->writeread';
}

# writeread_cs
{
   expect_write "\x02";
   expect_read "\x01";
   expect_write "\x11\x12\x34";
   expect_read "\x01\x56\x78";
   expect_write "\x03";
   expect_read "\x01";

   is( $spi->writeread_cs( "\x12\x34" )->get, "\x56\x78",
      '->writeread_cs yields bytes' );

   check_and_clear '->writeread_cs';
}

# aux
{
   expect_write "\x43";
   expect_read "\x01";

   $spi->aux( 1 )->get;

   check_and_clear '->aux';
}

# power, pullups
{
   expect_write "\x4B";
   expect_read "\x01";

   $spi->power( 1 )->get;

   expect_write "\x4F";
   expect_read "\x01";

   $spi->pullup( 1 )->get;

   check_and_clear '->power and ->pullup';
}

done_testing;
