#!/usr/bin/env perl
# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2021, Roland van Ipenburg
use strict;
use warnings;
use utf8;
use 5.014000;

use Test::More;

our $VERSION = 'v1.0.3';

use Test::Kwalitee qw(kwalitee_ok);
Test::Kwalitee::kwalitee_ok(qw( -has_meta_yml ));
Test::More::done_testing;
