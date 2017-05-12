#!perl -T

use Test::More;
plan skip_all => "env AUTOMATED_TESTING=1 and Test::Pod 1.14 required for testing POD" unless $ENV{AUTOMATED_TESTING};
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
