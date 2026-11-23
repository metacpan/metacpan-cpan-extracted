#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 7;

BEGIN {
    use_ok( 'Google::Cloud::Dataflow::V1beta3' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataflow::V1beta3::FlexTemplatesServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataflow::V1beta3::JobsV1Beta3Client' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataflow::V1beta3::MessagesV1Beta3Client' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataflow::V1beta3::MetricsV1Beta3Client' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataflow::V1beta3::SnapshotsV1Beta3Client' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataflow::V1beta3::TemplatesServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Dataflow::V1beta3 $Google::Cloud::Dataflow::V1beta3::VERSION, Perl $], $^X" );
