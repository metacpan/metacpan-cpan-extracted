use Test::More tests=>7;

use strict;
use Biblio::ILL::GS;
my $gs = new Biblio::ILL::GS;

eval{ $gs->as_string() };
like( $@, qr/missing mandatory field: LSB/, 'minimum data: LSB' );
$gs->set("LSB", "MWPL" );

eval{ $gs->as_string() };
like( $@, qr/missing mandatory field: LSP/, 'minimum data: LSP');
$gs->set("LSP", "BVAS" );

eval{ $gs->as_string() };
like( $@, qr/missing mandatory field: ADR/, 'minimum data: ADR');
$gs->set( "ADR", 
    "Public Library Services",
    "Interlibrary Loan Department",
    "1525 First Street South",
    "Brandon, MB  R7A 7A1"
);

eval{ $gs->as_string() };
like( $@, qr/missing mandatory field: SER/, 'minimum data: SER');
$gs->set("SER", "LOAN" );

eval{ $gs->as_string() };
like( $@, qr/missing mandatory field: AUT/, 'minimum data: AUT');
$gs->set("AUT", "Wall, Larry" );

eval{ $gs->as_string() };
like( $@, qr/missing mandatory field: TIT/, 'minimum data: TIT');
$gs->set("TIT", "Programming Perl" );

$gs->set("P/L", "Cambridge, Mass." );
$gs->set("P/M", "O'Reilly" );
$gs->set("EDN", "2nd Ed." );
$gs->set("DAT", "2000" );
$gs->set("SBN", "0596000278" );
$gs->set("SRC", "TEST SCRIPT" );
$gs->set("REM", "This is a comment.", "And another comment." );
$gs->set("P/U", "Christensen, David" );

isn't( $gs->as_string(), undef, 'minimum data');

