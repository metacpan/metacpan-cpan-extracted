#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

require Device::Chip;
require Device::Chip::Adapter;

require Device::Chip::ProtocolBase::SPI;

require Device::Chip::Sensor;

pass( 'Modules loaded' );
done_testing;
