#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod is present
my $test_pod_version = 1.22;
eval "use Test::Pod $test_pod_version";
plan skip_all => "Test::Pod $test_pod_version required for testing POD" if $@;

my @files = all_pod_files('.');
my $nb_files = @files;
diag("Testing $nb_files POD files.");

all_pod_files_ok(@files);
