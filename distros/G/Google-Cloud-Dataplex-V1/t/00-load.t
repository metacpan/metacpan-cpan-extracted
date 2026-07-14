use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Google::Cloud::Dataplex::V1') || print "Bail out!
";
}

diag( "Google::Cloud::Dataplex::V1 $Google::Cloud::Dataplex::V1::VERSION, Perl $], $^X" );
