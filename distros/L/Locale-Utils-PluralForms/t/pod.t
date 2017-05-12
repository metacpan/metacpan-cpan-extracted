#!perl -T

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars $EVAL_ERROR);

eval 'use Test::Pod 1.14';
plan skip_all => "Test::Pod 1.14 required for testing POD; $EVAL_ERROR" if $EVAL_ERROR;

all_pod_files_ok();
