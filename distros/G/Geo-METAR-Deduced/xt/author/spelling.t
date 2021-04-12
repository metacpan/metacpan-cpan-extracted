#!/usr/bin/env perl
# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2021, Roland van Ipenburg
use strict;
use warnings;
use utf8;
use 5.014000;

our $VERSION = 'v1.0.3';

use Test::More;
use Test::Requires { 'Test::Spelling' => 0 };
## no critic (RequireExplicitInclusion)
Test::Spelling::add_stopwords(<DATA>);
Test::Spelling::all_pod_files_spelling_ok();
## use critic
__DATA__
Ipenburg
Bitbucket
MERCHANTABILITY
doesn't
isn't
v3.0
