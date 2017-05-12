#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Mail::IMAPTalk::MailCache' );
}

diag( "Testing Mail::IMAPTalk::MailCache $Mail::IMAPTalk::MailCache::VERSION, Perl $], $^X" );
