#!/usr/bin/perl

use 5.006;
use strict;

use Module::Build;

my $b = Module::Build->new(
	'module_name'	=> 'Graphics::ColorNames::WWW',
	'license'	=> 'perl',

	'sign'		=> 1,
	'create_license' => 1,
	'create_makefile_pl' => 'traditional',

    	'requires'	=> {
		'Graphics::ColorNames'	=> 0.32,
	},
	'build_requires' => {
		'Test::More' => 0, 
		'Test::NoWarnings' => 0,
	},
	'resources' => {
		'homepage' => 'http://search.cpan.org/dist/Graphics-ColorNames-WWW',
		'repository' => 'http://github.com/cfaerber/Graphics-ColorNames-WWW',
	},
);

$b->create_build_script;
