#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Mail::Mailer::smtp_auth' );
}

diag( "Testing Mail::Mailer::smtp_auth $Mail::Mailer::smtp_auth::VERSION, Perl $], $^X" );
