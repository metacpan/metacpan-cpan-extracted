#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 6;

BEGIN {
    use_ok( 'Google::Cloud::Dataflow::V1beta3::FlexTemplatesServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataflow::V1beta3::JobsV1beta3Client' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataflow::V1beta3::MessagesV1beta3Client' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataflow::V1beta3::MetricsV1beta3Client' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataflow::V1beta3::SnapshotsV1beta3Client' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataflow::V1beta3::TemplatesServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Dataflow::V1beta3::FlexTemplatesServiceClient $Google::Cloud::Dataflow::V1beta3::FlexTemplatesServiceClient::VERSION, Perl $], $^X" );
