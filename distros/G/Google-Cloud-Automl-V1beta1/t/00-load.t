#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Automl::V1beta1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Automl::V1beta1::AutoMlClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Automl::V1beta1::PredictionServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Automl::V1beta1 $Google::Cloud::Automl::V1beta1::VERSION, Perl $], $^X" );
