#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( 'Device::BusPirate' );

use_ok( 'Device::BusPirate::Mode::BB' );
use_ok( 'Device::BusPirate::Mode::I2C' );
use_ok( 'Device::BusPirate::Mode::SPI' );

use_ok( 'Device::Chip::Adapter::BusPirate' );

done_testing;
