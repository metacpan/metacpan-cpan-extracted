#!/usr/bin/perl

use strict;
use warnings;

our $test_class = 'FieldTest::GeoPoint';

our @mapping = (
    'basic' => { type => 'geo_point' },

    'options' => {
        geohash           => 1,
        geohash_precision => 8,
        index_name        => "foo",
        lat_lon           => 1,
        store             => "yes",
        type              => "geo_point",
    },

    multi => {
        type   => "multi_field",
        fields => {
            multi_attr => { type              => "geo_point" },
            one        => { geohash_precision => 2, type => "geo_point" },
        },
    },

    bad_opt   => qr/doesn't understand 'analyzer'/,
    bad_multi => qr/doesn't understand 'analyzer'/

);

do 't/10_typemaps/test_field.pl' or die $!;

1;
