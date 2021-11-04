#!/usr/bin/env perl

use t::setup;

use Test::More;
use Test::Pod 1.22;

use Env qw($RELEASE_TESTING);
unless ($RELEASE_TESTING) {
    plan skip_all => "Author tests not required for installation";
}

my @podfiles = all_pod_files bin => @LIBDIRS;

die "can't find any pod files" unless @podfiles;

all_pod_files_ok(@podfiles);
