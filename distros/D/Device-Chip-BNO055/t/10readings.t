#!/usr/bin/perl

use v5.26;
use warnings;
use utf8;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::BNO055;

my $chip = Device::Chip::BNO055->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_config first just to cache the units
{
   $adapter->expect_write_then_read( "\x3B", 8 )
      ->returns( "\x80\x00\x00\x00\x00\x00\x24\x00" );
   $adapter->expect_write( "\x07\x01" );
   $adapter->expect_write_then_read( "\x08", 4 )
      ->returns( "\x0D\x0B\x38\x00" );

   await $chip->read_config;

   $adapter->check_and_clear( 'Initial ->read_config' );
}

# ->read_accelerometer
{
   $adapter->expect_write( "\x07\x00" );

   $adapter->expect_write_then_read( "\x08", 6 )
      ->returns( "\x12\x34\x56\x78\x9A\xBC" );

   is( [ await $chip->read_accelerometer ],
      [ 133.3, 308.06, -172.54 ],
      '->read_accelerometer yields readings' );

   $adapter->check_and_clear( '->read_accelerometer' );
}

# ->read_magnetometer
{
   $adapter->expect_write_then_read( "\x0E", 6 )
      ->returns( "\x01\x23\x02\x46\x03\x69" );

   is( [ await $chip->read_magnetometer ],
      [ 560.0625, 1120.125, 1680.1875 ],
      '->read_magnetometer yields readings' );

   $adapter->check_and_clear( '->read_magnetometer' );
}

# ->read_gyroscope
{
   $adapter->expect_write_then_read( "\x14", 6 )
      ->returns( "\x03\x21\x06\x42\x09\x63" );

   is( [ await $chip->read_gyroscope ],
      [ 528.1875, 1056.375, 1584.5625 ],
      '->read_gyroscope yields readings' );

   $adapter->check_and_clear( '->read_gyroscope' );
}

# ->read_euler_angles
{
   $adapter->expect_write_then_read( "\x1A", 6 )
      ->returns( "\x12\x01\x23\x01\x01\x04" );

   is( [ await $chip->read_euler_angles ],
      [ 17.125, 18.1875, 64.0625 ],
      '->read_euler_angles yields readings' );

   $adapter->check_and_clear( '->read_euler_angles' );
}

# ->read_quarternion
{
   $adapter->expect_write_then_read( "\x20", 8 )
      ->returns( "\x11\x02\x22\x03\x00\x04\x33\x02" );

   is( [ map { sprintf "%.04f", $_ } await $chip->read_quarternion ],
      [ 0.0323, "0.0490", 0.0625, 0.0344 ],
      '->read_quarternion yields readings' );

   $adapter->check_and_clear( '->read_quarternion' );
}

# ->read_linear_acceleration
{
   $adapter->expect_write_then_read( "\x28", 6 )
      ->returns( "\x21\x03\x42\x06\x63\x09" );

   is( [ await $chip->read_linear_acceleration ],
      [ 8.01, 16.02, 24.03 ],
      '->read_linear_acceleration yields readings' );

   $adapter->check_and_clear( '->read_linear_acceleration' );
}

# ->read_gravity
{
   $adapter->expect_write_then_read( "\x2E", 6 )
      ->returns( "\x44\x02\x66\x03\x88\x04" );

   is( [ await $chip->read_gravity ],
      [ 5.8, 8.7, 11.6 ],
      '->read_gravity yields readings' );

   $adapter->check_and_clear( '->read_gravity' );
}

done_testing;
