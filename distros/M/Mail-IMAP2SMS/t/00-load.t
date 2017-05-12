#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Mail::IMAP2SMS' );
}

diag( "Testing Mail::IMAP2SMS $Mail::IMAP2SMS::VERSION, Perl $], $^X" );
