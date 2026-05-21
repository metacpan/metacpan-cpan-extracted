#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

eval "use Test::Pod 1.41; 1" or plan skip_all => 'Test::Pod 1.41 required';
all_pod_files_ok();
