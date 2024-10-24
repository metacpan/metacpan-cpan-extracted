#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

require Device::Chip::From::Sensirion;

require Device::Chip::SCD4x;
require Device::Chip::SGP4x;

pass( 'Modules loaded' );
done_testing;
