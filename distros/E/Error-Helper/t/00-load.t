#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Error::Helper' ) || print "Bail out!
";
}

diag( "Testing Error::Helper $Error::Helper::VERSION, Perl $], $^X" );
