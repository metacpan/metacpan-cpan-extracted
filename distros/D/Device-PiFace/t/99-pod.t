#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# https://github.com/kraih/mojo/blob/master/t/pod.t <3
plan skip_all => 'Test::Pod 1.14+ required for this test!'
  unless eval 'use Test::Pod 1.14; 1';

all_pod_files_ok();
