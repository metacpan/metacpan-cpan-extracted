use strict;
use warnings;
use Test::More;


unless (eval "use Test::Pod 1.00; 1") {
    plan skip_all => "Test::Pod not available";
}

Test::Pod::all_pod_files_ok();

1;
