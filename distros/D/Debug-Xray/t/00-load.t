#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Debug::Xray' ) || print "Bail out!
";
}

diag( "Testing Debug::Xray $Debug::Xray::VERSION, Perl $], $^X" );
