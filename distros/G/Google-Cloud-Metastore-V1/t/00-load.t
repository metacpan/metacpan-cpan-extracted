use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Google::Cloud::Metastore::V1') || print "Bail out!
";
}

diag( "Google::Cloud::Metastore::V1 $Google::Cloud::Metastore::V1::VERSION, Perl $], $^X" );
