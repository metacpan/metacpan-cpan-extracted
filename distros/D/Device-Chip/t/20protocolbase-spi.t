#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::ProtocolBase::SPI;

{
   package TestAdapter;
   # T:D:C:Adapter yields itself as all protocol implementations
   use base qw( Device::Chip::ProtocolBase::SPI Test::Device::Chip::Adapter );
}

my $adapter = TestAdapter->new;
my $protocol = $adapter->make_protocol( "SPI" )->get;

# readwrite
{
   $adapter->expect_assert_ss;
   $adapter->expect_readwrite_no_ss( "AB" )->returns( "CD" );
   $adapter->expect_release_ss;

   is( $protocol->readwrite( "AB" )->get, "CD",
      '->readwrite value' );

   $adapter->check_and_clear( '->readwrite' );
}

# write
{
   $adapter->expect_assert_ss;
   $adapter->expect_readwrite_no_ss( "EF" )->returns( "XX" );
   $adapter->expect_release_ss;

   is( $protocol->write( "EF" )->get, undef,
      '->write value' );

   $adapter->check_and_clear( '->write' );
}

# read
{
   $adapter->expect_assert_ss;
   $adapter->expect_readwrite_no_ss( "\0\0" )->returns( "KL" );
   $adapter->expect_release_ss;

   is( $protocol->read( 2 )->get, "KL",
      '->read value' );

   $adapter->check_and_clear( '->read' );
}

# write_then_read
{
   $adapter->expect_assert_ss;
   $adapter->expect_readwrite_no_ss( "GH" )->returns( "XX" );
   $adapter->expect_readwrite_no_ss( "\0\0" )->returns( "IJ" );
   $adapter->expect_release_ss;

   is( $protocol->write_then_read( "GH", 2 )->get, "IJ",
      '->write_then_read value' );

   $adapter->check_and_clear( '->write_then_read' );
}

done_testing;
