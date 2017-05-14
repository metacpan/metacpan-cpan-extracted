#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Find;

unless ( $ENV{AUTHOR_TESTING} ) {
	plan skip_all => 'author tests';
}

eval "use Test::Pod 1.14";    ## no critic (ProhibitStringyEval)
plan skip_all => 'Test::Pod 1.14 required' if $@;

all_pod_files_ok(qw/lib t/);

done_testing();
