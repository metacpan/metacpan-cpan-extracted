#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Documentai::V1beta3' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Documentai::V1beta3::DocumentProcessorServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Documentai::V1beta3::DocumentServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Documentai::V1beta3 $Google::Cloud::Documentai::V1beta3::VERSION, Perl $], $^X" );
