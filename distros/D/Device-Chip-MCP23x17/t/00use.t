#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

require Device::Chip::MCP23x17;
require Device::Chip::MCP23S17;
require Device::Chip::MCP23x17::Adapter;

pass( 'Modules loaded' );
done_testing;
