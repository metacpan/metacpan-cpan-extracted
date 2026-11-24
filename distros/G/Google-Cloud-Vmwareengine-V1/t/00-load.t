#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Vmwareengine::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Vmwareengine::V1::VmwareEngineClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Vmwareengine::V1 $Google::Cloud::Vmwareengine::V1::VERSION, Perl $], $^X" );
