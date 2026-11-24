#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 7;

BEGIN {
    use_ok( 'Google::Cloud::Ces::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Ces::V1beta::AgentServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Ces::V1beta::AssistantServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Ces::V1beta::EvaluationServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Ces::V1beta::SessionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Ces::V1beta::ToolServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Ces::V1beta::WidgetServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Ces::V1beta $Google::Cloud::Ces::V1beta::VERSION, Perl $], $^X" );
