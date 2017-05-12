#!perl

use strict;
use warnings;
use Test::More;

eval "use Test::NoTabs";

plan skip_all => 'Test::NoTabs not installed; skipping' if $@;
all_perl_files_ok('lib');
