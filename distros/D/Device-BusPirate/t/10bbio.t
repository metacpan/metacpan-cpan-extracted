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
my $bbio;
{
   expect_write "\x00";
   expect_read "BBIO1";

   $bbio = $bp->enter_mode( "BB" )->get;
   ok( $bbio, '->enter_mode( "BB" )' );

   check_and_clear '->enter_mode BB';
}

# read
{
   expect_write "\x80"; # bitbang
   expect_read "\x00";

   is_deeply( $bbio->read->get,
      { miso => '', cs => '', mosi => '', clk => '', aux => '' },
      '->read yields pins' );

   check_and_clear '->read';
}

# write
{
   expect_write "\x4E\x91"; # set direction; bitbang CS,AUX
   expect_read "\x00\x11";

   $bbio->write( cs => 1, aux => 1 )->get;

   check_and_clear '->write';
}

# read after write no longer yields written pins
{
   expect_write "\x91"; # bitbang CS,AUX again
   expect_read "\x11";

   is_deeply( $bbio->read->get,
      { miso => '', mosi => '', clk => '' },
      '->read yields fewer pins after write' );

   check_and_clear '->read after write';
}

# pin shortcut methods
{
   expect_write "\x4A";
   expect_read "\x11";

   $bbio->clk( 0 )->get;

   expect_write "\x4E";
   expect_read "\x15";

   ok( $bbio->read_clk->get, '->read_clk yields pin state' );

   check_and_clear '->clk and ->read_clk';
}

# power, pullups
{
   expect_write "\xD1";
   expect_read "\x15";

   $bbio->power( 1 )->get;

   expect_write "\xF1";
   expect_read "\x15";

   $bbio->pullup( 1 )->get;

   check_and_clear '->power and ->pullup';
}

# set_pwm
{
   # 1 MHz => period 16 at fCPU
   expect_write "\x12\x00\x00\x08\x00\x10";
   expect_read "\x01";

   $bbio->set_pwm( freq => 1E6 )->get;

   # 1kHz => period 16000 at fCPU
   expect_write "\x12\x00\x1F\x40\x3E\x80";
   expect_read "\x01";

   $bbio->set_pwm( freq => 1E3 )->get;

   # 10Hz => period 25000 at fCPU/64
   expect_write "\x12\x02\x30\xD4\x61\xA8";
   expect_read "\x01";

   $bbio->set_pwm( freq => 10 )->get;

   # 90% duty cycle
   expect_write "\x12\x02\x57\xE4\x61\xA8";
   expect_read "\x01";

   $bbio->set_pwm( freq => 10, duty => 90 )->get;

   # 0Hz to clear
   expect_write "\x13";
   expect_read "\x01";

   $bbio->set_pwm( freq => 0 )->get;

   check_and_clear '->set_pwm';
}

# read_adc_voltage
{
   expect_write "\x14";
   expect_read "\x01\x23";

   my $volts = $bbio->read_adc_voltage->get;
   is( sprintf( "%.3f", $volts ), "1.876", '->read_adc_voltage yields voltage' );

   check_and_clear '->read_adc_voltage';
}

done_testing;
