#!perl -T

use strict;
use warnings;

use English qw(-no_match_vars $EVAL_ERROR);
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage; $EVAL_ERROR" if $EVAL_ERROR;

all_pod_coverage_ok();