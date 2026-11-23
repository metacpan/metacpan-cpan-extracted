#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 10;

BEGIN {
    use_ok( 'Google::Ai::Generativelanguage::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1beta::CacheServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1beta::DiscussServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1beta::FileServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1beta::GenerativeServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1beta::ModelServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1beta::PermissionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1beta::PredictionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1beta::RetrieverServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1beta::TextServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Ai::Generativelanguage::V1beta $Google::Ai::Generativelanguage::V1beta::VERSION, Perl $], $^X" );
