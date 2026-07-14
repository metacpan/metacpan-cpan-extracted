use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Google::Cloud::NetworkServices::V1') || print "Bail out!
";
}

diag( "Google::Cloud::NetworkServices::V1 $Google::Cloud::NetworkServices::V1::VERSION, Perl $], $^X" );
