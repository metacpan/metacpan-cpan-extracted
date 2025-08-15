#!/usr/bin/env perl

use v5.018;
use warnings;
use Test2::V0;
use Test::Script 1.05;

plan(2);

script_compiles('script/maclog', 'maclog compiles');
script_runs(['script/maclog', '--help'], 'maclog --help');
