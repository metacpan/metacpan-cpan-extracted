#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase 0.030

use Test::Mojibake;

all_files_encoding_ok( grep { -d } qw( bin lib t xt ) );
