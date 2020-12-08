#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;

use_ok( 'Device::Chip::SSD1306' );
use_ok( 'Device::Chip::SSD1306::I2C' );
use_ok( 'Device::Chip::SSD1306::SPI4' );

done_testing;
