# -*- cperl -*-
use Test::More;

eval "use Test::Pod";
plan skip_all => "Test::Pod required for testing POD" if $@;

plan tests => 1;
pod_file_ok( "lib/File/MergeSort.pm");
