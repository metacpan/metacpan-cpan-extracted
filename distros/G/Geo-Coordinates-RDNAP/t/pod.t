#!perl 

use Test::More;

plan skip_all => 'Test::Pod test is for author only'
    unless -e 't/AUTHOR_BUILD';

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
