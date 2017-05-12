#!perl -Tw

use strict;
use integer;

use Test::More tests=>8;
use File::Spec;

BEGIN {
    use_ok( 'MARC::Batch' );
    use_ok( 'MARC::Field' );
}

my $filename = File::Spec->catfile( 't', 'camel.usmarc' );
my $batch = new MARC::Batch( 'MARC::File::USMARC', $filename );
isa_ok( $batch, 'MARC::Batch', 'Batch object creation' );

my $record = $batch->next();
isa_ok( $record, 'MARC::Record', 'Record object creation' );

my $f650 = $record->field('650');
isa_ok( $f650, 'MARC::Field', 'Field retrieval' );

my $new = MARC::Field->new('650','','0','a','World Wide Web.');
isa_ok( $new, 'MARC::Field', 'Field creation' );

my $nadded = $record->append_fields($new);
is( $nadded, 1 );

my $expected = 
<<MARC_DATA;
LDR 00755cam  22002414a 4500
001     fol05731351 
003     IMchF
005     20000613133448.0
008     000107s2000    nyua          001 0 eng  
010    _a   00020737 
020    _a0471383147 (paper/cd-rom : alk. paper)
040    _aDLC
       _cDLC
       _dDLC
042    _apcc
050 00 _aQA76.73.P22
       _bM33 2000
082 00 _a005.13/3
       _221
100 1  _aMartinsson, Tobias,
       _d1976-
245 10 _aActivePerl with ASP and ADO /
       _cTobias Martinsson.
260    _aNew York :
       _bJohn Wiley & Sons,
       _c2000.
300    _axxi, 289 p. :
       _bill. ;
       _c23 cm. +
       _e1 computer  laser disc (4 3/4 in.)
500    _a"Wiley Computer Publishing."
650  0 _aPerl (Computer program language)
630 00 _aActive server pages.
630 00 _aActiveX.
650  0 _aWorld Wide Web.
MARC_DATA
chomp($expected);

is($record->as_formatted, $expected, "append_fields");

