#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Debian::Releases' ) || print "Bail out!
";
}

diag( "Testing Debian::Releases $Debian::Releases::VERSION, Perl $], $^X" );
