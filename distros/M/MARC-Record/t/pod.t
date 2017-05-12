#!perl -T

use strict;
use warnings;

use Test::More;
eval {
    require Test::Pod;
    Test::Pod->import();
    die unless $Test::Pod::VERSION >= 1.14;
};
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
