#!/usr/bin/env perl -T

use strict;
use warnings;

use File::Basename;
use File::Spec;

use Test::More;


# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

my $dirname = dirname(dirname(__FILE__));

all_pod_files_ok(File::Spec->join($dirname, 'lib'));
