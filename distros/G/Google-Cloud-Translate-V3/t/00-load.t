#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Translate::V3' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Translate::V3::TranslationServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Translate::V3 $Google::Cloud::Translate::V3::VERSION, Perl $], $^X" );
