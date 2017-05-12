#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Guitar::Tuner' ) || print "Bail out!
";
}

diag( "Testing Guitar::Tuner $Guitar::Tuner::VERSION, Perl $], $^X" );
