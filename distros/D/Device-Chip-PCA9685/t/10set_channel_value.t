#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::PCA9685;

my $chip = Device::Chip::PCA9685->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->set_channel_value
{
    $adapter->expect_write( "\x06\x00\x00\x00\x00" );

    $chip->set_channel_value( 0, 0 )->get;

    $adapter->check_and_clear( '$chip->set_channel_value' );
}

# ->set_channel_on
{
    $adapter->expect_write( "\x06\x00\x10\x00\x00" );

    $chip->set_channel_on( 0 )->get;

    $adapter->check_and_clear( '$chip->set_channel_on' );
}

# ->set_channel_off
{
    $adapter->expect_write( "\x06\x00\x00\x00\x10" );

    $chip->set_channel_off( 0 )->get;

    $adapter->check_and_clear( '$chip->set_channel_off' );
}

done_testing;
