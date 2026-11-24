#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Google::Cloud::Devtools::Resultstore::V2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Devtools::Resultstore::V2::ResultStoreDownloadClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Devtools::Resultstore::V2::ResultStoreFileDownloadClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Devtools::Resultstore::V2::ResultStoreUploadClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Devtools::Resultstore::V2 $Google::Cloud::Devtools::Resultstore::V2::VERSION, Perl $], $^X" );
