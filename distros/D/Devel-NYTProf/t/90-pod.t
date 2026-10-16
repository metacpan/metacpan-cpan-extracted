#!perl -w

use Test::More;
unless ($ENV{NYTPROF_AUTHOR_TESTING}) {
    plan skip_all => "NYTPROF_AUTHOR_TESTING only";
}
else {
    diag("Relevant envvar is true; proceeding to testing POD");
}

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

my @default_pod_files = all_pod_files();

all_pod_files_ok(@default_pod_files, 'Changes');

1;
