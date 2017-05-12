#!/usr/bin/env perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
	module_name => 'Hash::PriorityQueue',
	dist_author => 'Lars Stoltenow <penma.cpan@penma.de>',
	license     => 'perl',
	recursive_test_files => 1,
);
$build->create_build_script;
