#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::MAX11200;

my $chip = Device::Chip::MAX11200->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_status
{
   $adapter->expect_readwrite( "\xC1\x00" )
      ->returns( "\x00\x00" ); # STAT default value

   is_deeply( { $chip->read_status->get },
      {
         RDY   => '',
         MSTAT => '',
         UR    => '',
         OR    => '',
         RATE  => 1,
         SYSOR => '',
      },
      '$chip->read_status'
   );

   $adapter->check_and_clear( '$chip->read_status' );
}

# ->read_config
{
   $adapter->expect_readwrite( "\xC3\x00" )
      ->returns( "\x00\x02" ); # CTRL1 default value
   $adapter->expect_readwrite( "\xC7\x00" )
      ->returns( "\x00\x1e" ); # CTRL3 default value

   is_deeply( $chip->read_config->get,
      {
         SCYCLE => 1,
         FORMAT => 'TWOS_COMP',
         SIGBUF => '',
         REFBUF => '',
         EXTCLK => '',
         UB     => 'BIPOLAR',
         LINEF  => '60Hz',
         NOSCO  => 1,
         NOSCG  => 1,
         NOSYSO => 1,
         NOSYSG => 1,
         DGAIN  => 1,
      },
      '$chip->read_config'
   );

   $adapter->check_and_clear( '$chip->read_config' );
}

# ->change_config
{
   $adapter->expect_write( "\xC2\x82" );
   $adapter->expect_write( "\xC6\x1e" ); # TODO this is technically redundant

   $chip->change_config(
      LINEF => '50Hz',
   )->get;

   $adapter->check_and_clear( '$chip->change_config' );
}

# ->trigger and ->read_adc
{
   $adapter->expect_write( "\x87" ); # trigger
   $adapter->expect_readwrite( "\xC9\x00\x00\x00" )
      ->returns( "\x00\x12\x34\x56" );

   $chip->trigger->get;  # defaults to 120s/sec
   is( $chip->read_adc->get, 0x123456,
      '$chip->read_adc returns result' );

   $adapter->check_and_clear( '$chip->trigger and ->read_adc' );
}

# ->default_trigger_rate
{
   $adapter->expect_write( "\x85" ); # trigger at 30s/sec
   $adapter->expect_readwrite( "\xC9\x00\x00\x00" )
      ->returns( "\x00\x12\x34\x60" );

   $chip->default_trigger_rate = 30;
   $chip->trigger->get;  # defaults to 120s/sec
   is( $chip->read_adc->get, 0x123460,
      '$chip->read_adc returns result' );

   $adapter->check_and_clear( '$chip->trigger after ->default_trigger_rate' );
}

# ->read_adc_ratio
{
   $adapter->expect_readwrite( "\xC9\x00\x00\x00" )
      ->returns( "\x00\x20\x00\x00" );

   is( $chip->read_adc_ratio->get, 0.25,
      '$chip->read_adc_ratio returns result' );

   $adapter->check_and_clear( '$chip->read_adc_ratio' );
}

# ->write_gpios and ->read_gpios
{
   $adapter->expect_write( "\xC4\x31" ); # CTRL2
   $adapter->expect_readwrite( "\xC5\x00" )
      ->returns( "\x00\x39" );

   $chip->write_gpios( 0x1, 0x3 )->get;
   is( $chip->read_gpios->get, 0x9,
      '$chip->read_gpios returns result' );

   $adapter->check_and_clear( '$chip->write_gpios and ->read_gpios' );
}

# calibrations
{
   $adapter->expect_write( "\x90" );
   $adapter->expect_readwrite( "\xCF\x00\x00\x00" )
      ->returns( "\x00\x00\x01\x23" );

   $chip->selfcal->get;
   is( $chip->read_selfcal_offset->get, 0x123,
      '$chip->read_selfcal_offset returns result' );

   $adapter->expect_write( "\xD0\xAB\xCD\xEF" );

   $chip->write_selfcal_gain( 0xabcdef )->get;

   $adapter->check_and_clear( '$chip->selfcal' );
}

# concurrent read and GPIO
{
   $adapter->expect_readwrite( "\xC9\x00\x00\x00" )
      ->returns( "\x00\x12\x34\x56" );
   $adapter->expect_readwrite( "\xC5\x00" )
      ->returns( "\x00\x39" );

   is_deeply(
      [ Future->needs_all( $chip->read_adc, $chip->read_gpios )->get ],
      [ 0x123456, 0x09 ],
      'concurrent ->read_adc + ->read_gpios' );
}

# GPIO adapter
{
   my $gpioproto = $chip->as_gpio_adapter->make_protocol( "GPIO" )->get;

   is_deeply( [ $gpioproto->list_gpios ], [qw( GPIO1 GPIO2 GPIO3 GPIO4 )],
      '$gpioproto->list_gpios' );

   $adapter->expect_write( "\xC4\x11" );

   $gpioproto->write_gpios( { GPIO1 => 1 } )->get;

   $adapter->check_and_clear( '$gpioproto->write_gpios' );


   $adapter->expect_write( "\xC4\x33" );

   $gpioproto->write_gpios( { GPIO2 => 1 } )->get;

   $adapter->check_and_clear( '$gpioproto->write_gpios preserves existing' );


   $adapter->expect_readwrite( "\xC5\x00" )
      ->returns( "\x00\x33" );

   is_deeply( $gpioproto->read_gpios( [ 'GPIO3' ] )->get,
      { GPIO3 => 0 },
      'result of $gpioproto->read_gpios' );

   $adapter->check_and_clear( '$gpioproto->read_gpios' );
}

done_testing;
