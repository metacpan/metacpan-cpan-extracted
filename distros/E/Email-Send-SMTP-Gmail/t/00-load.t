#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Email::Send::SMTP::Gmail' ) || print "Bail out!
";
}

diag( "Testing Email::Send::SMTP::Gmail $Email::Send::SMTP::Gmail::VERSION, Perl $], $^X" );
