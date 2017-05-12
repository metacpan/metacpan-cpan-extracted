# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl t/HTTP-ClickHouse-pod.t'

#########################

use strict;
use Test::More;
eval "use Test::Pod 1.51";
plan skip_all => "Test::Pod 1.51 required for testing POD" if $@;
all_pod_files_ok();

