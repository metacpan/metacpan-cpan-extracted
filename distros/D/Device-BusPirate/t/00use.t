#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

require Device::BusPirate;

require Device::BusPirate::Mode::BB;
require Device::BusPirate::Mode::I2C;
require Device::BusPirate::Mode::SPI;
require Device::BusPirate::Mode::UART;

require Device::Chip::Adapter::BusPirate;

pass( 'Modules loaded' );
done_testing;
