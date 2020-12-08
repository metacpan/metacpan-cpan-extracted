#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;

use_ok( 'Device::Chip::MCP23x17' );
use_ok( 'Device::Chip::MCP23x17::Adapter' );

done_testing;
