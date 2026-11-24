#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 11;

BEGIN {
    use_ok( 'Google::Cloud::Run::V2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Run::V2::BuildsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Run::V2::ExecutionsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Run::V2::InstancesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Run::V2::JobsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Run::V2::RevisionsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Run::V2::ServicesClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Run::V2::SourceUploadClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Run::V2::TasksClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Run::V2::WorkerPoolsClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Run::V2::becomesClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Run::V2 $Google::Cloud::Run::V2::VERSION, Perl $], $^X" );
