use strict;
use Test::More;
if ($] < 5.007003 ) {
    plan skip_all => "Perl 5.7.3 or later required for testing utf-8 POD";
} else {
    eval "use Test::Pod 1.00";
    if ($@) {
        plan skip_all => "Test::Pod 1.00 or later required for testing POD";
    }
}
all_pod_files_ok();

