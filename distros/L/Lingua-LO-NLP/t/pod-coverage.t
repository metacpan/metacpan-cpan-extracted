#!/usr/bin/perl -T
use 5.010_001;
use strict;
use warnings FATAL => 'all';
use utf8;
use Test::More;

## no critic(Lax::ProhibitStringyEval::ExceptForRequire, BuiltinFunctions::ProhibitStringyEval)
eval "use Test::Pod::Coverage 1.00; 1" // plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage";
all_pod_coverage_ok();
