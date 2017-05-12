use strict;
use Test::More;

eval 'use Test::Pod;';
plan skip_all => 'Test::Pod required for this test.' if $@;

all_pod_files_ok();
