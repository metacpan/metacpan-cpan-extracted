use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Google::Cloud::IAM::V1') || print "Bail out!
";
}

diag( "Google::Cloud::IAM::V1 $Google::Cloud::IAM::V1::VERSION, Perl $], $^X" );
