#!/usr/bin/env perl
# Author test: every POD document parses without syntax errors.
use strict;
use warnings;
use Test::More;

eval "use Test::Pod 1.22";
plan skip_all => 'Test::Pod 1.22 required for POD checks' if $@;

all_pod_files_ok( all_pod_files('lib') );
