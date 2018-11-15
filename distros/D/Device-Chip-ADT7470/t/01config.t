#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::ADT7470;

my $chip = Device::Chip::ADT7470->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_config
{
    $adapter->expect_write_then_read( "\x40", 1 )
       ->returns( "\x01" );

    is_deeply( $chip->read_config->get,
       {
	  STRT       => 1,
	  TODIS      => '',
	  LOCK       => '',
	  FST_TCH    => '',
	  HF_LF      => '',
	  T05_STB    => '',
      },
      '->read_config returns config' );

   $adapter->check_and_clear( '->read_config' );
}

# ->change_config
{
   $adapter->expect_write( "\x40\xA1" );

   $chip->change_config(
      FST_TCH => 1,
      T05_STB => 1,
   )->get;

   $adapter->check_and_clear( '$chip->change_config' );
}

done_testing;
