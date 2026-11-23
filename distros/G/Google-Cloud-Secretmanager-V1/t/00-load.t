#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Secretmanager::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Secretmanager::V1::SecretManagerServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Secretmanager::V1::SecretOperationsServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Secretmanager::V1 $Google::Cloud::Secretmanager::V1::VERSION, Perl $], $^X" );
