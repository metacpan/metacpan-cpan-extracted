#!perl -T

use Test::More;

plan skip_all => "Documentation tests are disabled" if $ENV{TEST_POD_SKIP};

eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
