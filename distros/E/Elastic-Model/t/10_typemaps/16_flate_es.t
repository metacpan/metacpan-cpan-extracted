#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Moose;
use Test::Exception;
use Test::Deep;

use lib 't/lib';

BEGIN {
    use_ok 'TypeTest' || print 'Bail out';
}

my $model = new_ok 'TypeTest';
isa_ok my $tm = $model->typemap, 'Elastic::Model::TypeMap::Base';

note '';
note "Flation for TypeTest::ES";

does_ok my $class = $model->class_for('TypeTest::ES'),
    'Elastic::Model::Role::Doc';

my $meta = $class->meta;

note '';

my ( $de, $in );

## KEYWORD ##

{
    ( $de, $in ) = flators('keyword');

    is $de->('foo'), 'foo', 'Deflate: keyword';
    is $in->('bar'), 'bar', 'Inflate: keyword';
}

## BINARY ##

{
    my $binary = join '', map { chr( oct($_) ) } qw(0 012 0305 0202);
    my $b64 = "AArFgg==\n";
    ( $de, $in ) = flators('binary');

    is $de->($binary), $b64,    'Deflate: binary';
    is $in->($b64),    $binary, 'Inflate: binary';
}

## GEO-POINT ##

{
    ( $de, $in ) = flators('geopoint');
    cmp_deeply $de->( { lat => 1, lon => 2 } ), { lat => 1, lon => 2 },
        'Deflate: geopoint';
    cmp_deeply $in->( { lat => 1, lon => 2 } ), { lat => 1, lon => 2 },
        'Inflate: geopoint';
}

## TIMESTAMP ##

{
    ( $de, $in ) = flators('timestamp');
    is $de->(1338634443.3589), 1338634443359,  'Deflate: timestamp';
    is $in->(1338634443359),   1338634443.359, 'Inflate: timestamp';
}

done_testing;

#===================================
sub flators {
#===================================
    my $name = shift;
    $name .= '_attr';

    note '';
    note "Flation: $name";

    ok my $attr = $meta->find_attribute_by_name($name), "Has attr: $name";
    return unless $attr;

    ok my $de = $tm->find_deflator($attr), "Deflator: $name";
    ok my $in = $tm->find_inflator($attr), "Inflator: $name";
    return ( $de, $in );
}

1;
