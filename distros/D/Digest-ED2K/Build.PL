#! /usr/bin/env perl

use strict;
use warnings;

use Module::Build 0.3601;

my %module_build_args = (
	module_name   => 'Digest::ED2K',
	create_readme => 1,
	create_license => 1,
	license       => 'artistic_2',
	build_requires => {
		'Test::More'     => 0,
	},
	configure_requires => {
		'version'        => '0.77',
	},
	meta_merge => {
		resources => {
			repository => 'https://github.com/Kulag/Digest-ED2K',
		},
	},
	requires      => {
		'perl'           => '5.08.0',
		'common::sense'  => '0',
		'Digest::base'   => '1.03',
		'Digest::MD4'    => '0',
	},
);

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
