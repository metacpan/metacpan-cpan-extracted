#!/usr/bin/env perl -w
use strict;
BEGIN { do 't/skip.test' or die "Can't include skip.test!" }

unless ($ENV{'TEST_POD'}) {
    $|++;
    print "1..0 # Skipped: To enable POD test set TEST_POD=1\n";
    exit;
}

eval "use Test::Pod 1.00";
if($@) {
   plan skip_all => "Test::Pod 1.00 required for testing POD";
} else {
   all_pod_files_ok();
}
