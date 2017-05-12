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
note "Flation for TypeTest::Common";

does_ok my $class = $model->class_for('TypeTest::Common'),
    'Elastic::Model::Role::Doc';

my $meta = $class->meta;

note '';

my ( $de, $in );

## DATETIME ##

{
    ( $de, $in ) = flators('datetime');
    my $date = DateTime->new(
        year      => 1964,
        month     => 10,
        day       => 16,
        hour      => 16,
        minute    => 12,
        second    => 47,
        time_zone => 'Asia/Taipei'
    );

    is $de->($date), '1964-10-16T08:12:47', 'Deflate: date';
    is $in->('1964-10-16T08:12:47'), $date->set_time_zone('UTC'),
        'Inflate: date';
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
