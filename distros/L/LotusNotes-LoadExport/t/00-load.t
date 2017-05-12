#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'LotusNotes::LoadExport' );
}

diag( "Testing LotusNotes::LoadExport $LotusNotes::LoadExport::VERSION, Perl $], $^X" );
