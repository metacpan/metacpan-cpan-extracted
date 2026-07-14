use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Google::Cloud::DataFusion::V1') || print "Bail out!
";
}

diag( "Google::Cloud::DataFusion::V1 $Google::Cloud::DataFusion::V1::VERSION, Perl $], $^X" );
