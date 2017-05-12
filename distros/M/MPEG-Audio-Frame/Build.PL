#!/usr/bin/perl -w

use strict;

use Module::Build;

Module::Build->new(
	module_name => 'MPEG::Audio::Frame',
	license => 'perl',
	requires => {
		'perl'	=> '>= 5.005_04',
	},
	build_requires => {
		'Test::More' => 0,
	},
	create_makefile_pl => 'traditional',
	sign => 1,
)->create_build_script;

