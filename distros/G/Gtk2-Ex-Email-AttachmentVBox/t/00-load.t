#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Gtk2::Ex::Email::AttachmentVBox' );
}

diag( "Testing Gtk2::Ex::Email::AttachmentVBox $Gtk2::Ex::Email::AttachmentVBox::VERSION, Perl $], $^X" );
