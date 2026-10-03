use strict;
use warnings;
use Test::More;

eval "use Test::Pod 1.40";
plan skip_all => "Test::Pod 1.40 required for testing POD" if $@;

all_pod_files_ok();
