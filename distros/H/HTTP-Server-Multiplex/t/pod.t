#!/usr/bin/perl
use warnings;
use strict;

use Test::More;

BEGIN
{   eval "use Test::Pod 1.00";

    plan skip_all => "Test::Pod 1.00 required for testing POD"
        if $@;

    plan skip_all => "devel home uses OODoc"
        if qx(/bin/pwd) =~ m[^/home/markov/];
}

all_pod_files_ok();
