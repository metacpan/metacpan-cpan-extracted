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

{
    $adapter->expect_write_then_read( "\x00", 1 )
        ->returns( "\x00" );
    $adapter->expect_write( "\x00\x10" ); # MODE1=SLEEP
    $adapter->expect_write( "\xFE\x0E" ); # PRE_SCALE
    $adapter->expect_write( "\x00\x00" ); # MODE1=!SLEEP
    $adapter->expect_write( "\x00\x80" ); # MODE1=RESTART

    $chip->set_frequency( 400 )->get;

    $adapter->check_and_clear( '$chip->set_frequency' );
}

done_testing;
