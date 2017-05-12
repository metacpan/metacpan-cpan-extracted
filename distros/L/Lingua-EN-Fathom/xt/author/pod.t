#!perl

use Test::More;
use warnings;
use strict;
eval "use Test::Pod";
plan skip_all => "Test::Pod required for testing POD" if $@;
all_pod_files_ok();
