#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'List::Analyse::Sequence' );
}

diag( "Testing List::Analyse::Sequence $List::Analyse::Sequence::VERSION, Perl $], $^X" );
