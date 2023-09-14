#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

require Device::Chip::AVR_HVSP;
require Device::Chip::AVR_HVSP::FuseInfo;

pass( 'Modules loaded' );
done_testing;
