#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

require Device::Chip::AD5691R;
require Device::Chip::ADC121Sx;
require Device::Chip::ADS1115;
require Device::Chip::DAC7513;
require Device::Chip::DAC7571;
require Device::Chip::LTC2400;
require Device::Chip::MAX11200;
require Device::Chip::MAX1166x;
require Device::Chip::MCP3221;
require Device::Chip::MCP4725;

pass( 'Modules loaded' );
done_testing;
