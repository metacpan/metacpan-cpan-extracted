#!perl -w
use strict;
use Test::More;
use ExtUtils::Manifest qw(maniread);
$ENV{AUTOMATED_TESTING} || $ENV{IMAGER_AUTHOR_TESTING}
  or plan skip_all => "POD only tested under automated or author testing";
eval "use Test::Pod 1.00;";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
