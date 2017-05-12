use strict;
use Test::More;

eval 'use Test::Synopsis;';
plan skip_all => 'Test::Synopsis required for this test.' if $@;

all_synopsis_ok();
