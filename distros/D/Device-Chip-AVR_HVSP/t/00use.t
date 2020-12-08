#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;

use_ok( 'Device::Chip::AVR_HVSP' );
use_ok( 'Device::Chip::AVR_HVSP::FuseInfo' );

done_testing;
