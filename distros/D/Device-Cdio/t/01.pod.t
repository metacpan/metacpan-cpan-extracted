#!/usr/bin/perl -T
use strict;
use warnings;
BEGIN {
    push @INC, ('../blib/lib', '../blib/arch');
}

use Test::More;
note("Test POD Documentation");
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
done_testing();
