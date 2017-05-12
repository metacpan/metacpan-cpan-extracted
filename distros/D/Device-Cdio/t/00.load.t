#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';
use blib;

use Test::More tests => 2;
note( "Testing Device::Cdio $Device::Cdio::VERSION" );

BEGIN {
use_ok( 'Device::Cdio' );
}

ok(defined($Device::Cdio::VERSION), "\$Device::Cdio::VERSION number is set");
