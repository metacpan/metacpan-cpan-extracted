#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Devtools::Cloudprofiler::V2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Devtools::Cloudprofiler::V2::ExportServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Devtools::Cloudprofiler::V2::ProfilerServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Devtools::Cloudprofiler::V2 $Google::Cloud::Devtools::Cloudprofiler::V2::VERSION, Perl $], $^X" );
