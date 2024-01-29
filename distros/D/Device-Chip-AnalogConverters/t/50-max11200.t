#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::MAX11200;

my $chip = Device::Chip::MAX11200->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_status
{
   $adapter->expect_readwrite( "\xC1\x00" )
      ->will_done( "\x00\x00" ); # STAT default value

   is( { await $chip->read_status },
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
      ->will_done( "\x00\x02" ); # CTRL1 default value
   $adapter->expect_readwrite( "\xC7\x00" )
      ->will_done( "\x00\x1e" ); # CTRL3 default value

   is( await $chip->read_config,
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

   await $chip->change_config(
      LINEF => '50Hz',
   );

   $adapter->check_and_clear( '$chip->change_config' );
}

# ->trigger and ->read_adc
{
   $adapter->expect_write( "\x87" ); # trigger
   $adapter->expect_readwrite( "\xC9\x00\x00\x00" )
      ->will_done( "\x00\x12\x34\x56" );

   await $chip->trigger;  # defaults to 120s/sec
   is( await $chip->read_adc, 0x123456,
      '$chip->read_adc returns result' );

   $adapter->check_and_clear( '$chip->trigger and ->read_adc' );
}

# ->default_trigger_rate
{
   $adapter->expect_write( "\x85" ); # trigger at 30s/sec
   $adapter->expect_readwrite( "\xC9\x00\x00\x00" )
      ->will_done( "\x00\x12\x34\x60" );

   $chip->default_trigger_rate = 30;
   await $chip->trigger;  # defaults to 120s/sec
   is( await $chip->read_adc, 0x123460,
      '$chip->read_adc returns result' );

   $adapter->check_and_clear( '$chip->trigger after ->default_trigger_rate' );
}

# ->read_adc_ratio
{
   $adapter->expect_readwrite( "\xC9\x00\x00\x00" )
      ->will_done( "\x00\x20\x00\x00" );

   is( await $chip->read_adc_ratio, 0.25,
      '$chip->read_adc_ratio returns result' );

   $adapter->check_and_clear( '$chip->read_adc_ratio' );
}

# ->write_gpios and ->read_gpios
{
   $adapter->expect_write( "\xC4\x31" ); # CTRL2
   $adapter->expect_readwrite( "\xC5\x00" )
      ->will_done( "\x00\x39" );

   await $chip->write_gpios( 0x1, 0x3 );
   is( await $chip->read_gpios, 0x9,
      '$chip->read_gpios returns result' );

   $adapter->check_and_clear( '$chip->write_gpios and ->read_gpios' );
}

# calibrations
{
   $adapter->expect_write( "\x90" );
   $adapter->expect_readwrite( "\xCF\x00\x00\x00" )
      ->will_done( "\x00\x00\x01\x23" );

   await $chip->selfcal;
   is( await $chip->read_selfcal_offset, 0x123,
      '$chip->read_selfcal_offset returns result' );

   $adapter->expect_write( "\xD0\xAB\xCD\xEF" );

   await $chip->write_selfcal_gain( 0xabcdef );

   $adapter->check_and_clear( '$chip->selfcal' );
}

# concurrent read and GPIO
{
   $adapter->expect_readwrite( "\xC9\x00\x00\x00" )
      ->will_done( "\x00\x12\x34\x56" );
   $adapter->expect_readwrite( "\xC5\x00" )
      ->will_done( "\x00\x39" );

   is(
      [ await Future->needs_all( $chip->read_adc, $chip->read_gpios ) ],
      [ 0x123456, 0x09 ],
      'concurrent ->read_adc + ->read_gpios' );
}

# GPIO adapter
{
   my $gpioproto = await $chip->as_gpio_adapter->make_protocol( "GPIO" );

   is( [ $gpioproto->list_gpios ], [qw( GPIO1 GPIO2 GPIO3 GPIO4 )],
      '$gpioproto->list_gpios' );

   $adapter->expect_write( "\xC4\x11" );

   await $gpioproto->write_gpios( { GPIO1 => 1 } );

   $adapter->check_and_clear( '$gpioproto->write_gpios' );


   $adapter->expect_write( "\xC4\x33" );

   await $gpioproto->write_gpios( { GPIO2 => 1 } );

   $adapter->check_and_clear( '$gpioproto->write_gpios preserves existing' );


   $adapter->expect_readwrite( "\xC5\x00" )
      ->will_done( "\x00\x33" );

   is( await $gpioproto->read_gpios( [ 'GPIO3' ] ),
      { GPIO3 => 0 },
      'result of $gpioproto->read_gpios' );

   $adapter->check_and_clear( '$gpioproto->read_gpios' );
}

done_testing;
