#!perl -T

use Test::More tests => 1;
use strict;
use warnings;

BEGIN {
    use_ok( 'Device::USB' );
}

diag( "Testing Device::USB $Device::USB::VERSION, Perl $], $^X" );
