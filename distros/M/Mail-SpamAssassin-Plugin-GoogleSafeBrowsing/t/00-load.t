#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Mail::SpamAssassin::Plugin::GoogleSafeBrowsing' );
}

diag( "Testing Mail::SpamAssassin::Plugin::GoogleSafeBrowsing $Mail::SpamAssassin::Plugin::GoogleSafeBrowsing::VERSION, Perl $], $^X" );
