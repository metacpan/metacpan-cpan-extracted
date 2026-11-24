#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Vision::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Vision::V1::ImageAnnotatorClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Vision::V1::ProductSearchClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Vision::V1 $Google::Cloud::Vision::V1::VERSION, Perl $], $^X" );
