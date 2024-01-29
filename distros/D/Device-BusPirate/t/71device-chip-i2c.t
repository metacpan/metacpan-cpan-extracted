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
   expect_write "\x02";
   expect_read "I2C1";

   $proto = await $adapter->make_protocol( "I2C" );

   check_and_clear '->make_protocol'
}

# configure
{
   expect_write "\x62";
   expect_write "\x44";
   expect_read "\x01";
   expect_read "\x01";

   await $proto->configure(
      addr        => 0x40,
      max_bitrate => 100E3,
   );

   check_and_clear '->configure';
}

# write
{
   expect_write "\x02"; # START
   expect_read "\x01";
   expect_write "\x12\x80\x20\x40"; # WRITE
   expect_read "\x01\x00\x00\x00";
   expect_write "\x03"; # STOP
   expect_read "\x01";

   await $proto->write( "\x20\x40" );

   check_and_clear '->write';
}

# read
{
   expect_write "\x02"; # START
   expect_read "\x01";
   expect_write "\x10\x81"; # WRITE
   expect_read "\x01\x00";
   expect_write "\x04"; # READ1
   expect_read "\x80";
   expect_write "\x06"; # ACK
   expect_read "\x01";
   expect_write "\x04"; # READ1
   expect_read "\x10";
   expect_write "\x07"; # NACK
   expect_read "\x01";
   expect_write "\x03"; # STOP
   expect_read "\x01";

   is( await $proto->read( 2 ), "\x80\x10", '->read returns bytes' );

   check_and_clear '->read';
}

# write_then_read
{
   expect_write "\x02"; # START
   expect_read "\x01";
   expect_write "\x12\x80\x01\x02"; # WRITE
   expect_read "\x01\x00\x00\x00";
   expect_write "\x02"; # START
   expect_read "\x01";
   expect_write "\x10\x81"; # WRITE
   expect_read "\x01\x00";
   expect_write "\x04"; # READ1
   expect_read "\x03";
   expect_write "\x06"; # ACK
   expect_read "\x01";
   expect_write "\x04"; # READ1
   expect_read "\x04";
   expect_write "\x07"; # NACK
   expect_read "\x01";
   expect_write "\x03"; # STOP
   expect_read "\x01";

   is( await $proto->write_then_read( "\x01\x02", 2 ), "\x03\x04",
      '->write_then_read returns bytes' );

   check_and_clear '->write_then_read';
}

# custom double-write/double-read transaction
{
   expect_write "\x02"; # START
   expect_read "\x01";
   expect_write "\x11\x80\x41"; # WRITE
   expect_read "\x01\x00\x00";
   expect_write "\x02"; # START
   expect_read "\x01";
   expect_write "\x10\x81"; # WRITE
   expect_read "\x01\x00";
   expect_write "\x04"; # READ1
   expect_read "\x61";
   expect_write "\x07"; # NACK
   expect_read "\x01";
   expect_write "\x02"; # START
   expect_read "\x01";
   expect_write "\x11\x80\x42"; # WRITE
   expect_read "\x01\x00\x00";
   expect_write "\x02"; # START
   expect_read "\x01";
   expect_write "\x10\x81"; # WRITE
   expect_read "\x01\x00";
   expect_write "\x04"; # READ1
   expect_read "\x62";
   expect_write "\x07"; # NACK
   expect_read "\x01";
   expect_write "\x03"; # STOP
   expect_read "\x01";

   is( await $proto->txn(async sub {
      my ( $helper ) = @_;

      await $helper->write( "A" );
      my $x = await $helper->read( 1 );
      await $helper->write( "B" );
      my $y = await $helper->read( 1 );
      return $x . $y;
   }), "ab", '->txn yields result' );

   check_and_clear '->txn';
}

# concurrency
{
   my $proto2 = await $adapter->make_protocol( "I2C" );

   check_and_clear '->make_protocol 2';

   expect_write "\x44";
   expect_read "\x01";

   await $proto2->configure( addr => 0x42 );

   check_and_clear '->configure 2';

   expect_write "\x02"; # START
   expect_read "\x01";
   expect_write "\x11\x80\x31"; # WRITE
   expect_read "\x01\x00\x00";
   expect_write "\x03"; # STOP
   expect_read "\x01";

   expect_write "\x02"; # START
   expect_read "\x01";
   expect_write "\x11\x84\x32"; # WRITE
   expect_read "\x01\x00\x00";
   expect_write "\x03"; # STOP
   expect_read "\x01";

   my $f1 = $proto->write( "1" );
   my $f2 = $proto2->write( "2" );

   await $f1;
   await $f2;

   check_and_clear 'two concurrent ->write';

   # DESTROY will try to shutdown
   expect_write "\x40";
   expect_read "\x01";
}

# DESTROY will try to shutdown
expect_write "\x40";
expect_read "\x01";

done_testing;
