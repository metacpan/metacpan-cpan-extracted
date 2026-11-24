#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 7;

BEGIN {
    use_ok( 'Google::Cloud::Contentwarehouse::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Contentwarehouse::V1::DocumentLinkServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Contentwarehouse::V1::DocumentSchemaServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Contentwarehouse::V1::DocumentServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Contentwarehouse::V1::PipelineServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Contentwarehouse::V1::RuleSetServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Contentwarehouse::V1::SynonymSetServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Contentwarehouse::V1 $Google::Cloud::Contentwarehouse::V1::VERSION, Perl $], $^X" );
