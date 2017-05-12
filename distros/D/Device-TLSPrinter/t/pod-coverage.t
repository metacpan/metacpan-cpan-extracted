#!perl -T
use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok({ also_private => [qw( ^init$ ^read$ ^write$ ^connected$ ^[is]c_filter ^ic_enable_immediate_cmds$ )] });
