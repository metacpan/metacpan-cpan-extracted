#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Storage::V2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Storage::V2::StorageClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Storage::V2 $Google::Cloud::Storage::V2::VERSION, Perl $], $^X" );
