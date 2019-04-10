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
my $i2c;
{
   expect_write "\x00";
   expect_read "BBIO1";
   expect_write "\x02";
   expect_read "I2C1";

   $i2c = $bp->enter_mode( "I2C" )->get;
   ok( $i2c, '->enter_mode( "I2C" )' );

   check_and_clear '->enter_mode I2C';
}

# configure
{
   expect_write "\x62";
   expect_read "\x01";

   $i2c->configure( speed => "100k" )->get;

   check_and_clear '->configure';
}

# start_bit, stop_bit
{
   expect_write "\x02";
   expect_read "\x01";

   $i2c->start_bit->get;

   expect_write "\x03";
   expect_read "\x01";

   $i2c->stop_bit->get;

   check_and_clear '->start_bit and ->stop_bit';
}

# write
{
   expect_write "\x11\x12\x34";
   expect_read "\x01\x00\x00";

   $i2c->write( "\x12\x34" )->get;

   check_and_clear '->write';
}

# read
{
   expect_write "\x04";
   expect_read "\x56";
   expect_write "\x06";
   expect_read "\x01";
   expect_write "\x04";
   expect_read "\x78";
   expect_write "\x07";
   expect_read "\x01";

   is( $i2c->read( 2 )->get, "\x56\x78",
      '->read returns bytes' );

   check_and_clear '->read';
}

# send
{
   expect_write "\x02";
   expect_read "\x01";
   expect_write "\x12\x40\x12\x34";
   expect_read "\x01\x00\x00\x00";
   expect_write "\x03";
   expect_read "\x01";

   $i2c->send( 0x20, "\x12\x34" )->get;

   check_and_clear '->send';
}

# recv
{
   expect_write "\x02";
   expect_read "\x01";
   expect_write "\x10\x43";
   expect_read "\x01\x00";
   expect_write "\x04";
   expect_read "\x56";
   expect_write "\x06";
   expect_read "\x01";
   expect_write "\x04";
   expect_read "\x78";
   expect_write "\x07";
   expect_read "\x01";
   expect_write "\x03";
   expect_read "\x01";

   is( $i2c->recv( 0x21, 2 )->get, "\x56\x78",
      '->recv returns bytes' );

   check_and_clear '->recv';
}

# send_then_recv
{
   expect_write "\x02";
   expect_read "\x01";
   expect_write "\x12\x44\x89\xAB";
   expect_read "\x01\x00\x00\x00";
   expect_write "\x02";
   expect_read "\x01";
   expect_write "\x10\x45";
   expect_read "\x01\x00";
   expect_write "\x04";
   expect_read "\xCD";
   expect_write "\x07";
   expect_read "\x01";
   expect_write "\x03";
   expect_read "\x01";

   is( $i2c->send_then_recv( 0x22, "\x89\xAB", 1 )->get, "\xCD",
      '->send_then_recv returns bytes' );

   check_and_clear '->send_then_recv';
}

# aux
{
   expect_write "\x42";
   expect_read "\x01";

   $i2c->aux( 1 )->get;

   check_and_clear '->aux';
}

# power, pullups
{
   expect_write "\x4A";
   expect_read "\x01";

   $i2c->power( 1 )->get;

   expect_write "\x4E";
   expect_read "\x01";

   $i2c->pullup( 1 )->get;

   check_and_clear '->power and ->pullup';
}

done_testing;
