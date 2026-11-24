#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Partner::Aistreams::V1alpha1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Partner::Aistreams::V1alpha1::AIStreamsClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Partner::Aistreams::V1alpha1 $Google::Cloud::Partner::Aistreams::V1alpha1::VERSION, Perl $], $^X" );
