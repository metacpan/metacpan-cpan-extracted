#!/usr/bin/env perl
# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2021, Roland van Ipenburg
use strict;
use warnings;
use utf8;
use 5.014000;

our $VERSION = 'v1.0.3';

use Test::More;
use Test::NoWarnings;

use version;

my @metars = (
## no critic (ProhibitMagicNumbers)
    [
        'KFDY 251450Z 21012G21KT 8SM VV065 04/M01 A3010 RMK 57014',
        6500,
        'Vertical visibility of 6500 feet makes ceiling 6500 feet in US',
    ],
    [
        'KFDY 251450Z 21012G21KT 8SM OVC065 04/M01 A3010 RMK 57014',
        6500,
        'Overcast at 6500 feet makes ceiling 6500 feet',
    ],
    [
        'KFDY 251450Z 21012G21KT 8SM OVC064 OVC065 04/M01 A3010 RMK 57014',
        6400,
        'Overcast at 6400 and 6500 feet makes ceiling 6400 feet',
    ],
    [
        'EHAM 251450Z 21012G21KT 8SM OVC200 04/M01 A3010 RMK 57014',
        'Inf',
        'Overcast at 20000ft makes ceiling unlimited under ICAO rules',
    ],
    [
        'EHAM 251450Z 21012G21KT 8SM OVC199 04/M01 A3010 RMK 57014',
        19_900,
        'Overcast at 19900ft makes ceiling 19900ft under ICAO rules',
    ],
    [
        'EGFF 251450Z 21012G21KT 8SM OVC200 04/M01 A3010 RMK 57014',
        20_000,
        'Overcast at 20000ft makes ceiling 20000ft in UK',
    ],
    [
        'KFDY 251450Z 21012G21KT 8SM OVC200 04/M01 A3010 RMK 57014',
        20_000,
        'Overcast at 20000ft makes ceiling 20000ft in US',
    ],
    [
        'EHAM 261625Z 13006KT 090V170 CAVOK 29/15 Q1008 NOSIG',
        'Inf',
        'CAVOK makes ceiling unlimited in ICAO',
    ],
## use critic
);

Test::More::plan 'tests' => ( 0 + @metars ) + 1;

require Geo::METAR::Deduced;
my $m = Geo::METAR::Deduced->new();
foreach my $metar (@metars) {
    $m->metar( @{$metar}[0] );
    Test::More::is( $m->ceiling()->ft(), @{$metar}[1] + 0, @{$metar}[2] );
}
