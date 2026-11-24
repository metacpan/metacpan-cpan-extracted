#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Actions::Sdk::V2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Actions::Sdk::V2::ActionsSdkClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Actions::Sdk::V2::ActionsTestingClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Actions::Sdk::V2 $Google::Cloud::Actions::Sdk::V2::VERSION, Perl $], $^X" );
