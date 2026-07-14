use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Google::Cloud::SQL::V1') || print "Bail out!
";
}

diag( "Google::Cloud::SQL::V1 $Google::Cloud::SQL::V1::VERSION, Perl $], $^X" );
