#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Email::IsFree::CN' ) || print "Bail out!
";
}

diag( "Testing Email::IsFree::CN $Email::IsFree::CN::VERSION, Perl $], $^X" );
