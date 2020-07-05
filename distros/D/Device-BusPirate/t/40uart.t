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
my $uart;
{
   expect_write "\x00";
   expect_read "BBIO1";
   expect_write "\x03";
   expect_read "ART1";

   $uart = $bp->enter_mode( "UART" )->get;
   ok( $uart, '->enter_mode( "UART" )' );

   check_and_clear '->enter_mode UART';
}

# configure
{
   expect_write "\x65";
   expect_read "\x01";

   $uart->configure( baud => "19200" )->get;

   check_and_clear '->configure baud';

   expect_write "\x84";
   expect_read "\x01";

   $uart->configure( parity => "E" )->get;

   check_and_clear '->configure parity';
}

# write
{
   expect_write "\x13\x41\x42\x43\x44";
   expect_read "\x01\x01\x01\x01\x01";

   $uart->write( "ABCD" )->get;

   check_and_clear '->write';
}

done_testing;
