#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Mail::IMAPTalk::SortHelper' );
}

diag( "Testing Mail::IMAPTalk::SortHelper $Mail::IMAPTalk::SortHelper::VERSION, Perl $], $^X" );
