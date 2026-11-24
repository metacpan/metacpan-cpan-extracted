#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Speech::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Speech::V1::AdaptationClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Speech::V1::SpeechClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Speech::V1 $Google::Cloud::Speech::V1::VERSION, Perl $], $^X" );
