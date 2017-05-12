use strict;
use warnings;
use Test::More qw( no_plan );
use MARC::Record;
use MARC::Field;
use File::Temp qw( tempfile );

use_ok( 'MARC::SubjectMap' );
use_ok( 'MARC::SubjectMap::Field' );
use_ok( 'MARC::SubjectMap::Rules' );
use_ok( 'MARC::SubjectMap::Rule' );

## configure MARC::SubjectMap object, remember the fields we 
## added so we can pass them into translateField even though
## most code would never use translateField directly
my $map = MARC::SubjectMap->new();
my $field600 = MARC::SubjectMap::Field->new( { 
    tag         => 600, 
    translate   => ['a','b'], 
} );
$map->addField( $field600 );
my $field650 = MARC::SubjectMap::Field->new( { 
    tag         => 650, 
    translate   => ['a'] 
} );
$map->addField( $field650 );

## log to a temp file
my ($fh,$filename) = tempfile();
$map->setLog($fh);

## set up some translation rules
my $rules = MARC::SubjectMap::Rules->new();
$rules->addRule(
    MARC::SubjectMap::Rule->new( {
        field       => '600',
        subfield    => 'a',
        original    => 'foo',
        translation => 'bar',
        source      => 'bogus'
    } )
);
$rules->addRule(
    MARC::SubjectMap::Rule->new( {
        field       => '600',
        subfield    => 'b',
        original    => 'goo',
        translation => 'gar',
        source      => 'bogusy'
    } )
);
$rules->addRule(
    MARC::SubjectMap::Rule->new( {
        field       => '650',
        subfield    => 'a',
        original    => 'COMMON LISP (Computer Program Language)',
        translation => 'Python (Computer Program Language)',
        source      => 'bogus'
    } )
);
$map->rules( $rules );

VERIFY_FIELD_TRANSLATION: {
    my $old = MARC::Field->new( '600', '', '0', a=>'foo', b=>'goo' );
    my $new = $map->translateField($old,$field600);
    isa_ok( $new, 'MARC::Field' );
    is( $new->indicator(2), 7, 'indicator 2 is set properly to 7' );
    my @subfields = $new->subfields();
    is( @subfields, 3, 'expected number of subfields after translateField()' );
    is_deeply( $subfields[0], ['a','bar'], 'translateField() 1' );
    is_deeply( $subfields[1], ['b','gar.'], 'translateField() 2' );
    is_deeply( $subfields[2], ['2','bogus'], 'translateField() 3' );
}

VERIFY_SOURCE_WHEN_SUBFIELD_A_IS_ABSENT: {
    my $old = MARC::Field->new( '600', '', '0', b=>'goo' );
    my $new = $map->translateField($old,$field600);
    isa_ok( $new, 'MARC::Field' );
    is( $new->subfield(2), "bogusy", "got last source" );
}

VERIFY_SOURCE_WHEN_NOT_SUBFIELD_A: {
    my $old = MARC::Field->new( '600', '', '0', a=>'foo', b=>'goo', a=>'foo');
    my $field600 = MARC::SubjectMap::Field->new( { 
        tag             => 600, 
        translate       => ['a','b'], 
        sourceSubfield  => 'b',
    } );
    my $new = $map->translateField($old,$field600);
    isa_ok( $new, 'MARC::Field' );
    is( $new->subfield(2), "bogusy", "got correct non subfield a source" );
}

VERIFY_REAL_TRANSLATION: {
    my $old = MARC::Field->new( '650', '', '0', 
        a=>'COMMON LISP (Computer Program Language)' );
    my $new = $map->translateField($old,$field650);
    isa_ok( $new, 'MARC::Field' );
    is( $new->indicator(2), 7, 'indicator 2 is set properly to 7' );
    my @subfields = $new->subfields();
    is( @subfields, 2, 'expected number of subfields after translateField()' );
    is_deeply( $subfields[0], ['a','Python (Computer Program Language)'], 
        'translateField() 1' );
    is_deeply( $subfields[1], ['2','bogus'], 'translateField() 3' );
}

VERIFY_FAILED_FIELD_TRANSLATION: {
    my $old = MARC::Field->new( '600', '', '0', a=>'foo', b=>'foo' );
    my $new = $map->translateField($old,$field600);
    ok( ! $new, 'failed field translation returned undef' );
}

VERIFY_ONLY_LCSH_FIELD: {
    my $old = MARC::Field->new( '600', '', '1', a=>'foo', b=>'goo' );
    my $field600 = MARC::SubjectMap::Field->new( { 
        tag             => 600, 
        translate       => ['a','b'], 
        indicator2      => 0,
    } );
    my $new = $map->translateField($old,$field600);
    ok( ! $new, 'lcsh field only' );
}

VERIFY_RECORD_TRANSLATION: {
    my $old = MARC::Record->new();
    $old->append_fields(MARC::Field->new('600', '', '0', a=>'foo', b=>'goo.' ));
    my $new = $map->translateRecord($old);
    isa_ok( $new, 'MARC::Record' );
    my @fields = $new->fields( '600' );
    is( @fields, 2, 'found expected fields after translateRecord()' );
    my @subfields = $fields[1]->subfields();
    is_deeply( $subfields[0], ['a','bar'], 'translateRecord() 1' );
    is_deeply( $subfields[1], ['b','gar.'], 'translateRecord() 2' );
    is_deeply( $subfields[2], ['2','bogus'], 'translateRecord() 3' );
    is( $fields[1]->indicator(2), 7, 'indicator 2 is set properly' );
}

VERIFY_REAL_RECORD_TRANSLATION: {
    my $old = MARC::Record->new();
    $old->append_fields(MARC::Field->new('650', '', '0', 
        a=>'COMMON LISP (Computer Program Language)' ));
    my $new = $map->translateRecord($old);
    isa_ok( $new, 'MARC::Record' );
    my @fields = $new->fields( '650' );
    is( @fields, 2, 'found expected fields after translateRecord()' );
    my @subfields = $fields[1]->subfields();
    is_deeply( $subfields[0], ['a','Python (Computer Program Language)'], 'translateRecord() 1' );
    is_deeply( $subfields[1], ['2','bogus'], 'translateRecord() 2' );
    is( $fields[1]->indicator(2), 7, 'indicator 2 is set properly' );
}

VERIFY_FAILED_RECORD_TRANSLATION: {
    my $old = MARC::Record->new();
    $old->append_fields(MARC::Field->new('600', '', '0', a=>'foo', b=>'hoo' ));
    my $new = $map->translateRecord($old);
    ok( ! $new, 'failed record translation returned undef' );
}

