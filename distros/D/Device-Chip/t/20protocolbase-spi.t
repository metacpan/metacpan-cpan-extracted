#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait 0.47;

use Device::Chip::ProtocolBase::SPI;

{
   use Object::Pad 0.800;

   class TestAdapter
      :isa(Test::Device::Chip::Adapter)
      :does(Device::Chip::ProtocolBase::SPI);
}

my $adapter = TestAdapter->new;
my $protocol = await $adapter->make_protocol( "SPI" );

# readwrite
{
   $adapter->expect_assert_ss;
   $adapter->expect_readwrite_no_ss( "AB" )
      ->will_done( "CD" );
   $adapter->expect_release_ss;

   is( await $protocol->readwrite( "AB" ), "CD",
      '->readwrite value' );

   $adapter->check_and_clear( '->readwrite' );
}

# write
{
   $adapter->expect_assert_ss;
   $adapter->expect_readwrite_no_ss( "EF" )
      ->will_done( "XX" );
   $adapter->expect_release_ss;

   is( await $protocol->write( "EF" ), undef,
      '->write value' );

   $adapter->check_and_clear( '->write' );
}

# read
{
   $adapter->expect_assert_ss;
   $adapter->expect_readwrite_no_ss( "\0\0" )
      ->will_done( "KL" );
   $adapter->expect_release_ss;

   is( await $protocol->read( 2 ), "KL",
      '->read value' );

   $adapter->check_and_clear( '->read' );
}

# write_then_read
{
   $adapter->expect_assert_ss;
   $adapter->expect_readwrite_no_ss( "GH" )
      ->will_done( "XX" );
   $adapter->expect_readwrite_no_ss( "\0\0" )
      ->will_done( "IJ" );
   $adapter->expect_release_ss;

   is( await $protocol->write_then_read( "GH", 2 ), "IJ",
      '->write_then_read value' );

   $adapter->check_and_clear( '->write_then_read' );
}

done_testing;
