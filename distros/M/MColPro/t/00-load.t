#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MColPro' ) || print "Bail out!
";
}

diag( "Testing MColPro $MColPro::VERSION, Perl $], $^X" );
