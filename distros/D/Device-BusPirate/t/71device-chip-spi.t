#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Future::AsyncAwait;

use Device::BusPirate;
use Device::Chip::Adapter::BusPirate;

use lib "t/lib";
use TestBusPirate;

my $adapter = Device::Chip::Adapter::BusPirate->new( fh => [] );

my $proto;

# enter_mode
{
   expect_write "\x00";
   expect_read "BBIO1";
   expect_write "\x01";
   expect_read "SPI1";

   # implicit configure
   expect_write "\x8C";
   expect_read "\x01";

   $proto = await $adapter->make_protocol( "SPI" );

   check_and_clear '->make_protocol'
}

# configure
{
   expect_write "\x8A";
   expect_read "\x01";

   await $proto->configure(
      mode => 0,
   );

   check_and_clear '->configure';
}

# readwrite
{
   expect_write "\x02";
   expect_read "\x01";
   expect_write "\x11\x12\x34";
   expect_read "\x01\x56\x78";
   expect_write "\x03";
   expect_read "\x01";

   is( await $proto->readwrite( "\x12\x34" ), "\x56\x78",
      '->writeread yields bytes' );

   check_and_clear '->readwrite';
}

# write
{
   expect_write "\x02";
   expect_read "\x01";
   expect_write "\x11\x12\x34";
   expect_read "\x01XX";
   expect_write "\x03";
   expect_read "\x01";

   await $proto->write( "\x12\x34" );

   check_and_clear '->write';
}

# read
{
   expect_write "\x02";
   expect_read "\x01";
   expect_write "\x11\x00\x00"; ## these bytes are fragile; might be FFFF or 0000
   expect_read "\x01rr";
   expect_write "\x03";
   expect_read "\x01";

   is( await $proto->read( 2 ), "rr",
      '->read yields bytes' );

   check_and_clear '->read';
}

# write_then_read
{
   expect_write "\x02";
   expect_read "\x01";
   expect_write "\x11\x01\x02";
   expect_read "\x01xx";
   expect_write "\x11\x00\x00"; ## these bytes are fragile; might be FFFF or 0000
   expect_read "\x01\x03\x04";
   expect_write "\x03";
   expect_read "\x01";

   is( await $proto->write_then_read( "\x01\x02", 2 ), "\x03\x04",
      '->write_then_read returns bytes' );

   check_and_clear '->write_then_read';
}

done_testing;
