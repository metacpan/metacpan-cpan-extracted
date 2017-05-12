#!perl

use strict;

use Test::More;
use Test::Compile;

my @pms = all_pm_files;

plan tests => @pms + 1;

pm_file_ok($_) for @pms;
pl_file_ok('dh-make-perl');
