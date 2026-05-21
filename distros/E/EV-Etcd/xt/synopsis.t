#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

eval "use Test::Synopsis 0.06; 1"
    or plan skip_all => 'Test::Synopsis 0.06 required';

all_synopsis_ok();
