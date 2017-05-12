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
    $adapter->expect_write( "\x00\x20" );

    $chip->enable->get;

    $adapter->check_and_clear( '$chip->enable' );
}

done_testing;
