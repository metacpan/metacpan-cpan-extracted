#!perl -T

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
plan skip_all => "These tests are for author only" unless $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING};
all_pod_files_ok();
