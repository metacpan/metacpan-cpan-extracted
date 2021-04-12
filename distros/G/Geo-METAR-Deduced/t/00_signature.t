#!/usr/bin/env perl
# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2021, Roland van Ipenburg
use strict;
use warnings;
use utf8;
use 5.014000;

our $VERSION = 'v1.0.3';

use Test::More 'tests' => 1;
use Test::Signature;
Test::Signature::signature_ok();
