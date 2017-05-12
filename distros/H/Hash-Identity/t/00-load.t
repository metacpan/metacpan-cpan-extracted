#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Hash::Identity' ) || print "Bail out!
";
}

diag( "Testing Hash::Identity $Hash::Identity::VERSION, Perl $], $^X" );
