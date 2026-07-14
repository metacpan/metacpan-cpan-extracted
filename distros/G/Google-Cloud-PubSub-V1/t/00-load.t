use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Google::Cloud::PubSub::V1') || print "Bail out!
";
}

diag( "Google::Cloud::PubSub::V1 $Google::Cloud::PubSub::V1::VERSION, Perl $], $^X" );
