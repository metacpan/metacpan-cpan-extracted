#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Mail::SpamAssassin::Plugin::OpenPGP' );
}

diag( "Testing Mail::SpamAssassin::Plugin::OpenPGP $Mail::SpamAssassin::Plugin::OpenPGP::VERSION, Perl $], $^X" );
