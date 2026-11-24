#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 10;

BEGIN {
    use_ok( 'Google::Ai::Generativelanguage::V1alpha' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1alpha::CacheServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1alpha::DiscussServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1alpha::FileServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1alpha::GenerativeServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1alpha::ModelServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1alpha::PermissionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1alpha::PredictionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1alpha::RetrieverServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1alpha::TextServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Ai::Generativelanguage::V1alpha $Google::Ai::Generativelanguage::V1alpha::VERSION, Perl $], $^X" );
