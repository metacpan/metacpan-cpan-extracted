#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Jifty::Plugin::GoogleAnalytics' );
}

diag( "Testing Jifty::Plugin::GoogleAnalytics $Jifty::Plugin::GoogleAnalytics::VERSION, Perl $], $^X" );
