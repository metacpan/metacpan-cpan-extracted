use Test::More;

use strict;
use warnings;

eval {
    require Test::Pod;
    Test::Pod->import();
    die unless $Test::Pod::VERSION >= 1.00;
};
plan skip_all => 'Test::Pod 1.00 required for testing POD' if $@;
all_pod_files_ok();
