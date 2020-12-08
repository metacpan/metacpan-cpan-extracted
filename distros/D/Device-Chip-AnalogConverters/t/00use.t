#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;

use_ok( 'Device::Chip::AD5691R' );
use_ok( 'Device::Chip::ADC121Sx' );
use_ok( 'Device::Chip::ADS1115' );
use_ok( 'Device::Chip::DAC7513' );
use_ok( 'Device::Chip::DAC7571' );
use_ok( 'Device::Chip::LTC2400' );
use_ok( 'Device::Chip::MAX11200' );
use_ok( 'Device::Chip::MAX1166x' );
use_ok( 'Device::Chip::MCP3221' );
use_ok( 'Device::Chip::MCP4725' );

done_testing;
