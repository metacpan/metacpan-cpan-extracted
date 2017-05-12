#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN
{   eval "use Test::Pod 1.00";
    plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

    plan skip_all => "devel home uses OODoc"
       if $ENV{MARKOV_DEVEL};
}

all_pod_files_ok();
