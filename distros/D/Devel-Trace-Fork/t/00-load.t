#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Devel::Trace::Fork' ) || print "Bail out!
";
}

diag( "Testing Devel::Trace::Fork $Devel::Trace::Fork::VERSION, Perl $], $^X" );
