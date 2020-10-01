#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;

Module::Build->new(
	module_name => 'Devel::FIXME',
	license => 'perl',
	requires => {
		'perl'	=> '5.8.0',
	},
	build_requires => {
		'Test::Most' => 0,
		'Test::Warn' => '0.10',
		'Test::NoWarnings' => 0,
		'Text::Soundex' => 0, # used in testing
	},
	create_makefile_pl => 'traditional',
	# sign => 1,
)->create_build_script;
