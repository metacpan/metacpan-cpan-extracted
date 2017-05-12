use strict;
use Module::Build;

Module::Build->new(
	'module_name'	=> 'Geo::Coordinates::Parser',
	'license'	=> 'perl',
	'dist_author'	=> 'Carl Räihä, <carl.raiha at gmail.com>',
	'requires'      => {
				'Geo::Coordinates::DecimalDegrees' => 0,
			   },
	'build_requires' => {
				'Test::More' => 0,
			    },
	'sign'		=> 1,
	'create_readme'	=> 1
)->create_build_script;
