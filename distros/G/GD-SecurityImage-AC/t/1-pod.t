#!/usr/bin/env perl -w
use strict;
BEGIN { do 't/skip.test' or die "Can't include skip.test!" }

eval "use Test::Pod 1.00";
if($@) {
   plan skip_all => "Test::Pod 1.00 required for testing POD";
} else {
   all_pod_files_ok();
}