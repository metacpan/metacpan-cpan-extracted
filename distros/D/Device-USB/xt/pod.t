#!perl -T

use Test::More;
use strict;
use warnings;

eval "use Test::Pod 1.14"; ## no critic (ProhibitStringyEval)
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
