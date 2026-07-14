use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Google::Cloud::Storage::V2') || print "Bail out!
";
}

diag( "Google::Cloud::Storage::V2 $Google::Cloud::Storage::V2::VERSION, Perl $], $^X" );
