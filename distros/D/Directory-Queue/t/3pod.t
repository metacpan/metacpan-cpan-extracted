#!perl

use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod
eval("use Test::Pod 1.22");
plan skip_all => "Test::Pod 1.22 required for testing POD" if $@;

all_pod_files_ok();
