use Test::More tests=>1;

use strict;
use Biblio::ILL::GS;
my $gs = new Biblio::ILL::GS;

$gs->set("LSB", "MWPL" );
$gs->set("LSP", "BVAS" );
$gs->set("P/U", "Christensen, David" );

$gs->set( "ADR", 
    "Public Library Services",
    "Interlibrary Loan Department",
    "1525 First Street South",
    "Brandon, MB  R7A 7A1"
);

$gs->set("SER", "LOAN" );
$gs->set("AUT", "Wall, Larry" );
$gs->set("TIT", "Programming Perl" );
$gs->set("P/L", "Cambridge, Mass." );
$gs->set("P/M", "O'Reilly" );
$gs->set("EDN", "2nd Ed." );
$gs->set("DAT", "2000" );
$gs->set("SBN", "0596000278" );
$gs->set("SRC", "TEST SCRIPT" );
$gs->set("REM", "This is a comment.", "And another comment." );

# get expected output off of the disk
open( IN, 't/expected.txt' );

# in case were running in a Win or Mac environment
binmode( IN );

# slurp in the file
$/ = undef;
my $expected = <IN>;

# makes sure as_string() outputs as expected
is( $gs->as_string(), $expected, 'as_string()' );
