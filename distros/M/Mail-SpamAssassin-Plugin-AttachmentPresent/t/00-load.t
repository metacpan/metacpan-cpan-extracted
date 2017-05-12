#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Mail::SpamAssassin::Plugin::AttachmentPresent' );
}

diag( "Testing Mail::SpamAssassin::Plugin::AttachmentPresent $Mail::SpamAssassin::Plugin::AttachmentPresent::VERSION, Perl $], $^X" );
