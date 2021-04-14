#!/usr/bin/env perl
# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2021, Roland van Ipenburg
use strict;
use warnings;
use utf8;
use 5.014000;

our $VERSION = 'v1.0.4';

use Test::More 'tests' => 1;
use Test::Signature;
Test::More::diag(
    $ENV{'TEST_SIGNATURE'}
## no critic (RequireInterpolationOfMetachars)
    ? q{Forced because $ENV{TEST_SIGNATURE} is true}
    : q{Not forced because $ENV{TEST_SIGNATURE} is false},
## use critic
);
Test::Signature::signature_ok( undef, $ENV{'TEST_SIGNATURE'} );
