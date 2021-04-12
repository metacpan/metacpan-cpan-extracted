#!/usr/bin/env perl
# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2021, Roland van Ipenburg
use strict;
use warnings;
use utf8;
use 5.014000;

our $VERSION = 'v1.0.3';

use Test::More 'tests' => 2;
use Test::Requires { 'ExtUtils::Manifest' => 0 };
## no critic (RequireExplicitInclusion)
Test::More::is_deeply [ ExtUtils::Manifest::manicheck() ], [], 'missing';
Test::More::is_deeply [ ExtUtils::Manifest::filecheck() ], [], 'extra';
## use critic
