#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::DAC7571;

my $chip = Device::Chip::DAC7571->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->write_dac
{
   $adapter->expect_write( "\x04\x00" );

   $chip->write_dac( 1024 )->get;

   $adapter->check_and_clear( '$chip->write_dac' );
}

# ->write_dac with powerdown
{
   $adapter->expect_write( "\x24\x00" );

   $chip->write_dac( 1024, "100k" )->get;

   $adapter->check_and_clear( '$chip->write_dac with powerdown' );
}

done_testing;
