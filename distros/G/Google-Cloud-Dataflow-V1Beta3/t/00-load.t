use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Google::Cloud::Dataflow::V1Beta3') || print "Bail out!
";
}

diag( "Google::Cloud::Dataflow::V1Beta3 $Google::Cloud::Dataflow::V1Beta3::VERSION, Perl $], $^X" );
