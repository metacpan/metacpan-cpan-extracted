#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

eval 'use Test::Pod 1.26'; ## no critic (eval)
plan skip_all => 'Test::Pod 1.26 required for this test' if $@;
all_pod_files_ok();
