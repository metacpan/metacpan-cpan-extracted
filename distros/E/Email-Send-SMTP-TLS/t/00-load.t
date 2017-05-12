#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Email::Send::SMTP::TLS' );
}

diag( "Testing Email::Send::SMTP::TLS $Email::Send::SMTP::TLS::VERSION, Perl $], $^X" );
