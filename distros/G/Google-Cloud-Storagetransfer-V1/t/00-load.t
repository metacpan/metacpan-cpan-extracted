#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Storagetransfer::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Storagetransfer::V1::StorageTransferServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Storagetransfer::V1 $Google::Cloud::Storagetransfer::V1::VERSION, Perl $], $^X" );
