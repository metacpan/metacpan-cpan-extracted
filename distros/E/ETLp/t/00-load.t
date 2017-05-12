#!perl 

use Test::More tests => 1;

BEGIN {
    use_ok( 'ETLp' ) || print "Bail out!
";
}

diag( "Testing ETLp $ETLp::VERSION, Perl $], $^X" );
    