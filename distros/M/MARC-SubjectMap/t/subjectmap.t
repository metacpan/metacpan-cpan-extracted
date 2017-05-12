use strict;
use warnings;
use Test::More qw( no_plan );
use File::Temp qw( tempfile );

use_ok( 'MARC::SubjectMap' );
use_ok( 'MARC::SubjectMap::Field' );
use_ok( 'MARC::SubjectMap::Rule' );

CONSTRUCTOR: {
    my $map = MARC::SubjectMap->new();
    isa_ok( $map, 'MARC::SubjectMap' );
}

ADD_FIELD: {
    my $map = MARC::SubjectMap->new();
    $map->addField(
        MARC::SubjectMap::Field->new({
            tag         => '650',
            translate   => ['a','z'],
            copy        => ['c','d'],
        })
    );
    $map->addField(
        MARC::SubjectMap::Field->new({
            tag         => '600',
            translate   => ['f','g'],
            copy        => ['w','o'],
        })
    );
    my @fields = $map->fields();
    is( @fields, 2, 'fields() found 2 fields' );
    is( $fields[0]->tag(), '650', 'field 1' );
    is( $fields[1]->tag(), '600', 'field 2' );
}

SET_RULES: {
    my $map = MARC::SubjectMap->new();
    ok( ! $map->rules(), 'no rules yet' );
    $map->rules( MARC::SubjectMap::Rules->new() );
    ok( $map->rules(), 'got rules' );
}

XML: {
    my $map = MARC::SubjectMap->new();

    $map->sourceLanguage( 'en' );

    ## add some fields to the config
    $map->addField(
        MARC::SubjectMap::Field->new({
            tag         => '650',
            translate   => ['a','z'],
            copy        => ['c','d'],
        })
    );
    $map->addField(
        MARC::SubjectMap::Field->new({
            tag         => '600',
            translate   => ['f','g'],
            copy        => ['w','o'],
        })
    );

    ## add some rules to the config
    my $rules = MARC::SubjectMap::Rules->new();
    $rules->addRule( 
        MARC::SubjectMap::Rule->new({
            field       => '650',
            subfield    => 'a',
            original    => 'hello',
            translation => 'hola',
            source      => 'bogus',
        })
    );
    $rules->addRule(
        MARC::SubjectMap::Rule->new({
            field       => '650',
            subfield    => 'a',
            original    => 'goodbye',
            translation => 'adios',
            source      => 'bogus',
        })
    );
    $map->rules($rules);

    ## capture xml
    my ($fh,$file) = tempfile();
    $map->toXML( $fh );
    close($fh);

    ## check the XML
    open(XML,$file);
    my $xml = join('',<XML>);
    my $expected = join('',<DATA>);
    is( $xml, $expected, 'toXML()' );

}

__DATA__
<?xml version="1.0" encoding="ISO-8859-1"?>
<config>

<!-- the original language -->
<sourceLanguage>en</sourceLanguage>

<!-- the fields and subfields to be processed -->
<fields>

<field tag="650">
<copy>c</copy>
<copy>d</copy>
<translate>a</translate>
<translate>z</translate>
<sourceSubfield>a</sourceSubfield>
</field>

<field tag="600">
<copy>w</copy>
<copy>o</copy>
<translate>f</translate>
<translate>g</translate>
<sourceSubfield>a</sourceSubfield>
</field>

</fields>

<!-- the rule mappings themselves -->
<rules>

<rule field="650" subfield="a">
<original>goodbye</original>
<translation>adios</translation>
<source>bogus</source>
</rule>

<rule field="650" subfield="a">
<original>hello</original>
<translation>hola</translation>
<source>bogus</source>
</rule>

</rules>

</config>
