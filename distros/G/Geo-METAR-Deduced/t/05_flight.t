#!/usr/bin/env perl
# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2021, Roland van Ipenburg
use strict;
use warnings;
use utf8;
use 5.014000;

use Test::More;
use Test::NoWarnings;

our $VERSION = 'v1.0.4';

my @metars = (
## no critic (ProhibitMagicNumbers)
    [
        'KFDY 260950Z AUTO 29011KT 1/4SM OVC001 16/16 Q1010',
        0,
        '.25 statute mile visibility with 100ft ceiling is low IFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 3/4SM OVC004 16/16 Q1010',
        0,
        '.75 statute mile visibility with 400ft ceiling is low IFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 3/4SM OVC005 16/16 Q1010',
        0,
        '.75 statute mile visibility with 500ft ceiling is low IFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 1SM OVC004 16/16 Q1010',
        0,
        '1 statute mile visibility with 400ft ceiling is low IFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 4SM VV009 16/16 Q1010',
        1,
        '4 statute mile visibility with 900ft ceiling is IFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 1SM OVC005 16/16 Q1010',
        1,
        '1 statute mile visibility with 500ft ceiling is IFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 3SM OVC010 16/16 Q1010',
        2,
        '3 statute mile visibility with 1000ft ceiling is MVFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 5SM OVC025 16/16 Q1010',
        2,
        '5 statute mile visibility with 2500ft ceiling is MVFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 5SM OVC030 16/16 Q1010',
        2,
        '5 statute mile visibility with 3000ft ceiling is MVFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 5 1/4SM OVC031 16/16 Q1010',
        3,
        '5.25 statute mile visibility with 3100ft ceiling is MVFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 15SM OVC065 16/16 Q1010',
        3,
        '15 statute mile visibility with 6500ft ceiling is MVFR in US rules',
    ],
## use critic
);

Test::More::plan 'tests' => ( 0 + @metars ) + 1;

require Geo::METAR::Deduced;
my $m = Geo::METAR::Deduced->new();
foreach my $metar (@metars) {
    $m->metar( @{$metar}[0] );
    Test::More::is( $m->flight_rule(), @{$metar}[1], @{$metar}[2] );
}
