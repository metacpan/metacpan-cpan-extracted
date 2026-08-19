#!/usr/bin/env perl
# Author test: the POD must parse.
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to enable' unless $ENV{RELEASE_TESTING};

eval { require Test::Pod; Test::Pod->VERSION('1.22'); 1 }
    or plan skip_all => 'Test::Pod 1.22 is required for this test';

Test::Pod::all_pod_files_ok(Test::Pod::all_pod_files('lib'));
