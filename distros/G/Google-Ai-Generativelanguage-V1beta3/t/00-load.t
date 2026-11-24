#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'Google::Ai::Generativelanguage::V1beta3' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1beta3::DiscussServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1beta3::ModelServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1beta3::PermissionServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1beta3::TextServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Ai::Generativelanguage::V1beta3 $Google::Ai::Generativelanguage::V1beta3::VERSION, Perl $], $^X" );
