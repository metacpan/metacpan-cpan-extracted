#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Osconfig::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Osconfig::V1::OsConfigServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Osconfig::V1::OsConfigZonalServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Osconfig::V1 $Google::Cloud::Osconfig::V1::VERSION, Perl $], $^X" );
