#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'JavaScript::Sprockets' ) || print "Bail out!
";
}

diag( "Testing JavaScript::Sprockets $JavaScript::Sprockets::VERSION, Perl $], $^X" );
