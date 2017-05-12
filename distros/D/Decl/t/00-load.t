#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Decl' ) || print "Bail out!
";
}

diag( "Testing Decl $Decl::VERSION, Perl $], $^X" );
