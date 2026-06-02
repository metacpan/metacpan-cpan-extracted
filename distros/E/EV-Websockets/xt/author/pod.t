use strict;
use warnings;
use Test::More;

# Author test: POD syntax. Run with `prove -l xt/` (not part of `make test`).
eval "use Test::Pod 1.41; 1"
    or plan skip_all => "Test::Pod 1.41 required for POD syntax tests";

all_pod_files_ok();
