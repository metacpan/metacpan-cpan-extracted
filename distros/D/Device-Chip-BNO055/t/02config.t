#!/usr/bin/perl

use utf8;

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::BNO055;

my $chip = Device::Chip::BNO055->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_config
{
   # Page 0
   $adapter->expect_write_then_read( "\x3B", 8 )
      ->returns( "\x80\x00\x00\x00\x00\x00\x24\x00" );
   # Page 1
   $adapter->expect_write( "\x07\x01" );
   $adapter->expect_write_then_read( "\x08", 4 )
      ->returns( "\x0D\x0B\x38\x00" );

   is_deeply( $chip->read_config->get,
      {
         # Page 0 config
         ACC_Unit    => "m/s²",
         EUL_Unit    => "degrees",
         GYR_Unit    => "dps",
         OPR_MODE    => "CONFIGMODE",
         ORI_Android_Windows => "Android",
         PWR_MODE    => "normal",
         TEMP_Source => "accelerometer",
         TEMP_Unit   => "Celsius",
         X_AXIS_MAP  => "X",
         X_AXIS_SIGN => "positive",
         Y_AXIS_MAP  => "Y",
         Y_AXIS_SIGN => "positive",
         Z_AXIS_MAP  => "Z",
         Z_AXIS_SIGN => "positive",

         # Page 1 config
         ACC_BW       => "62.5Hz",
         ACC_Range    => "4G",
         ACC_PWR_Mode => "normal",
         GYR_Bandwidth  => "32Hz",
         GYR_Power_Mode => "normal",
         GYR_Range      => "2000dps",
         MAG_Data_output_rate => "10Hz",
         MAG_OPR_Mode         => "regular",
         MAG_Power_mode       => "normal",
      },
      '->read_config yields config' );

   $adapter->check_and_clear( '->read_config' );
}

# ->change_config
{
   $adapter->expect_write( "\x07\x00" );
   $adapter->expect_write( "\x42\x03" );

   $chip->change_config(
      X_AXIS_SIGN => "negative",
      Y_AXIS_SIGN => "negative",
   )->get;

   $adapter->check_and_clear( '->change_config' );
}

# ->set_opr_mode
{
   $adapter->expect_write( "\x3D\x01" );

   $chip->set_opr_mode( "ACCONLY" )->get;

   $adapter->check_and_clear( '->set_opr_mode' );

   is( $chip->read_config->get->{OPR_MODE}, "ACCONLY",
      '->read_config now gives OPR_MODE=ACCONLY' );

   $adapter->check_and_clear( '->read_config after ->set_opr_mode' );
}

done_testing;
