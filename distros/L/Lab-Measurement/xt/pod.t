#!perl -T

use strict;
use warnings;
use Test::More;
use Module::Load;

eval {
    autoload Test::Pod;
    1;
} or do {
    plan skip_all => "Test::Pod required for testing POD";
};

all_pod_files_ok();
