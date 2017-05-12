#!perl

use strict;

use Test::More;

BEGIN {
    eval 'use Test::Pod';

    if ($@) {
        plan skip_all => 'Needs Test::Pod';
    }
}

all_pod_files_ok();

