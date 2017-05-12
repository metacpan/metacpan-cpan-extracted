#!perl -T
use strict;
use Test::More tests => 2;

use_ok( "Device::TLSPrinter" );
use_ok( "Device::TLSPrinter::Network" );

diag( "Testing Device::TLSPrinter $Device::TLSPrinter::VERSION, Perl $], $^X" );
