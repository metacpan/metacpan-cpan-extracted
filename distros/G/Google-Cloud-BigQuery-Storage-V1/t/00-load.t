use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Google::Cloud::BigQuery::Storage::V1') || print "Bail out!
";
}

diag( "Google::Cloud::BigQuery::Storage::V1 $Google::Cloud::BigQuery::Storage::V1::VERSION, Perl $], $^X" );
