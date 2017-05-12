#!/usr/bin/perl -w
use lib 'lib';

use Test::More tests => 1;

BEGIN {
use_ok( 'GD::Graph::Thermometer' );
}

diag( "Testing GD::Graph::Thermometer $GD::Graph::Thermometer::VERSION" );
