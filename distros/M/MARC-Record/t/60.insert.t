#!perl -Tw

use strict;
use integer;
use File::Spec;

use Test::More tests=>20;

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

my $newagain = MARC::Field->new('650','','0','a','Hockey etiquette.');
isa_ok( $newagain, 'MARC::Field', 'Field creation' );

## test append_fields()

my $nappended = $record->append_fields($new);
is( $nappended, 1, "Added one field" );

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
my $ndeleted = $record->delete_field($new);
is( $ndeleted, 1, "Deleted one field" );

## test insert_fields_after

my $nadds = $record->insert_fields_after($f650,$new,$newagain);
is( $nadds, 2, 'Added 2 fields' );

$expected = 
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
650  0 _aWorld Wide Web.
650  0 _aHockey etiquette.
630 00 _aActive server pages.
630 00 _aActiveX.
MARC_DATA
chomp($expected);

is($record->as_formatted,$expected,'insert_fields_after');
my $n = $record->delete_field($new);
is( $n, 1 );

$n = $record->delete_field($newagain);
is( $n, 1 );

# marker field for last field of record - testing rt55993
my $new999 = MARC::Field->new('999', ' ', ' ', a => 'last field');
$nappended = $record->append_fields($new999);
is ( $nappended, 1, 'added 999 field as last field (RT#55993 test)' );

$nadds = $record->insert_fields_after($new999,$newagain);

is( $nadds, 1, 'added 650 after last field in record (RT#55993 test)' );

$n = $record->delete_field($newagain);
is( $n, 1 );

$n = $record->delete_field($new999);
is( $n, 1, 'deleted 999 field' );

## test insert_record_before

$nadds = $record->insert_fields_before($f650, MARC::Field->new('650','4','3','a','House painting.'), $new );
is( $nadds, 2, 'Added 2 more fields' );

$expected = 
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
650 43 _aHouse painting.
650  0 _aWorld Wide Web.
650  0 _aPerl (Computer program language)
630 00 _aActive server pages.
630 00 _aActiveX.
MARC_DATA
chomp($expected);

is($record->as_formatted,$expected,'insert_fields_before');


