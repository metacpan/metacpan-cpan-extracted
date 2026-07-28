#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 8;

BEGIN {
    use_ok( 'Google::Cloud::Dataproc::V1::AutoscalingPolicyServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataproc::V1::BatchControllerClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataproc::V1::ClusterControllerClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataproc::V1::JobControllerClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataproc::V1::NodeGroupControllerClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataproc::V1::SessionControllerClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataproc::V1::SessionTemplateControllerClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataproc::V1::WorkflowTemplateServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Dataproc::V1::AutoscalingPolicyServiceClient $Google::Cloud::Dataproc::V1::AutoscalingPolicyServiceClient::VERSION, Perl $], $^X" );
