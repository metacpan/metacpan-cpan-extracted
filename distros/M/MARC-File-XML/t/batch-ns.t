use strict;
use warnings;

use Test::More tests => 23;

use Data::Dumper;
use_ok( 'MARC::File::XML' );
use_ok( 'MARC::Batch' );

my $batch = MARC::Batch->new( 'XML', 't/batch-ns.xml' );
isa_ok( $batch, 'MARC::Batch' );

my @titles = ( 
'ActivePerl with ASP and ADO / Tobias Martinsson.',
'Programming the Perl DBI / Alligator Descartes and Tim Bunce.',
'Perl : programmer\'s reference / Martin C. Brown.',
'Perl : the complete reference / Martin C. Brown.',
'CGI programming with Perl / Scott Guelich, Shishir Gundavaram & Gunther Birznieks.',
'Proceedings of the Perl Conference 4.0 : July 17-20, 2000, Monterey, California.',
'Perl for system administration / David N. Blank-Edelman.',
'Programming Perl / Larry Wall, Tom Christiansen & Jon Orwant.',
'Perl programmer\'s interactive workbook / Vincent Lowe.',
'Cross-platform Perl / Eric F. Johnson.',
);

my @leaders = (
'00755cam  22002414a 4500',
'00647pam  2200241 a 4500',
'00605cam  22002054a 4500',
'00579cam  22002054a 4500',
'00801nam  22002778a 4500',
'00665nam  22002298a 4500',
'00579nam  22002178a 4500',
'00661nam  22002538a 4500',
'00603cam  22002054a 4500',
'00696nam  22002538a 4500',
);

my $count = 0;
while ( my $record = $batch->next() ) { 
    $count++;
    is( $record->leader(), shift(@leaders), "found leader $count" );
    is( $record->title(), shift(@titles), "found title $count" );
}

