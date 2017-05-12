#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Mail::SpamAssassin::Plugin::Konfidi' );
}

diag( "Testing Mail::SpamAssassin::Plugin::Konfidi $Mail::SpamAssassin::Plugin::Konfidi::VERSION, Perl $], $^X" );
