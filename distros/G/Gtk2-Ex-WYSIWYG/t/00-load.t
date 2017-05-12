#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Gtk2::Ex::WYSIWYG' ) || print "Bail out!
";
}

diag( "Testing Gtk2::Ex::WYSIWYG $Gtk2::Ex::WYSIWYG::VERSION, Perl $], $^X" );
