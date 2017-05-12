#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'HTML::Auto' ) || print "Bail out!
";
}

diag( "Testing HTML::Auto $HTML::Auto::VERSION, Perl $], $^X" );
