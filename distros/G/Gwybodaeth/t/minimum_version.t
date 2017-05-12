#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
eval "use Test::MinimumVersion";
plan skip_all => "Test::MinimumVersion required for testing minimum required version of Perl" if $@;
all_minimum_version_ok('5.6.0');
