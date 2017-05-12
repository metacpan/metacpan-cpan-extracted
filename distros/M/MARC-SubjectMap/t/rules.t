use strict;
use warnings;
use Test::More qw( no_plan );
use File::Temp qw( tempfile );

use_ok( 'MARC::SubjectMap::Rules' );
use_ok( 'MARC::SubjectMap::Rule' );

CONSTRUCTOR: {
    my $rules = MARC::SubjectMap::Rules->new();
    isa_ok( $rules, 'MARC::SubjectMap::Rules' );
}

ADD_RULE: {
    my $rules = MARC::SubjectMap::Rules->new();
    $rules->addRule(
        MARC::SubjectMap::Rule->new({
            field       => '600',
            subfield    => 'a',
            original    => 'foo bar',
            translation => 'bar foo',
            source      => 'bogus'
        })
    );
    $rules->addRule(
        MARC::SubjectMap::Rule->new({
            field       => '600',
            subfield    => 'a',
            original    => 'cheeze',
            translation  => 'frommage',
            source      => 'bogus',
        })
    );
    $rules->addRule(
        MARC::SubjectMap::Rule->new({
            field       => '610',
            subfield    => 'b',
            original    => 'cha cha',
            translation => 'chi chi',
            source      => 'bogus'
        })
    );
    is( $rules->getRule( field => '600', subfield => 'b', original => 'foo' ), 
        undef, 'getRule() when there is no rule for field/subfield' );

    my $rule = $rules->getRule( field => '600', subfield => 'a',
        original => 'foo bar' );
    isa_ok( $rule, 'MARC::SubjectMap::Rule' );
    is( $rule->translation(), 'bar foo', 'translation() 1' );

    $rule = $rules->getRule( field => '610', subfield => 'b', 
        original => 'cha cha' );
    isa_ok( $rule, 'MARC::SubjectMap::Rule' );
    is( $rule->translation(), 'chi chi', 'translation() 2' );

    ## serialize rules as XML
    my ($fh,$file) = tempfile(); 
    $rules->toXML($fh);
    close($fh);

    ## check out the XML
    open(XML,$file);
    my $xml = join( '', <XML> );
    my $expectedXML = join( '', <DATA> );
    is( $xml, $expectedXML, 'toXML()' );

}

__DATA__
<!-- the rule mappings themselves -->
<rules>

<rule field="610" subfield="b">
<original>cha cha</original>
<translation>chi chi</translation>
<source>bogus</source>
</rule>

<rule field="600" subfield="a">
<original>cheeze</original>
<translation>frommage</translation>
<source>bogus</source>
</rule>

<rule field="600" subfield="a">
<original>foo bar</original>
<translation>bar foo</translation>
<source>bogus</source>
</rule>

</rules>
