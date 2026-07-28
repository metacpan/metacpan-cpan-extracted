#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Ai::Generativelanguage::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1::GenerativeServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Ai::Generativelanguage::V1::ModelServiceClient' ) || print "Bail out!\n";
}
