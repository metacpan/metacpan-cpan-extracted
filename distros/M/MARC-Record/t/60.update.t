#!perl -Tw

use strict;
use integer;
use Data::Dumper;
use File::Spec;

use Test::More tests=>20;


BEGIN {
    use_ok( 'MARC::File::USMARC' );
}

my $filename = File::Spec->catfile( 't', 'camel.usmarc' );
my $file = MARC::File::USMARC->in( $filename );
isa_ok( $file, 'MARC::File::USMARC', 'USMARC file' );

my $marc = $file->next();
isa_ok( $marc, 'MARC::Record' ) or die "Can't read the test record";
$file->close;

my $field = $marc->field('245');
isa_ok( $field, 'MARC::Field', 'new 245' );

my $nchanges = $field->update('a' => 'Programming Python /', 'ind1' => '4' );
is( $marc->subfield('245','a') => 'Programming Python /',
  'Updated 1 subfield' );
is( $field->indicator(1) => '4', 'Indicator 1 changed' );
is( $nchanges, 2, 'number of changes is correct' );

$nchanges = $field->update('a' => 'Programming Python /', 'c' => 'Mark Lutz');
is( $field->as_string() => 'Programming Python / Mark Lutz', 
  'Updated 2 subfields');
is( $nchanges, 2, 'number of changes is correct' );


## make sure we can update fields with no subfields or indicators (000-009)

my $f003 = $marc->field('003');
isa_ok( $f003, 'MARC::Field' );
my $n = $f003->update('XXXX');
is( $n, 1, 'number of changes is correct' );

$f003 = $marc->field('003');
isa_ok( $f003, 'MARC::Field' );
is( $f003->as_string(), 'XXXX', 'Update for fields 000-009 works' ); 

## if an update is attempted on a non existent subfield it will be 
## appended to the end of the subfield

$field = $marc->field( '245' );
isa_ok( $field, 'MARC::Field', 'got 245' );
$n = $field->update( 'z' => 'foo bar' );
is( $n, 1, 'numer of changes correct' );
is( $field->subfield( 'z' ), 'foo bar', 'update() append worked' );

$n = $field->update( 'x' => 'homer', 'y' => 'plato', 'z' => 'bart' );
is( $n, 3, 'number of changes correct' );
is( $field->subfield( 'x' ), 'homer', 'update() append 1' );
is( $field->subfield( 'y' ), 'plato', 'update() append 2' );
is( $field->subfield( 'z' ), 'bart', 'update() append 3' );

