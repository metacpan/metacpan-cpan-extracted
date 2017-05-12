#!perl -Tw

use Test::More tests => 29;

use strict;
use File::Spec;

BEGIN {
    use_ok( 'MARC::Record' );
    use_ok( 'MARC::Field' );
    use_ok( 'MARC::File' );
    use_ok( 'MARC::File::USMARC' );
    use_ok( 'MARC::File::MicroLIF' );
}

## According to the MARC spec tags can have alphanumeric
## characters in them. They are rarely seen, but they are 
## allowed...and believe it or not some people actually use them!
## Tags must be alphanumeric, and three characters long.

my $record = MARC::Record->new();
isa_ok( $record, "MARC::Record" );

my $field;

## this should fail since it is four chars long 
eval {
    $field = MARC::Field->new( '245A', '', '', 'a' => 'Test' );
};
ok( !defined $field );
like($@ ,qr/Tag "245A" is not a valid tag/, 'caught invalid tag "245A"' );

## this should fail since it is a four digit number
eval { 
    $field = MARC::Field->new( '2456', '', '', 'a' => 'Test' );
};
ok( !defined $field );
like($@, qr/Tag "2456" is not a valid tag/, 'caught invalid tag "2456"' );

## this should work be ok
$field = MARC::Field->new( 'RAZ', '1', '2', 'a' => 'Test' );
isa_ok( $field, 'MARC::Field', 'field with alphanumeric tag' );

is ( $field->subfield('a'), 'Test', 'subfield()' );

my $n = $field->update( 'a' => '123' );
is( $n, 1 );
is( $field->subfield('a'), '123', 'update()' );

is_deeply( $field->subfields(), [ 'a' => 123 ], 'subfields()' );
is( $field->tag(), 'RAZ', 'tag()' );

is( $field->indicator(1), '1', 'indicator(1)' );
is( $field->indicator(2), '2', 'indicator(2)' );

$field->add_subfields( 'b' => 'Tweak' );
is( $field->subfield('b'), 'Tweak', 'add_subfields()' );
is( $field->as_string(), '123 Tweak', 'as_string()' );

my $text = "RAZ 12 _a123\n       _bTweak";
is( $field->as_formatted(), $text, 'as_formatted()' );

## make sure we can add a field with an alphanumeric tag to 
## a MARC::Record object

$record->append_fields( $field );
my $new = $record->field('RAZ');
isa_ok( $new, 'MARC::Field', 'able to grab field with alpha tag' );

$new = MARC::Field->new('100', '', '', 'a' => 'Gates, Bill');
$record->append_fields( $new );

$new = MARC::Field->new('110', '', '', 'a' => 'Microsoft');
$record->append_fields( $new );

my @fields = $record->field( '1..' );
is( scalar(@fields), 2, 'field(regex)' );

## test output as USMARC

my $marc = $record->as_usmarc();

my $filename = "$$.usmarc";
open(my $OUT, '>', $filename);
print $OUT $record->as_usmarc();
close($OUT);

my $file = MARC::File::USMARC->in( $filename );
isa_ok( $file, 'MARC::File::USMARC', "Opened $filename" );

my $newRec = $file->next();
isa_ok( $newRec, 'MARC::Record' );

is( $newRec->as_usmarc(), $marc, 'as_usmarc()' );
unlink( $filename );


## test output as MicroLIF

my $micro = $record->as_formatted();

my $lifname = File::Spec->catfile( 't', 'alphatag.lif' );
$file = MARC::File::MicroLIF->in( $lifname );
isa_ok( $file, 'MARC::File::MicroLIF' );
$newRec = $file->next();
isa_ok( $newRec, 'MARC::Record' );
is ($newRec->as_formatted(), $micro, 'as_formatted()' );

