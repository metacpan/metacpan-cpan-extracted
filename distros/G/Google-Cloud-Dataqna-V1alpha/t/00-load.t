#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Dataqna::V1alpha' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataqna::V1alpha::AutoSuggestionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataqna::V1alpha::QuestionServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Dataqna::V1alpha $Google::Cloud::Dataqna::V1alpha::VERSION, Perl $], $^X" );
