#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Assistant::Embedded::V1alpha2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Assistant::Embedded::V1alpha2::EmbeddedAssistantClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Assistant::Embedded::V1alpha2 $Google::Cloud::Assistant::Embedded::V1alpha2::VERSION, Perl $], $^X" );
