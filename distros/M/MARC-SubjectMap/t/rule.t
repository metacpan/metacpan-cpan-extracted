use strict;
use warnings;
use Test::More qw( no_plan );

use_ok( 'MARC::SubjectMap::Rule' );

my $r = MARC::SubjectMap::Rule->new( {
    field       => '650',
    subfield    => 'a',
    original    => 'hello.',
    translation => 'hola',
    source      => 'bogus',
} );

is( $r->field(), '650', 'field()' );
is( $r->subfield(), 'a', 'subfield()' );
is( $r->original(), 'hello', 'original()' );
is( $r->translation(), 'hola', 'translation' );
is( $r->source(), 'bogus', 'source' );
is( $r->toXML(), join('',<DATA>), 'toXML()' );

__DATA__
<rule field="650" subfield="a">
<original>hello</original>
<translation>hola</translation>
<source>bogus</source>
</rule>
