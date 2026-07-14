use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Google::Cloud::Dataproc::V1') || print "Bail out!
";
}

diag( "Google::Cloud::Dataproc::V1 $Google::Cloud::Dataproc::V1::VERSION, Perl $], $^X" );
