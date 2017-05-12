#!perl -w

use Test::More;

BEGIN {
  plan skip_all => "not run unless RELEASE_TESTING"
    unless $ENV{RELEASE_TESTING};
}

use Test::Pod 1.00;
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

all_pod_files_ok();
