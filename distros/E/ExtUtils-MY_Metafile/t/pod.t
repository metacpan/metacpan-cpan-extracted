#! perl -T

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
eval "require Encode;";
plan skip_all => "Encode required for testing POD written in utf-8" if $@;
all_pod_files_ok();
