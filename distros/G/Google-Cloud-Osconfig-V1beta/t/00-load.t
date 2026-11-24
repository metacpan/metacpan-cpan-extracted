#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Osconfig::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Osconfig::V1beta::OsConfigServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Osconfig::V1beta $Google::Cloud::Osconfig::V1beta::VERSION, Perl $], $^X" );
