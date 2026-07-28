#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Storage::V2::StorageClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Storage::V2::StorageClient $Google::Cloud::Storage::V2::StorageClient::VERSION, Perl $], $^X" );
