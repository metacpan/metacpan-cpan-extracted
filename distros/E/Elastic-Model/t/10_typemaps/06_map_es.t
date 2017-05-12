#!/usr/bin/perl

use strict;
use warnings;

our $test_class = 'TypeTest::ES';

our @mapping = (
    'keyword' => {
        type  => 'string',
        index => 'not_analyzed'
    },
    'binary'    => { type => 'binary' },
    'geopoint'  => { type => 'geo_point' },
    'timestamp' => { type => 'date' },
);

# TODO: IP, Attachment

do 't/10_typemaps/test_mapping.pl' or die $!;

1;
