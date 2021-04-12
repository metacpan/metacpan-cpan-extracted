#!/usr/bin/env perl
# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2021, Roland van Ipenburg
use strict;
use warnings;
use utf8;
use 5.014000;

use Test::More;
use Geo::METAR::Deduced;

our $VERSION = 'v1.0.3';

use Test::Requires { 'Test::TestCoverage' => 0 };
Test::More::plan 'tests' => 1;
TODO: {
    Test::More::todo_skip
      q{Fails on calling add_method on an immutable Moose object}, 1;
## no critic (RequireExplicitInclusion)
    Test::TestCoverage::test_coverage('Geo::METAR::Deduced');
    Test::TestCoverage::test_coverage_except( 'Geo::METAR::Deduced', 'meta' );
    my $deduced = Geo::METAR::Deduced->new();
    Test::TestCoverage::ok_test_coverage('Geo::METAR::Deduced');
## use critic
}
