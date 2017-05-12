#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'LaTeX::Decode' ) || print "Bail out!
";
}

diag( "Testing LaTeX::Decode $LaTeX::Decode::VERSION, Perl $], $^X" );
