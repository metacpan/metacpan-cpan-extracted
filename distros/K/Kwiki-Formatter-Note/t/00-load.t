#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::Formatter::Note' );
}

diag( "Testing Kwiki::Formatter::Note $Kwiki::Formatter::Note::VERSION, Perl $], $^X" );
