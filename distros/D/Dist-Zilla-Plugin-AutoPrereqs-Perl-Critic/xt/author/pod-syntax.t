#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase 0.030

use Test::Pod 1.26;

all_pod_files_ok( grep { -d } qw( bin lib t xt) );
