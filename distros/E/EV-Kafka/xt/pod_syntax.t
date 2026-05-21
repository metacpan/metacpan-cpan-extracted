use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING' unless $ENV{RELEASE_TESTING};

eval { require Test::Pod; Test::Pod->import(import => ['all_pod_files_ok']); 1 }
    or plan skip_all => 'Test::Pod required';

all_pod_files_ok();
