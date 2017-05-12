#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Jifty::Plugin::JapaneseNotification' );
}

diag( "Testing Jifty::Plugin::JapaneseNotification $Jifty::Plugin::JapaneseNotification::VERSION, Perl $], $^X" );
