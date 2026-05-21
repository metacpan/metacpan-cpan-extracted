#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

eval "use Test::DistManifest 1.012; 1"
    or plan skip_all => 'Test::DistManifest 1.012 required';

manifest_ok();
