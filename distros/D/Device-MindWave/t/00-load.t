#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Device::MindWave' ) || print "Bail out!\n";
}

diag( "Testing Device::MindWave $Device::MindWave::VERSION, Perl $], $^X" );
