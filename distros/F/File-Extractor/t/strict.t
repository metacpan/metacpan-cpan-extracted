#!perl

use strict;
use warnings;
use Test::More;

eval "use Test::Strict";

plan skip_all => 'Test::Strict not installed; skipping' if $@;

{
    no warnings 'once';
    $Test::Strict::TEST_WARNINGS = 1;
}

all_perl_files_ok('lib');
