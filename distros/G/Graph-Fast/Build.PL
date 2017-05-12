#!/usr/bin/env perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
	module_name => 'Graph::Fast',
	dist_author => 'Lars Stoltenow <penma.cpan@penma.de>',
	license     => 'perl',
	recursive_test_files => 1,
	requires    => {
		'Hash::PriorityQueue' => 0,
		perl => '5.10.0',
	},
	recommends  => {
		'List::PriorityQueue' => 0,
	},
);
$build->create_build_script;
