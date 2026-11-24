#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Storage::Control::V2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Storage::Control::V2::StorageControlClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Storage::Control::V2 $Google::Cloud::Storage::Control::V2::VERSION, Perl $], $^X" );
