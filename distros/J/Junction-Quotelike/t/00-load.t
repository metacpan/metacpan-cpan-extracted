#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Junction::Quotelike', 'qone' ) || print "Bail out!
";
}

diag( "Testing Junction::Quotelike $Junction::Quotelike::VERSION, Perl $], $^X" );
