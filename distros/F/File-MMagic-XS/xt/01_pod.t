use strict;
use Test::More;

eval {
    require Test::Pod;
};
if ($@) {
    plan skip_all => "Test::Pod is not installed";
}

Test::Pod::all_pod_files_ok();
