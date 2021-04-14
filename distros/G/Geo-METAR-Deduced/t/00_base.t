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

BEGIN {
## no critic (ProhibitPackageVars)
    @main::methods = qw(ceiling flight_rule);
## no critic (ProhibitMagicNumbers)
    Test::More::plan 'tests' => ( 4 + @main::methods ) + 1;
## use critic
## use critic
    Test::More::ok(1);
    Test::More::use_ok('Geo::METAR::Deduced');
}
Test::More::diag("Testing Geo::METAR::Deduced $Geo::METAR::Deduced::VERSION");
my $deduced = Test::More::new_ok('Geo::METAR::Deduced');

## no critic (RequireExplicitInclusion)
@Geo::METAR::Deduced::Sub::ISA = qw(Geo::METAR::Deduced);
## use critic
my $deduced_sub = Test::More::new_ok('Geo::METAR::Deduced::Sub');

## no critic (ProhibitPackageVars)
foreach my $method (@main::methods) {
## use critic
    Test::More::can_ok( 'Geo::METAR::Deduced', $method );
}
