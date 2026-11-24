#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Language::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Language::V1::LanguageServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Language::V1 $Google::Cloud::Language::V1::VERSION, Perl $], $^X" );
