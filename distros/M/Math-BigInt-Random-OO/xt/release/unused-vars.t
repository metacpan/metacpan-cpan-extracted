# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

eval 'use Test::Vars';
plan skip_all => 'Test::Vars required for this testing variables' if $@;

all_vars_ok();
