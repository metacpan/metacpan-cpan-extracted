#!/usr/bin/perl -w
use strict;
use warnings;

use File::Basename 'dirname';
use Module::Build 0.30;

my %module_build_args = (
	dist_abstract => 'Command line processing with extensive usage generation, object oriented',
	dist_author => [q(Oliver Schieche <schiecheo@cpan.org>)],
	release_status => 'stable',

	build_requires => {
		'Module::Build' => '0.30',
	},
	configure_requires => {
		'Module::Build' => '0.30'
	},
	license => 'perl',
	module_name => 'Getopt::O2',
	requires => {
		'perl' => '5.10.0',
		'Readonly' => 0
	},
	test_requires => {
		'Capture::Tiny' => 0,
		'Test::More' => 0,
		'Test::MockObject::Extends' => 0
	}
);

my %fallback_build_requires = (
	'Module::Build' => '0.30',
	'Test::More' => 0
);

unless (eval {Module::Build->VERSION(0.4004)}) {
	delete $module_build_args{'test_requires'};
	$module_build_args{'build_requires'} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
