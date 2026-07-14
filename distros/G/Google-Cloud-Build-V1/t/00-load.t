use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Google::Cloud::Build::V1') || print "Bail out!
";
}

diag( "Google::Cloud::Build::V1 $Google::Cloud::Build::V1::VERSION, Perl $], $^X" );
