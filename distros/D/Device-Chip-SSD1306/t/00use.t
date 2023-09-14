#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

require Device::Chip::SSD1306;
require Device::Chip::SSD1306::I2C;
require Device::Chip::SSD1306::SPI4;

pass( 'Modules loaded' );
done_testing;
