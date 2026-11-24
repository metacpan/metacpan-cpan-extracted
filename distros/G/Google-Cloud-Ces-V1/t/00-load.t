#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'Google::Cloud::Ces::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Ces::V1::AgentServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Ces::V1::SessionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Ces::V1::ToolServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Ces::V1::WidgetServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Ces::V1 $Google::Cloud::Ces::V1::VERSION, Perl $], $^X" );
