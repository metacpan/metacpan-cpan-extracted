use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Google::Cloud::Composer::V1') || print "Bail out!
";
}

diag( "Google::Cloud::Composer::V1 $Google::Cloud::Composer::V1::VERSION, Perl $], $^X" );
