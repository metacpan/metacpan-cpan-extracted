#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( 'Device::Chip' );
use_ok( 'Device::Chip::Adapter' );

use_ok( 'Device::Chip::ProtocolBase::SPI' );

use_ok( 'Device::Chip::Sensor' );

done_testing;
