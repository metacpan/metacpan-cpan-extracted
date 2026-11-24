#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Language::V1beta1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Language::V1beta1::LanguageServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Language::V1beta1 $Google::Cloud::Language::V1beta1::VERSION, Perl $], $^X" );
