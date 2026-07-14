use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Google::Cloud::Compute::V1') || print "Bail out!
";
}

diag( "Google::Cloud::Compute::V1 $Google::Cloud::Compute::V1::VERSION, Perl $], $^X" );
