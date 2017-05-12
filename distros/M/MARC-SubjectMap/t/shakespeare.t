use Test::More qw( no_plan );
use strict;
use warnings;
use MARC::Field;

# a focused test of translation, making sure we don't get a 
# new field when subfields are only copied and none are translated

use_ok( "MARC::SubjectMap" );
use_ok( "MARC::SubjectMap::Rules" );
use_ok( "MARC::SubjectMap::Rule" );

my $map = MARC::SubjectMap->new();

# copy 600 ad and translate 600 x
my $field600 = MARC::SubjectMap::Field->new( { 
    tag             => 600, 
    translate       => ['x'], 
    copy            => ['a','d'],
    sourceSubfield  => 'x',
} );
$map->addField( $field600 );

# create rules
my $rules = MARC::SubjectMap::Rules->new();
$rules->addRule( 
    MARC::SubjectMap::Rule->new( {
        field       => 600,
        subfield    => 'x',
        original    => 'History and criticism',
        translation => 'Historica y critico',
        source      => 'bidex',
    } )
);
$map->rules( $rules );

ALL_COPY: {
    # this translation should fail since it's all copying 
    my $field = MARC::Field->new( '600', '', '', 
        a   => 'Shakespeare, William ',
        d   => '15XX-16XX',
    );
    my $new = $map->translateField( $field, $field600 );
    ok( ! $new, 'only copies means no translate' );
}

WITH_TRANSLATE: {
    # this translation should succeed since there is one translation
    my $field = MARC::Field->new( '600', '', '', 
        a   => 'Shakespeare, William ',
        d   => '15XX-16XX ',
        x   => 'History and criticism.' 
    );
    my $new = $map->translateField( $field, $field600);
    ok( $new, 'got new field' );
    is_deeply( [ $new->subfields() ], [ 
        [ a   => 'Shakespeare, William ' ],
        [ d   => '15XX-16XX ' ],
        [ x   => 'Historica y critico.' ],
        [ 2   => 'bidex' ] ], 
        'got expected new field' );
}

