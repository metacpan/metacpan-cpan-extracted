#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Eventarc::Publishing::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Eventarc::Publishing::V1::PublisherClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Eventarc::Publishing::V1 $Google::Cloud::Eventarc::Publishing::V1::VERSION, Perl $], $^X" );
