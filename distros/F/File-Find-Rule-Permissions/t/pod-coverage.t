use strict;
$^W=1;

eval "use Test::Pod::Coverage 1.00";
if($@) {
    print "1..0 # SKIP Test::Pod::Coverage 1.00 required for testing POD coverage\n";
} else {
    all_pod_coverage_ok();
}
