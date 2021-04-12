#!/usr/bin/env perl
# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2021, Roland van Ipenburg
use strict;
use warnings;
use utf8;
use 5.014000;

use Test::More;
use Test::NoWarnings;

our $VERSION = 'v1.0.3';

require Geo::METAR::Deduced;
my $m = Geo::METAR::Deduced->new();

my $METAR = q{EHRD 261925Z AUTO 30003G20 260V330 9999 TS FEW015CB BKN049 }
  . q{22/19 Q1009 BECMG NSW};
$m->metar($METAR);
my @TESTS = (
## no critic (ProhibitMagicNumbers)
    [ $m->site(),                            q{EHRD},      q{Site} ],
    [ $m->date(),                            26,           q{Date} ],
    [ $m->time(),                            q{19:25 UTC}, q{Time} ],
    [ $m->mode(),                            q{AUTO},      q{Modifier} ],
    [ $m->wind_dir()->deg(),                 300,          q{Wind dir} ],
    [ $m->wind_dir_eng(),                    q{Northwest}, q{Wind dir name} ],
    [ $m->wind_dir_abb(),                    q{NW},        q{Wind dir abbr} ],
    [ $m->wind_speed()->kn(),                3,            q{Wind speed} ],
    [ $m->wind_gust()->kn(),                 20,           q{Wind gust} ],
    [ $m->wind_var(),                        1,            q{Wind varying} ],
    [ $m->wind_low()->deg(),                 260,          q{Wind var low} ],
    [ $m->wind_high()->deg(),                330,          q{Wind var high} ],
    [ $m->visibility()->m(),                 9999,         q{Visibility} ],
    [ $m->thunderstorm(),                    2,            q{Thunderstorm} ],
    [ $m->ceiling()->ft(),                   4900,         q{Ceiling} ],
    [ $m->flight_rule(),                     3,            q{Flight rule} ],
    [ $m->temp()->C(),                       22,           q{Temp} ],
    [ $m->dew()->C(),                        19,           q{Dew} ],
    [ sprintf( q{%.0f}, $m->alt()->inHg() ), 30,           q{Altimeter} ],
    [ $m->pressure()->pa(),                  100_900,      q{Pressure} ],
## use critic
);
Test::More::plan 'tests' => 1 + @TESTS;
for my $test (@TESTS) {
    Test::More::is( ${$test}[0], ${$test}[1], ${$test}[2] );
}
